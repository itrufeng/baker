//
//  ShelfViewController.m
//  Baker
//
//  ==========================================================================================
//
//  Copyright (c) 2010-2012, Davide Casali, Marco Colombo, Alessandro Morandi
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification, are
//  permitted provided that the following conditions are met:
//
//  Redistributions of source code must retain the above copyright notice, this list of
//  conditions and the following disclaimer.
//  Redistributions in binary form must reproduce the above copyright notice, this list of
//  conditions and the following disclaimer in the documentation and/or other materials
//  provided with the distribution.
//  Neither the name of the Baker Framework nor the names of its contributors may be used to
//  endorse or promote products derived from this software without specific prior written
//  permission.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
//  EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
//  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
//  SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
//  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
//  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
//  LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
//  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import "ShelfViewController.h"
#import "UICustomNavigationBar.h"
#import "Constants.h"

#import "BakerViewController.h"
#import "IssueViewController.h"

#import "NSData+Base64.h"
#import "NSString+Extensions.h"
#import "Utils.h"

#import "UICustomTableViewCell.h"

#define SHADOW_Y 107
#define SHADOW_HEIGHT 69

@implementation ShelfViewController

@synthesize issues;
@synthesize issueViewControllers;
@synthesize issueTableView;
@synthesize subscribeButton;
@synthesize refreshButton;
@synthesize shelfStatus;
@synthesize subscriptionsActionSheet;
@synthesize supportedOrientation;
@synthesize blockingProgressView;
@synthesize bookToBeProcessed;
@synthesize shadow;
@synthesize cellBackground;
@synthesize refreshButton1;
@synthesize subscribeButton1;

#pragma mark - Init

- (id)init {
    self = [super init];
    if (self) {
        #ifdef BAKER_NEWSSTAND
        purchasesManager = [PurchasesManager sharedInstance];
        [self addPurchaseObserver:@selector(handleProductsRetrieved:)
                             name:@"notification_products_retrieved"];
        [self addPurchaseObserver:@selector(handleProductsRequestFailed:)
                             name:@"notification_products_request_failed"];
        [self addPurchaseObserver:@selector(handleSubscriptionPurchased:)
                             name:@"notification_subscription_purchased"];
        [self addPurchaseObserver:@selector(handleSubscriptionFailed:)
                             name:@"notification_subscription_failed"];
        [self addPurchaseObserver:@selector(handleSubscriptionRestored:)
                             name:@"notification_subscription_restored"];
        [self addPurchaseObserver:@selector(handleRestoreFailed:)
                             name:@"notification_restore_failed"];
        [self addPurchaseObserver:@selector(handleMultipleRestores:)
                             name:@"notification_multiple_restores"];
        [self addPurchaseObserver:@selector(handleRestoredIssueNotRecognised:)
                             name:@"notification_restored_issue_not_recognised"];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receiveBookProtocolNotification:)
                                                     name:@"notification_book_protocol"
                                                   object:nil];

        [[SKPaymentQueue defaultQueue] addTransactionObserver:purchasesManager];
        #endif

        api = [BakerAPI sharedInstance];
        issuesManager = [[IssuesManager sharedInstance] retain];
        notRecognisedTransactions = [[NSMutableArray alloc] init];

        self.shelfStatus = [[[ShelfStatus alloc] init] retain];
        self.issueViewControllers = [[NSMutableArray alloc] init];
        self.supportedOrientation = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"UISupportedInterfaceOrientations"];
        self.bookToBeProcessed = nil;

        #ifdef BAKER_NEWSSTAND
        [self handleRefresh:nil];
        #endif
    }
    return self;
}

- (id)initWithBooks:(NSArray *)currentBooks
{
    self = [self init];
    if (self) {
        self.issues = currentBooks;

        NSMutableArray *controllers = [NSMutableArray array];
        for (BakerIssue *issue in self.issues) {
            IssueViewController *controller = [self createIssueViewControllerWithIssue:issue];
            [controllers addObject:controller];
        }
        self.issueViewControllers = [NSMutableArray arrayWithArray:controllers];
    }
    return self;
}

#pragma mark - Memory management

- (void)dealloc
{
    [issueViewControllers release];
    [issues release];
    [subscribeButton release];
    [refreshButton release];
    [shelfStatus release];
    [subscriptionsActionSheet release];
    [supportedOrientation release];
    [blockingProgressView release];
    [issuesManager release];
    [notRecognisedTransactions release];
    [bookToBeProcessed release];
    [refreshButton1 release];
    [subscribeButton1 release];

    #ifdef BAKER_NEWSSTAND
    [purchasesManager release];
    #endif

    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.background = [[UIImageView alloc] init];
    self.cellBackground = [[UIImageView alloc] init];

    self.shadow = [[UIImageView alloc] init];
//    self.shadow.backgroundColor = [UIColor redColor];
    
    self.issueTableView = [[UITableView alloc] init];
    self.issueTableView.dataSource = self;
    self.issueTableView.delegate = self;
    self.issueTableView.backgroundColor = [UIColor clearColor];

    [self.view addSubview:self.background];
    [self.view addSubview:self.issueTableView];
    [self.view addSubview:self.shadow];

    [self willRotateToInterfaceOrientation:self.interfaceOrientation duration:0];
    [self.issueTableView reloadData];

    #ifdef BAKER_NEWSSTAND
    self.refreshButton = [[[UIBarButtonItem alloc]
                                       initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                       target:self
                                       action:@selector(handleRefresh:)]
                                      autorelease];

    self.subscribeButton = [[[UIBarButtonItem alloc]
                             initWithTitle: NSLocalizedString(@"SUBSCRIBE_BUTTON_TEXT", nil)
                             style:UIBarButtonItemStylePlain
                             target:self
                             action:@selector(handleSubscribeButtonPressed:)]
                            autorelease];

    self.blockingProgressView = [[UIAlertView alloc]
                                 initWithTitle:@"Processing..."
                                 message:@"\n"
                                 delegate:nil
                                 cancelButtonTitle:nil
                                 otherButtonTitles:nil];
    
    self.refreshButton1 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.refreshButton1.tag = BUTTON_REFRESH;
    self.refreshButton1.frame = CGRectMake(14, 55, 50, 38);
    [self.refreshButton1 setImage:[UIImage imageNamed:@"button_refresh.png"]
                         forState:UIControlStateNormal];
    [self.refreshButton1 addTarget:self
                            action:@selector(handleRefresh:)
                  forControlEvents:UIControlEventTouchUpInside];
    
    self.subscribeButton1 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.subscribeButton1.tag = BUTTON_SUBSCRIBE;
    self.subscribeButton1.frame = CGRectMake(75, 55, 110, 38);
    [self.subscribeButton1 setImage:[UIImage imageNamed:@"button_subscribe.png"]
                         forState:UIControlStateNormal];
    [self.subscribeButton1 addTarget:self
                            action:@selector(handleSubscribeButtonPressed:)
                  forControlEvents:UIControlEventTouchUpInside];
    
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    spinner.center = CGPointMake(139.5, 75.5); // .5 so it doesn't blur
    [self.blockingProgressView addSubview:spinner];
    [spinner startAnimating];
    [spinner release];

    NSMutableSet *subscriptions = [NSMutableSet setWithArray:AUTO_RENEWABLE_SUBSCRIPTION_PRODUCT_IDS];
    if ([FREE_SUBSCRIPTION_PRODUCT_ID length] > 0 && ![purchasesManager isPurchased:FREE_SUBSCRIPTION_PRODUCT_ID]) {
        [subscriptions addObject:FREE_SUBSCRIPTION_PRODUCT_ID];
    }
    [purchasesManager retrievePricesFor:subscriptions andEnableFailureNotifications:NO];
    #endif
}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setTranslucent:NO];
    [self willRotateToInterfaceOrientation:self.interfaceOrientation duration:0];

    for (IssueViewController *controller in self.issueViewControllers) {
        controller.issue.transientStatus = BakerIssueTransientStatusNone;
        [controller refresh];
    }

//    #ifdef BAKER_NEWSSTAND
//    NSMutableArray *buttonItems = [NSMutableArray arrayWithObject:self.refreshButton];
//    if ([purchasesManager hasSubscriptions] || [issuesManager hasProductIDs]) {
//        [buttonItems addObject:self.subscribeButton];
//    }
//    self.navigationItem.leftBarButtonItems = buttonItems;
//    #endif

    #ifdef BAKER_NEWSSTAND
    [self.navigationController.view addSubview:self.refreshButton1];
    
    if ([purchasesManager hasSubscriptions] || [issuesManager hasProductIDs]) {
        [self.navigationController.view addSubview:self.subscribeButton1];
    }
    #endif
//    // 隐藏后退显示订阅和刷新
//    self.refreshButton1.hidden = NO;
//    if ([purchasesManager hasSubscriptions] || [issuesManager hasProductIDs]) {
//        self.subscribeButton1.hidden = NO;
//    }
}
- (void)viewDidAppear:(BOOL)animated
{
    if (self.bookToBeProcessed) {
        [self handleBookToBeProcessed];
    }
}
- (NSInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [supportedOrientation indexOfObject:[NSString stringFromInterfaceOrientation:interfaceOrientation]] != NSNotFound;
}
- (BOOL)shouldAutorotate
{
    return YES;
}
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    int width  = 0;
    int height = 0;

    NSString *image = @"";
    NSString *shadowImage = @"shelf-shadow-bar.png";
    NSString *cellBackgroundImage = @"cell-bg.png";
    
    CGSize size = [UIScreen mainScreen].bounds.size;

    if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)) {
        width  = size.width;
        height = size.height - 64;
        image  = @"shelf-bg-portrait";
    } else if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
        width  = size.height;
        height = size.width - 64;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            height = height + 12;
        }
        image  = @"shelf-bg-landscape";
    }

    if (size.height == 568) {
        image = [NSString stringWithFormat:@"%@-568h.png", image];
    } else {
        image = [NSString stringWithFormat:@"%@.png", image];
    }

    int bannerHeight = [ShelfViewController getBannerHeight];

    self.background.frame = CGRectMake(0, 0, width, height);
    self.background.image = [UIImage imageNamed:image];
    
    self.shadow.frame = CGRectMake(0, SHADOW_Y - 50, width, SHADOW_HEIGHT);
    self.shadow.image = [UIImage imageNamed:shadowImage];
    
    self.cellBackground.frame = CGRectMake(0, 0, 768, 291);
    self.cellBackground.image = [UIImage imageNamed:cellBackgroundImage];

    self.issueTableView.frame = CGRectMake(0, bannerHeight - 50, width, height - bannerHeight + 50);
    self.issueTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}
- (IssueViewController *)createIssueViewControllerWithIssue:(BakerIssue *)issue
{
    IssueViewController *controller = [[[IssueViewController alloc] initWithBakerIssue:issue] autorelease];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleReadIssue:) name:@"read_issue_request" object:controller];
    return controller;
}

#pragma mark - 提供tableview数据

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self cellNumber] < 3 ? 3 : [self cellNumber];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"Cell";
    
    UICustomTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (!cell)
    {
        cell = [[UICustomTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:identifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    if (indexPath.row + 1 > [self cellNumber] &&
        [self cellNumber] < 3)
    {
        return cell;
    }
    
    NSInteger lastCount = [self.issueViewControllers count] % 3 ? [self.issueViewControllers count] % 3 : 3;
    
    lastCount = [self.issueViewControllers count] / 3 == indexPath.row ? lastCount : 3;
    
    NSRange subRange = NSMakeRange(indexPath.row * 3, lastCount);
    
    NSArray *subIssViewControllers = [self.issueViewControllers subarrayWithRange:subRange];
    
    cell.issueViewControllers = subIssViewControllers;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 291;
}

- (CGSize)portraitGridCellSizeForGridView:(AQGridView *)aGridView
{
    return [IssueViewController getIssueCellSize];
}

- (int) cellNumber
{
    return [issueViewControllers count] % 3 == 0 ? [issueViewControllers count] / 3 : [issueViewControllers count] / 3 + 1;
}

#ifdef BAKER_NEWSSTAND
- (void)handleRefresh:(NSNotification *)notification {
    [self setrefreshButtonEnabled:NO];

    if([issuesManager refresh]) {
        self.issues = issuesManager.issues;

        [purchasesManager retrievePurchasesFor:[issuesManager productIDs]];

        [shelfStatus load];
        for (BakerIssue *issue in self.issues) {
            issue.price = [shelfStatus priceFor:issue.productID];
        }

        [self.issues enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL *stop) {
            // NOTE: this block changes the issueViewController array while looping

            IssueViewController *existingIvc = nil;
            if (idx < [self.issueViewControllers count]) {
                existingIvc = [self.issueViewControllers objectAtIndex:idx];
            }

            BakerIssue *issue = (BakerIssue*)object;
            if (!existingIvc || ![[existingIvc issue].ID isEqualToString:issue.ID]) {
                IssueViewController *ivc = [self createIssueViewControllerWithIssue:issue];
                [self.issueViewControllers insertObject:ivc atIndex:idx];
//                [self.gridView insertItemsAtIndices:[NSIndexSet indexSetWithIndex:idx] withAnimation:AQGridViewItemAnimationNone];
//#warning 有新的书籍需要插入到这里
                [self.issueTableView reloadData];
            } else {
                existingIvc.issue = issue;
                [existingIvc refreshContentWithCache:NO];
            }
        }];

        [purchasesManager retrievePricesFor:issuesManager.productIDs andEnableFailureNotifications:NO];
    }
    else{
        [Utils showAlertWithTitle:NSLocalizedString(@"INTERNET_CONNECTION_UNAVAILABLE_TITLE", nil)
                          message:NSLocalizedString(@"INTERNET_CONNECTION_UNAVAILABLE_MESSAGE", nil)
                      buttonTitle:NSLocalizedString(@"INTERNET_CONNECTION_UNAVAILABLE_CLOSE", nil)];
    }
    [self setrefreshButtonEnabled:YES];
}

#pragma mark - Store Kit

- (void)handleSubscribeButtonPressed:(NSNotification *)notification {
    if (subscriptionsActionSheet.visible) {
        [subscriptionsActionSheet dismissWithClickedButtonIndex:(subscriptionsActionSheet.numberOfButtons - 1) animated:YES];
    } else {
        [self.subscriptionsActionSheet release];
        self.subscriptionsActionSheet = [self buildSubscriptionsActionSheet];
//        [subscriptionsActionSheet showFromBarButtonItem:self.subscribeButton animated:YES];
        [subscriptionsActionSheet showFromRect:self.subscribeButton1.frame inView:self.view animated:YES];
    }
}

- (UIActionSheet *)buildSubscriptionsActionSheet {
    NSString *title;
    if ([api canGetPurchasesJSON]) {
        if (purchasesManager.subscribed) {
            title = NSLocalizedString(@"SUBSCRIPTIONS_SHEET_SUBSCRIBED", nil);
        } else {
            title = NSLocalizedString(@"SUBSCRIPTIONS_SHEET_NOT_SUBSCRIBED", nil);
        }
    } else {
        title = NSLocalizedString(@"SUBSCRIPTIONS_SHEET_GENERIC", nil);
    }

    UIActionSheet *sheet = [[UIActionSheet alloc]initWithTitle:title
                                                      delegate:self
                                             cancelButtonTitle:nil
                                        destructiveButtonTitle:nil
                                             otherButtonTitles: nil];
    NSMutableArray *actions = [NSMutableArray array];

    if (!purchasesManager.subscribed) {
        if ([FREE_SUBSCRIPTION_PRODUCT_ID length] > 0 && ![purchasesManager isPurchased:FREE_SUBSCRIPTION_PRODUCT_ID]) {
            [sheet addButtonWithTitle:NSLocalizedString(@"SUBSCRIPTIONS_SHEET_FREE", nil)];
            [actions addObject:FREE_SUBSCRIPTION_PRODUCT_ID];
        }

        for (NSString *productId in AUTO_RENEWABLE_SUBSCRIPTION_PRODUCT_IDS) {
            NSString *title = NSLocalizedString(productId, nil);
            NSString *price = [purchasesManager priceFor:productId];
            if (price) {
                [sheet addButtonWithTitle:[NSString stringWithFormat:@"%@ %@", title, price]];
                [actions addObject:productId];
            }
        }
    }

    if ([issuesManager hasProductIDs]) {
        [sheet addButtonWithTitle:NSLocalizedString(@"SUBSCRIPTIONS_SHEET_RESTORE", nil)];
        [actions addObject:@"restore"];
    }

    [sheet addButtonWithTitle:NSLocalizedString(@"SUBSCRIPTIONS_SHEET_CLOSE", nil)];
    [actions addObject:@"cancel"];

    self.subscriptionsActionSheetActions = actions;

    sheet.cancelButtonIndex = sheet.numberOfButtons - 1;
    return sheet;
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (actionSheet == subscriptionsActionSheet) {
        NSString *action = [self.subscriptionsActionSheetActions objectAtIndex:buttonIndex];
        if ([action isEqualToString:@"cancel"]) {
            NSLog(@"Action sheet: cancel");
            [self setSubscribeButtonEnabled:YES];
        } else if ([action isEqualToString:@"restore"]) {
            [self.blockingProgressView show];
            [purchasesManager restore];
            NSLog(@"Action sheet: restore");
        } else {
            NSLog(@"Action sheet: %@", action);
            [self setSubscribeButtonEnabled:NO];
            if (![purchasesManager purchase:action]){
                [Utils showAlertWithTitle:NSLocalizedString(@"SUBSCRIPTION_FAILED_TITLE", nil)
                                  message:nil
                              buttonTitle:NSLocalizedString(@"SUBSCRIPTION_FAILED_CLOSE", nil)];
                [self setSubscribeButtonEnabled:YES];
            }
        }
    }
}

- (void)handleRestoreFailed:(NSNotification *)notification {
    NSError *error = [notification.userInfo objectForKey:@"error"];
    [Utils showAlertWithTitle:NSLocalizedString(@"RESTORE_FAILED_TITLE", nil)
                      message:[error localizedDescription]
                  buttonTitle:NSLocalizedString(@"RESTORE_FAILED_CLOSE", nil)];

    [self.blockingProgressView dismissWithClickedButtonIndex:0 animated:YES];

}

- (void)handleMultipleRestores:(NSNotification *)notification {
    #ifdef BAKER_NEWSSTAND
    if ([notRecognisedTransactions count] > 0) {
        NSSet *productIDs = [NSSet setWithArray:[[notRecognisedTransactions valueForKey:@"payment"] valueForKey:@"productIdentifier"]];
        NSString *productsList = [[productIDs allObjects] componentsJoinedByString:@", "];

        [Utils showAlertWithTitle:NSLocalizedString(@"RESTORED_ISSUE_NOT_RECOGNISED_TITLE", nil)
                          message:[NSString stringWithFormat:NSLocalizedString(@"RESTORED_ISSUE_NOT_RECOGNISED_MESSAGE", nil), productsList]
                      buttonTitle:NSLocalizedString(@"RESTORED_ISSUE_NOT_RECOGNISED_CLOSE", nil)];

        for (SKPaymentTransaction *transaction in notRecognisedTransactions) {
            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
        }
        [notRecognisedTransactions removeAllObjects];
    }
    #endif

    [self handleRefresh:nil];
    [self.blockingProgressView dismissWithClickedButtonIndex:0 animated:YES];
}

- (void)handleRestoredIssueNotRecognised:(NSNotification *)notification {
    SKPaymentTransaction *transaction = [notification.userInfo objectForKey:@"transaction"];
    [notRecognisedTransactions addObject:transaction];
}

// TODO: this can probably be removed
- (void)handleSubscription:(NSNotification *)notification {
    [self setSubscribeButtonEnabled:NO];
    [purchasesManager purchase:FREE_SUBSCRIPTION_PRODUCT_ID];
}

- (void)handleSubscriptionPurchased:(NSNotification *)notification {
    SKPaymentTransaction *transaction = [notification.userInfo objectForKey:@"transaction"];

    [purchasesManager markAsPurchased:transaction.payment.productIdentifier];
    [self setSubscribeButtonEnabled:YES];

    if ([purchasesManager finishTransaction:transaction]) {
        if (!purchasesManager.subscribed) {
            [Utils showAlertWithTitle:NSLocalizedString(@"SUBSCRIPTION_SUCCESSFUL_TITLE", nil)
                              message:NSLocalizedString(@"SUBSCRIPTION_SUCCESSFUL_MESSAGE", nil)
                          buttonTitle:NSLocalizedString(@"SUBSCRIPTION_SUCCESSFUL_CLOSE", nil)];

            [self handleRefresh:nil];
        }
    } else {
        [Utils showAlertWithTitle:NSLocalizedString(@"TRANSACTION_RECORDING_FAILED_TITLE", nil)
                          message:NSLocalizedString(@"TRANSACTION_RECORDING_FAILED_MESSAGE", nil)
                      buttonTitle:NSLocalizedString(@"TRANSACTION_RECORDING_FAILED_CLOSE", nil)];
    }
}

- (void)handleSubscriptionFailed:(NSNotification *)notification {
    SKPaymentTransaction *transaction = [notification.userInfo objectForKey:@"transaction"];

    // Show an error, unless it was the user who cancelled the transaction
    if (transaction.error.code != SKErrorPaymentCancelled) {
        [Utils showAlertWithTitle:NSLocalizedString(@"SUBSCRIPTION_FAILED_TITLE", nil)
                          message:[transaction.error localizedDescription]
                      buttonTitle:NSLocalizedString(@"SUBSCRIPTION_FAILED_CLOSE", nil)];
    }

    [self setSubscribeButtonEnabled:YES];
}

- (void)handleSubscriptionRestored:(NSNotification *)notification {
    SKPaymentTransaction *transaction = [notification.userInfo objectForKey:@"transaction"];

    [purchasesManager markAsPurchased:transaction.payment.productIdentifier];

    if (![purchasesManager finishTransaction:transaction]) {
        NSLog(@"Could not confirm purchase restore with remote server for %@", transaction.payment.productIdentifier);
    }
}

- (void)handleProductsRetrieved:(NSNotification *)notification {
    NSSet *ids = [notification.userInfo objectForKey:@"ids"];
    BOOL issuesRetrieved = NO;

    for (NSString *productId in ids) {
        if ([productId isEqualToString:FREE_SUBSCRIPTION_PRODUCT_ID]) {
            // ID is for a free subscription
            [self setSubscribeButtonEnabled:YES];
        } else if ([AUTO_RENEWABLE_SUBSCRIPTION_PRODUCT_IDS containsObject:productId]) {
            // ID is for an auto-renewable subscription
            [self setSubscribeButtonEnabled:YES];
        } else {
            // ID is for an issue
            issuesRetrieved = YES;
        }
    }

    if (issuesRetrieved) {
        NSString *price;
        for (IssueViewController *controller in self.issueViewControllers) {
            price = [purchasesManager priceFor:controller.issue.productID];
            if (price) {
                [controller setPrice:price];
                [shelfStatus setPrice:price for:controller.issue.productID];
            }
        }
        [shelfStatus save];
    }
}

- (void)handleProductsRequestFailed:(NSNotification *)notification {
    NSError *error = [notification.userInfo objectForKey:@"error"];

    [Utils showAlertWithTitle:NSLocalizedString(@"PRODUCTS_REQUEST_FAILED_TITLE", nil)
                      message:[error localizedDescription]
                  buttonTitle:NSLocalizedString(@"PRODUCTS_REQUEST_FAILED_CLOSE", nil)];
}

#endif

#pragma mark - Navigation management

- (void)gridView:(AQGridView *)myGridView didSelectItemAtIndex:(NSUInteger)index
{
    [myGridView deselectItemAtIndex:index animated:NO];
}
- (void)readIssue:(BakerIssue *)issue
{
    BakerBook *book = nil;
    NSString *status = [issue getStatus];

    #ifdef BAKER_NEWSSTAND
    if ([status isEqual:@"opening"]) {
        book = [[[BakerBook alloc] initWithBookPath:issue.path bundled:NO] autorelease];
        if (book) {
            [self pushViewControllerWithBook:book];
        } else {
            NSLog(@"[ERROR] Book %@ could not be initialized", issue.ID);
            issue.transientStatus = BakerIssueTransientStatusNone;
            // Let's refresh everything as it's easier. This is an edge case anyway ;)
            for (IssueViewController *controller in issueViewControllers) {
                [controller refresh];
            }
            [Utils showAlertWithTitle:NSLocalizedString(@"ISSUE_OPENING_FAILED_TITLE", nil)
                              message:NSLocalizedString(@"ISSUE_OPENING_FAILED_MESSAGE", nil)
                          buttonTitle:NSLocalizedString(@"ISSUE_OPENING_FAILED_CLOSE", nil)];
        }
    }
    #else
    if ([status isEqual:@"bundled"]) {
        book = [issue bakerBook];
        [self pushViewControllerWithBook:book];
    }
    #endif
}
- (void)handleReadIssue:(NSNotification *)notification
{
    IssueViewController *controller = notification.object;
    [self readIssue:controller.issue];
}
- (void)receiveBookProtocolNotification:(NSNotification *)notification
{
    self.bookToBeProcessed = [notification.userInfo objectForKey:@"ID"];
    [self.navigationController popToRootViewControllerAnimated:YES];
}
- (void)handleBookToBeProcessed
{
    for (IssueViewController *issueViewController in self.issueViewControllers) {
        if ([issueViewController.issue.ID isEqualToString:self.bookToBeProcessed]) {
            [issueViewController actionButtonPressed:nil];
            break;
        }
    }

    self.bookToBeProcessed = nil;
}
- (void)pushViewControllerWithBook:(BakerBook *)book
{
    BakerViewController *bakerViewController = [[BakerViewController alloc] initWithBook:book];
    [self.navigationController pushViewController:bakerViewController animated:YES];
    [bakerViewController release];
}

#pragma mark - Buttons management

-(void)setrefreshButtonEnabled:(BOOL)enabled {
    self.refreshButton.enabled = enabled;
}

-(void)setSubscribeButtonEnabled:(BOOL)enabled {
    self.subscribeButton.enabled = enabled;
    if (enabled) {
        self.subscribeButton.title = NSLocalizedString(@"SUBSCRIBE_BUTTON_TEXT", nil);
    } else {
        self.subscribeButton.title = NSLocalizedString(@"SUBSCRIBE_BUTTON_DISABLED_TEXT", nil);
    }
}

#pragma mark - Helper methods

- (void)addPurchaseObserver:(SEL)notificationSelector name:(NSString *)notificationName {
    #ifdef BAKER_NEWSSTAND
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:notificationSelector
                                                 name:notificationName
                                               object:purchasesManager];
    #endif
}

+ (int)getBannerHeight
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return SHADOW_Y;
    } else {
        return 104;
    }
}

@end
