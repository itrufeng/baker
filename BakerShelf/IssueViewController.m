//
//  IssueViewController.m
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

#import <QuartzCore/QuartzCore.h>

#import "IssueViewController.h"
#import "SSZipArchive.h"
#import "UIConstants.h"
#ifdef BAKER_NEWSSTAND
#import "PurchasesManager.h"
#endif

#import "UIColor+Extensions.h"
#import "Utils.h"

#import "StatusView.h"

@interface IssueViewController () <StatusViewDelegate>

@property (strong, nonatomic) StatusView *statusview;
@property (strong, nonatomic) UILongPressGestureRecognizer *longPress;
@property (strong, nonatomic) UITapGestureRecognizer *tap;
@property (strong, nonatomic) UIImageView *statusbar;

@end

@implementation IssueViewController

#pragma mark - Synthesis

@synthesize issue;
@synthesize actionButton;
@synthesize archiveButton;
@synthesize priceLabel;

@synthesize issueCover;
@synthesize titleFont;
@synthesize infoFont;
@synthesize titleLabel;
@synthesize infoLabel;

@synthesize currentStatus;
@synthesize statusview;
@synthesize longPress;
@synthesize tap;
@synthesize statusbar;

#pragma mark - Init

- (id)initWithBakerIssue:(BakerIssue *)bakerIssue
{
    self = [super init];
    if (self) {
        self.issue = bakerIssue;
        self.currentStatus = nil;

        purchaseDelayed = NO;

        #ifdef BAKER_NEWSSTAND
        purchasesManager = [PurchasesManager sharedInstance];
        [self addPurchaseObserver:@selector(handleIssueRestored:) name:@"notification_issue_restored"];

        [self addIssueObserver:@selector(handleDownloadStarted:) name:self.issue.notificationDownloadStartedName];
        [self addIssueObserver:@selector(handleDownloadProgressing:) name:self.issue.notificationDownloadProgressingName];
        [self addIssueObserver:@selector(handleDownloadFinished:) name:self.issue.notificationDownloadFinishedName];
        [self addIssueObserver:@selector(handleDownloadError:) name:self.issue.notificationDownloadErrorName];
        #endif
    }
    return self;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    CGSize cellSize = [IssueViewController getIssueCellSize];

    self.view.frame = CGRectMake(0, 0, cellSize.width, cellSize.height);
    self.view.backgroundColor = [UIColor clearColor];
    self.view.tag = 42;

    UI ui = [IssueViewController getIssueContentMeasures];

    self.issueCover = [UIButton buttonWithType:UIButtonTypeCustom];
    issueCover.frame = CGRectMake(ui.cellPadding, ui.cellPadding, ui.thumbWidth, ui.thumbHeight);
    
    issueCover.backgroundColor = [UIColor colorWithHexString:ISSUES_COVER_BACKGROUND_COLOR];
    issueCover.adjustsImageWhenHighlighted = NO;
    issueCover.adjustsImageWhenDisabled = NO;
        
    issueCover.layer.shadowOpacity = 0.5;
    issueCover.layer.shadowOffset = CGSizeMake(0, 2);
    issueCover.layer.shouldRasterize = YES;
    issueCover.layer.rasterizationScale = [UIScreen mainScreen].scale;
    
    [self.view addSubview:issueCover];

    // SETUP USED FONTS
    self.titleFont = [UIFont fontWithName:ISSUES_TITLE_FONT size:ISSUES_TITLE_FONT_SIZE];
    self.infoFont = [UIFont fontWithName:ISSUES_INFO_FONT size:ISSUES_INFO_FONT_SIZE];

    #ifdef BAKER_NEWSSTAND
    // RESUME PENDING NEWSSTAND DOWNLOAD
    NKLibrary *nkLib = [NKLibrary sharedLibrary];
    for (NKAssetDownload *asset in [nkLib downloadingAssets]) {
        if ([asset.issue.name isEqualToString:self.issue.ID]) {
            NSLog(@"[BakerShelf] Resuming abandoned Newsstand download: %@", asset.issue.name);
            [self.issue downloadWithAsset:asset];
        }
    }
    #endif

    // SETUP STATUS
    self.statusview = [[StatusView alloc] initWithFrame:CGRectMake(0, -1, 181, 233)];
    statusview.delegate = self;
    [self.view addSubview:statusview];
    
#ifdef BAKER_NEWSSTAND
    self.longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(actionLongPress:)];
    longPress.numberOfTouchesRequired = 1;
    [self.issueCover addGestureRecognizer:longPress];
    
    self.tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(actionButtonPressed:)];
    tap.numberOfTouchesRequired = 1;
    [self.issueCover addGestureRecognizer:tap];
#endif

#ifdef BAKER_NEWSSTAND
    // status
    statusbar = [[UIImageView alloc] initWithFrame:CGRectMake(0, 212, 181, 22)];
    statusbar.image = [UIImage imageNamed:@"status_bg.png"];
    [self.view addSubview:statusbar];
    
    titleLabel = [[UILabel alloc] init];
    titleLabel.font = [UIFont fontWithName:@"Arial" size:12];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.textColor = [UIColor whiteColor];
    [self.view addSubview:titleLabel];
    
    priceLabel = [[UILabel alloc] init];
    priceLabel.text = @"$0.99";
    priceLabel.textAlignment = NSTextAlignmentRight;
    priceLabel.font = [UIFont fontWithName:@"Arial" size:12];
    priceLabel.backgroundColor = [UIColor clearColor];
    priceLabel.textColor = [UIColor whiteColor];
    [self.view addSubview:priceLabel];
    
#endif

    [self refreshContentWithCache:NO];
}
- (void)refreshContentWithCache:(bool)cache {
    UI ui = [IssueViewController getIssueContentMeasures];
    int heightOffset = ui.cellPadding;
    uint textLineheight = [@"The brown fox jumps over the lazy dog" sizeWithFont:infoFont constrainedToSize:CGSizeMake(MAXFLOAT, MAXFLOAT)].height;

    // SETUP COVER IMAGE
    [self.issue getCoverWithCache:cache andBlock:^(UIImage *image) {
        [issueCover setBackgroundImage:image forState:UIControlStateNormal];
    }];

    // SETUP TITLE LABEL
    CGSize titleSize = [self.issue.title sizeWithFont:titleFont constrainedToSize:CGSizeMake(170, MAXFLOAT) lineBreakMode:UILineBreakModeWordWrap];
    uint titleLines = MIN(4, titleSize.height / textLineheight);

    titleLabel.frame = CGRectMake(2, self.view.bounds.size.height - 18, 170, textLineheight * titleLines);
    titleLabel.numberOfLines = titleLines;
    titleLabel.text = self.issue.title;

    heightOffset = heightOffset + titleLabel.frame.size.height + 5;

    // SETUP INFO LABEL
    CGSize infoSize = [self.issue.info sizeWithFont:infoFont constrainedToSize:CGSizeMake(170, MAXFLOAT) lineBreakMode:UILineBreakModeWordWrap];
    uint infoLines = MIN(4, infoSize.height / textLineheight);

    infoLabel.frame = CGRectMake(ui.contentOffset, heightOffset, 170, textLineheight * infoLines);
    infoLabel.numberOfLines = infoLines;
    infoLabel.text = self.issue.info;

    heightOffset = heightOffset + infoLabel.frame.size.height + 5;

    // SETUP PRICE LABEL
    self.priceLabel.frame = CGRectMake(2, self.view.bounds.size.height - 18, 178, textLineheight);

    heightOffset = heightOffset + priceLabel.frame.size.height + 10;

    // SETUP ACTION BUTTON
    NSString *status = [self.issue getStatus];
    if ([status isEqualToString:@"remote"] || [status isEqualToString:@"purchasable"] || [status isEqualToString:@"purchased"]) {
        actionButton.frame = CGRectMake(ui.contentOffset, heightOffset, 110, 30);
    } else if ([status isEqualToString:@"downloaded"] || [status isEqualToString:@"bundled"]) {
        actionButton.frame = CGRectMake(ui.contentOffset, heightOffset, 80, 30);
    }

    // SETUP ARCHIVE BUTTON
    archiveButton.frame = CGRectMake(ui.contentOffset + 80 + 10, heightOffset, 80, 30);
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self refresh];
}
- (void)refresh
{
    [self refresh:[self.issue getStatus]];
}
- (void)refresh:(NSString *)status
{
    //NSLog(@"[BakerShelf] Shelf UI - Refreshing %@ item with status from <%@> to <%@>", self.issue.ID, self.currentStatus, status);
    if ([status isEqualToString:@"remote"])
    {
        [self.priceLabel setText:NSLocalizedString(@"FREE_TEXT", nil)];

        [self.actionButton setTitle:NSLocalizedString(@"ACTION_REMOTE_TEXT", nil) forState:UIControlStateNormal];

        self.actionButton.hidden = NO;
        self.archiveButton.hidden = YES;
        self.priceLabel.hidden = NO;
        
        self.statusview.hidden = NO;
        self.statusview.downloadStatus = Nothing;
    }
    else if ([status isEqualToString:@"connecting"])
    {
        NSLog(@"[BakerShelf] '%@' is Connecting...", self.issue.ID);

        self.actionButton.hidden = YES;
        self.archiveButton.hidden = YES;
        self.priceLabel.hidden = YES;
    }
    else if ([status isEqualToString:@"downloading"])
    {
        NSLog(@"[BakerShelf] '%@' is Downloading...", self.issue.ID);

        self.actionButton.hidden = YES;
        self.archiveButton.hidden = YES;
        self.priceLabel.hidden = YES;
        statusview.downloadStatus = Downloading;
    }
    else if ([status isEqualToString:@"downloaded"])
    {
        NSLog(@"[BakerShelf] '%@' is Ready to be Read.", self.issue.ID);
        [self.actionButton setTitle:NSLocalizedString(@"ACTION_DOWNLOADED_TEXT", nil) forState:UIControlStateNormal];

        self.actionButton.hidden = NO;
        self.archiveButton.hidden = NO;
        self.priceLabel.hidden = YES;
        statusview.downloadStatus = Finished;
    }
    else if ([status isEqualToString:@"bundled"])
    {
        [self.actionButton setTitle:NSLocalizedString(@"ACTION_DOWNLOADED_TEXT", nil) forState:UIControlStateNormal];

        self.actionButton.hidden = NO;
        self.archiveButton.hidden = YES;
        self.priceLabel.hidden = YES;
    }
    else if ([status isEqualToString:@"opening"])
    {

        self.actionButton.hidden = YES;
        self.archiveButton.hidden = YES;
        self.priceLabel.hidden = YES;
    }
    else if ([status isEqualToString:@"purchasable"])
    {
        [self.actionButton setTitle:NSLocalizedString(@"ACTION_BUY_TEXT", nil) forState:UIControlStateNormal];

        if (self.issue.price) {
            [self.priceLabel setText:self.issue.price];
        }

        self.actionButton.hidden = NO;
        self.archiveButton.hidden = YES;
        self.priceLabel.hidden = NO;
    }
    else if ([status isEqualToString:@"purchasing"])
    {
        NSLog(@"[BakerShelf] '%@' is being Purchased...", self.issue.ID);

        self.actionButton.hidden = YES;
        self.archiveButton.hidden = YES;
        self.priceLabel.hidden = NO;
    }
    else if ([status isEqualToString:@"purchased"])
    {
        NSLog(@"[BakerShelf] '%@' is Purchased.", self.issue.ID);
        [self.priceLabel setText:NSLocalizedString(@"PURCHASED_TEXT", nil)];

        [self.actionButton setTitle:NSLocalizedString(@"ACTION_REMOTE_TEXT", nil) forState:UIControlStateNormal];

        self.actionButton.hidden = NO;
        self.archiveButton.hidden = YES;
        self.priceLabel.hidden = NO;
    }
    else if ([status isEqualToString:@"unpriced"])
    {
        self.actionButton.hidden = YES;
        self.archiveButton.hidden = YES;
        self.priceLabel.hidden = YES;
    }

    [self refreshContentWithCache:YES];

    self.currentStatus = status;
}

#pragma mark - Memory management

- (void)dealloc
{
    [issue release];
    [actionButton release];
    [archiveButton release];
    [priceLabel release];
    [issueCover release];
    [titleFont release];
    [infoFont release];
    [titleLabel release];
    [infoLabel release];
    [currentStatus release];
    [statusview release];
    [statusbar release];
    [longPress release];
    [tap release];

    [super dealloc];
}

#pragma mark - Issue management

- (void)actionButtonPressed:(UIButton *)sender
{
    NSString *status = [self.issue getStatus];
    if ([status isEqualToString:@"remote"] || [status isEqualToString:@"purchased"]) {
    #ifdef BAKER_NEWSSTAND
        [self download];
    #endif
    } else if ([status isEqualToString:@"downloaded"] || [status isEqualToString:@"bundled"]) {
        [self read];
    } else if ([status isEqualToString:@"downloading"]) {
        // TODO: assuming it is supported by NewsstandKit, implement a "Cancel" operation
    } else if ([status isEqualToString:@"purchasable"]) {
    #ifdef BAKER_NEWSSTAND
        [self buy];
    #endif
    }
}

#ifdef BAKER_NEWSSTAND
- (void) actionLongPress:(UILongPressGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateBegan)
    {   
        [self archiveButtonPressed:nil];
    }
}
#endif

#ifdef BAKER_NEWSSTAND
- (void)download {
    [self.issue download];
}
- (void)buy {
    [self addPurchaseObserver:@selector(handleIssuePurchased:) name:@"notification_issue_purchased"];
    [self addPurchaseObserver:@selector(handleIssuePurchaseFailed:) name:@"notification_issue_purchase_failed"];

    if (![purchasesManager purchase:self.issue.productID]) {
        // Still retrieving SKProduct: delay purchase
        purchaseDelayed = YES;

        [self removePurchaseObserver:@"notification_issue_purchased"];
        [self removePurchaseObserver:@"notification_issue_purchase_failed"];

        [purchasesManager retrievePriceFor:self.issue.productID];

        self.issue.transientStatus = BakerIssueTransientStatusUnpriced;
        [self refresh];
    } else {
        self.issue.transientStatus = BakerIssueTransientStatusPurchasing;
        [self refresh];
    }
}
- (void)handleIssuePurchased:(NSNotification *)notification {
    SKPaymentTransaction *transaction = [notification.userInfo objectForKey:@"transaction"];

    if ([transaction.payment.productIdentifier isEqualToString:issue.productID]) {

        [self removePurchaseObserver:@"notification_issue_purchased"];
        [self removePurchaseObserver:@"notification_issue_purchase_failed"];

        [purchasesManager markAsPurchased:transaction.payment.productIdentifier];

        if ([purchasesManager finishTransaction:transaction]) {
            if (!transaction.originalTransaction) {
                // Do not show alert on restoring a transaction
                [Utils showAlertWithTitle:NSLocalizedString(@"ISSUE_PURCHASE_SUCCESSFUL_TITLE", nil)
                                  message:[NSString stringWithFormat:NSLocalizedString(@"ISSUE_PURCHASE_SUCCESSFUL_MESSAGE", nil), self.issue.title]
                              buttonTitle:NSLocalizedString(@"ISSUE_PURCHASE_SUCCESSFUL_CLOSE", nil)];
            }
        } else {
            [Utils showAlertWithTitle:NSLocalizedString(@"TRANSACTION_RECORDING_FAILED_TITLE", nil)
                              message:NSLocalizedString(@"TRANSACTION_RECORDING_FAILED_MESSAGE", nil)
                          buttonTitle:NSLocalizedString(@"TRANSACTION_RECORDING_FAILED_CLOSE", nil)];
        }

        self.issue.transientStatus = BakerIssueTransientStatusNone;
        [purchasesManager retrievePurchasesFor:[NSSet setWithObject:self.issue.productID]];
        [self refresh]; 
    }
}
- (void)handleIssuePurchaseFailed:(NSNotification *)notification {
    SKPaymentTransaction *transaction = [notification.userInfo objectForKey:@"transaction"];

    if ([transaction.payment.productIdentifier isEqualToString:issue.productID]) {
        // Show an error, unless it was the user who cancelled the transaction
        if (transaction.error.code != SKErrorPaymentCancelled) {
            [Utils showAlertWithTitle:NSLocalizedString(@"ISSUE_PURCHASE_FAILED_TITLE", nil)
                              message:[transaction.error localizedDescription]
                          buttonTitle:NSLocalizedString(@"ISSUE_PURCHASE_FAILED_CLOSE", nil)];
        }

        [self removePurchaseObserver:@"notification_issue_purchased"];
        [self removePurchaseObserver:@"notification_issue_purchase_failed"];

        self.issue.transientStatus = BakerIssueTransientStatusNone;
        [self refresh];
    }
    
    self.statusview.downloadStatus = Nothing;
}

- (void)handleIssueRestored:(NSNotification *)notification {
    SKPaymentTransaction *transaction = [notification.userInfo objectForKey:@"transaction"];

    if ([transaction.payment.productIdentifier isEqualToString:issue.productID]) {
        [purchasesManager markAsPurchased:transaction.payment.productIdentifier];

        if (![purchasesManager finishTransaction:transaction]) {
            NSLog(@"[BakerShelf] Could not confirm purchase restore with remote server for %@", transaction.payment.productIdentifier);
        }

        self.issue.transientStatus = BakerIssueTransientStatusNone;
        [self refresh];
    }
}

- (void)setPrice:(NSString *)price {
    self.issue.price = price;
    if (purchaseDelayed) {
        purchaseDelayed = NO;
        [self buy];
    } else {
        [self refresh];
    }
}
#endif
- (void)read
{
    self.issue.transientStatus = BakerIssueTransientStatusOpening;
    [self refresh];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"read_issue_request" object:self];
}

#pragma mark - Newsstand download management

- (void)handleDownloadStarted:(NSNotification *)notification {
    [self refresh];
}
- (void)handleDownloadProgressing:(NSNotification *)notification {
    float bytesWritten = [[notification.userInfo objectForKey:@"totalBytesWritten"] floatValue];
    float bytesExpected = [[notification.userInfo objectForKey:@"expectedTotalBytes"] floatValue];

    if ([self.currentStatus isEqualToString:@"connecting"]) {
        self.issue.transientStatus = BakerIssueTransientStatusDownloading;
        [self refresh];
    }
//    [self.progressBar setProgress:(bytesWritten / bytesExpected) animated:YES];
    
    
    statusview.pro = (bytesWritten / bytesExpected);
    
    NSLog(@"%f", (bytesWritten / bytesExpected));
}

- (void)handleDownloadFinished:(NSNotification *)notification {
    self.issue.transientStatus = BakerIssueTransientStatusNone;
    [self refresh];
}
- (void)handleDownloadError:(NSNotification *)notification {
    [Utils showAlertWithTitle:NSLocalizedString(@"DOWNLOAD_FAILED_TITLE", nil)
                      message:NSLocalizedString(@"DOWNLOAD_FAILED_MESSAGE", nil)
                  buttonTitle:NSLocalizedString(@"DOWNLOAD_FAILED_CLOSE", nil)];

    self.issue.transientStatus = BakerIssueTransientStatusNone;
    [self refresh];
}

#pragma mark - StatusViewDelegate
- (void) start:(StatusView *)status
{
    NSString *issueStatus = [self.issue getStatus];
    if ([issueStatus isEqualToString:@"remote"] || [issueStatus isEqualToString:@"purchased"]) {
#ifdef BAKER_NEWSSTAND
        [self download];
#endif
    } else if ([issueStatus isEqualToString:@"downloaded"] || [issueStatus isEqualToString:@"bundled"]) {
        [self read];
    } else if ([issueStatus isEqualToString:@"downloading"]) {
        // TODO: assuming it is supported by NewsstandKit, implement a "Cancel" operation
    } else if ([issueStatus isEqualToString:@"purchasable"]) {
#ifdef BAKER_NEWSSTAND
        [self buy];
#endif
    }
}

- (void) pause:(StatusView *)status
{
    
}

- (void) goon:(StatusView *)status
{

}

- (void) end:(StatusView *)status
{
    statusview.hidden = YES;
}

#pragma mark - Newsstand archive management

#ifdef BAKER_NEWSSTAND
- (void)archiveButtonPressed:(UIButton *)sender
{
    UIAlertView *updateAlert = [[UIAlertView alloc]
                                initWithTitle: NSLocalizedString(@"ARCHIVE_ALERT_TITLE", nil)
                                message: NSLocalizedString(@"ARCHIVE_ALERT_MESSAGE", nil)
                                delegate: self
                                cancelButtonTitle: NSLocalizedString(@"ARCHIVE_ALERT_BUTTON_CANCEL", nil)
                                otherButtonTitles: NSLocalizedString(@"ARCHIVE_ALERT_BUTTON_OK", nil), nil];
    [updateAlert show];
    [updateAlert release];
}

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == 1){
        NKLibrary *nkLib = [NKLibrary sharedLibrary];
        NKIssue *nkIssue = [nkLib issueWithName:self.issue.ID];
        NSString *name = nkIssue.name;
        NSDate *date = nkIssue.date;
        
        [nkLib removeIssue:nkIssue];
        
        nkIssue = [nkLib addIssueWithName:name date:date];
        self.issue.path = [[nkIssue contentURL] path];
        
        [self refresh];
    }
}
#endif

#pragma mark - Helper methods

- (void)addPurchaseObserver:(SEL)notificationSelector name:(NSString *)notificationName {
    #ifdef BAKER_NEWSSTAND
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:notificationSelector
                                                 name:notificationName
                                               object:purchasesManager];
    #endif
}

- (void)removePurchaseObserver:(NSString *)notificationName {
    #ifdef BAKER_NEWSSTAND
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:notificationName
                                                  object:purchasesManager];
    #endif
}

- (void)addIssueObserver:(SEL)notificationSelector name:(NSString *)notificationName {
    #ifdef BAKER_NEWSSTAND
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:notificationSelector
                                                 name:notificationName
                                               object:nil];
    #endif
}

+ (UI)getIssueContentMeasures
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        UI iPad = {
            .cellPadding   = 0,
            .thumbWidth    = 181,
            .thumbHeight   = 233,
            .contentOffset = 184
        };
        return iPad;
    } else {
        UI iPhone = {
            .cellPadding   = 0,
            .thumbWidth    = 87,
            .thumbHeight   = 116,
            .contentOffset = 128
        };
        return iPhone;
    }
}

+ (int)getIssueCellHeight
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return 240;
    } else {
        return 156;
    }
}
+ (CGSize)getIssueCellSize
{
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return CGSizeMake(209, [IssueViewController getIssueCellHeight]);
    } else {
        return CGSizeMake(screenRect.size.width - 2, [IssueViewController getIssueCellHeight]);
    }
}

@end
