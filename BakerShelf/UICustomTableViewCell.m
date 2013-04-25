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

// 点击下载
@property (retain, nonatomic) UIImageView *downloadImage0;
@property (retain, nonatomic) UIImageView *downloadImage1;
@property (retain, nonatomic) UIImageView *downloadImage2;

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
        _shadow0.image = [UIImage imageNamed:@"book-shadow.png"];
        [self addSubview:_shadow0];
        
        _shadow1 = [[UIImageView alloc] initWithFrame:CGRectMake(_shadow0.frame.origin.x + _shadow0.frame.size.width + 15, 29, 209, 235)];
        _shadow1.image = [UIImage imageNamed:@"book-shadow.png"];
        [self addSubview:_shadow1];
        
        _shadow2 = [[UIImageView alloc] initWithFrame:CGRectMake(_shadow1.frame.origin.x + _shadow1.frame.size.width + 15, 29, 209, 235)];
        _shadow2.image = [UIImage imageNamed:@"book-shadow.png"];
        [self addSubview:_shadow2];
        
        // issues
        _issue0 = [[UIView alloc] initWithFrame:CGRectMake(_shadow0.frame.origin.x + 14, 29, 181, 233)];
        _issue0.backgroundColor = [UIColor redColor];
        [self addSubview:_issue0];
        
        _issue1 = [[UIView alloc] initWithFrame:CGRectMake(_shadow1.frame.origin.x + 14, 29, 181, 233)];
        _issue1.backgroundColor = [UIColor redColor];
        [self addSubview:_issue1];
        
        _issue2 = [[UIView alloc] initWithFrame:CGRectMake(_shadow2.frame.origin.x + 14, 29, 181, 233)];
        _issue2.backgroundColor = [UIColor redColor];
        [self addSubview:_issue2];
        
        // downloadImages
        _downloadImage0 = [[UIImageView alloc] initWithFrame:CGRectMake(_issue0.frame.origin.x + 95, 28, 88, 88)];
        _downloadImage0.image = [UIImage imageNamed:@"download-bg.png"];
        [self addSubview:_downloadImage0];
        
        _downloadImage1 = [[UIImageView alloc] initWithFrame:CGRectMake(_issue1.frame.origin.x +95, 28, 88, 88)];
        _downloadImage1.image = [UIImage imageNamed:@"download-bg.png"];
        [self addSubview:_downloadImage1];
        
        _downloadImage2 = [[UIImageView alloc] initWithFrame:CGRectMake(_issue2.frame.origin.x + 95, 28, 88, 88)];
        _downloadImage2.image = [UIImage imageNamed:@"download-bg.png"];
        [self addSubview:_downloadImage2];
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
    [_downloadImage0 release];
    [_downloadImage1 release];
    [_downloadImage2 release];
    
    [super dealloc];
}

- (void) setIssueViewControllers:(NSArray *)issueViewControllers
{
    _issueViewControllers = issueViewControllers;
    
    for (int i = 0, x = 0; i < [_issueViewControllers count]; i++, x+=209+30)
    {
        CGRect frame = CGRectMake(x, 0, 209, 235);
        
        if (<#condition#>) {
            <#statements#>
        }
    }
}

@end
