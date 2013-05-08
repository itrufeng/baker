//
//  UICustomTableViewCell.m
//  Baker
//
//  Created by 张 舰 on 4/25/13.
//
//

#import "UICustomTableViewCell.h"

#import "IssueViewController.h"

@interface UICustomTableViewCell ()

// 整个背景
@property (retain, nonatomic) UIImageView *backgroundImage;

// issue阴影
@property (retain, nonatomic) UIImageView *shadow0;
@property (retain, nonatomic) UIImageView *shadow1;
@property (retain, nonatomic) UIImageView *shadow2;

// issue
@property (retain, nonatomic) UIView *issue0;
@property (retain, nonatomic) UIView *issue1;
@property (retain, nonatomic) UIView *issue2;

@end

@implementation UICustomTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        _backgroundImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 768, 291)];
        _backgroundImage.image = [UIImage imageNamed:@"cell-bg.png"];
        [self addSubview:_backgroundImage];
        
        // shadows
        _shadow0 = [[UIImageView alloc] initWithFrame:CGRectMake(55, 29, 209, 235)];
        _shadow0.userInteractionEnabled = YES;
        _shadow0.image = [UIImage imageNamed:@"book-shadow.png"];
        [self addSubview:_shadow0];
        
        _shadow1 = [[UIImageView alloc] initWithFrame:CGRectMake(_shadow0.frame.origin.x + _shadow0.frame.size.width + 15, 29, 209, 235)];
        _shadow1.userInteractionEnabled = YES;
        _shadow1.image = [UIImage imageNamed:@"book-shadow.png"];
        [self addSubview:_shadow1];
        
        _shadow2 = [[UIImageView alloc] initWithFrame:CGRectMake(_shadow1.frame.origin.x + _shadow1.frame.size.width + 15, 29, 209, 235)];
        _shadow2.userInteractionEnabled = YES;
        _shadow2.image = [UIImage imageNamed:@"book-shadow.png"];
        [self addSubview:_shadow2];
        
        // issues
        _issue0 = [[UIView alloc] initWithFrame:CGRectMake(14, 1, 181, 233)];
        [_shadow0 addSubview:_issue0];
        
        _issue1 = [[UIView alloc] initWithFrame:CGRectMake(14, 1, 181, 233)];
        [_shadow1 addSubview:_issue1];
        
        _issue2 = [[UIView alloc] initWithFrame:CGRectMake(14, 1, 181, 233)];
        [_shadow2 addSubview:_issue2];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)dealloc
{
    [_backgroundImage release];
    [_issueViewControllers release];
    [_shadow0 release];
    [_shadow1 release];
    [_shadow2 release];
    [_issue0 release];
    [_issue1 release];
    [_issue2 release];
    
    [super dealloc];
}

- (void) setIssueViewControllers:(NSArray *)issueViewControllers
{
    _issueViewControllers = issueViewControllers;
    
    [self _clearsubViews:_issue0];
    [self _clearsubViews:_issue1];
    [self _clearsubViews:_issue2];
    
    for (int i = 0, x = 0; i < [_issueViewControllers count]; i++, x+=209+30)
    {
        CGRect frame = CGRectMake(0, 0, _issue0.frame.size.width, _issue0.frame.size.height);
        
        IssueViewController *issueViewController = [_issueViewControllers objectAtIndex:i];
        issueViewController.view.frame = frame;
        
        switch (i) {
            case 0:
            {
                [_issue0 addSubview:issueViewController.view];
                break;
            }
            case 1:
            {
                [_issue1 addSubview:issueViewController.view];
                break;
            }
            case 2:
            {
                [_issue2 addSubview:issueViewController.view];
                break;
            }
            default:
            {
                NSAssert(YES, @"只能出现3个issueViewController");
                break;
            }
        }
    }
}

- (void) _clearsubViews:(UIView *)view
{
    for (UIView *subView in view.subviews)
    {
        [subView removeFromSuperview];
    }
}

@end
