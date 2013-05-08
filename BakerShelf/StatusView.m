//
//  StatusView.m
//  Baker
//
//  Created by 张 舰 on 5/2/13.
//
//

#import "StatusView.h"

@interface StatusView ()

// 点击下载
@property (retain, nonatomic) UIImageView *downloadImage;
@property (retain, nonatomic) UIImageView *downloadingImage;
@property (retain, nonatomic) UILabel *proLabel;

@property (retain, nonatomic) UITapGestureRecognizer *tap;

@end

@implementation StatusView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.clipsToBounds = YES;
        
        // tap
        _tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                       action:@selector(tapThis)];
        _tap.numberOfTapsRequired = 1;
        _tap.numberOfTouchesRequired = 1;
        [self addGestureRecognizer:_tap];
        
        // downloadImages
        _downloadImage = [[UIImageView alloc] initWithFrame:CGRectMake(95, 0, 88, 88)];
        _downloadImage.hidden = YES;
        _downloadImage.image = [UIImage imageNamed:@"download-bg.png"];
        [self addSubview:_downloadImage];
        
        // downloadingImage
        _downloadingImage = [[UIImageView alloc] initWithFrame:CGRectMake(95, 0, 88, 88)];
        _downloadingImage.hidden = YES;
        _downloadingImage.image = [UIImage imageNamed:@"downloading-bg.png"];
        [self addSubview:_downloadingImage];
        
        // proLabel
        _proLabel = [[UILabel alloc] initWithFrame:CGRectMake(128, 8, 70, 20)];
        _proLabel.font = [UIFont fontWithName:@"Arial" size:12];
        _proLabel.textAlignment = NSTextAlignmentCenter;
        _proLabel.hidden = YES;
        _proLabel.backgroundColor = [UIColor clearColor];
        _proLabel.text = @"0%";
        [self insertSubview:_proLabel aboveSubview:_downloadingImage];
        
        self.pro = 0.0f;
        self.downloadStatus = Nothing;
        
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)dealloc
{
    [_downloadImage release];
    [_identify release];
    [_tap release];
    [_downloadingImage release];
    [_proLabel release];
    
    [super dealloc];
}

- (void) setDownloadStatus:(DownloadStatus)DownloadStatus
{
    _downloadStatus = DownloadStatus;
    switch (_downloadStatus)
    {
        case Nothing:
        {
            _downloadImage.hidden = NO;
            _downloadingImage.hidden = YES;
            _proLabel.hidden = YES;
            
            _proLabel.text = @"0%";
            break;
        }
        case Downloading:
        {
            _downloadImage.hidden = YES;
            _downloadingImage.hidden = NO;
            _proLabel.hidden = NO;
            break;
        }
        case Finished:
        {
            _downloadImage.hidden = YES;
            _downloadingImage.hidden = YES;
            _proLabel.hidden = YES;
            
            if ([self.delegate respondsToSelector:@selector(end:)])
            {
                [self.delegate end:self];
            }
            
            break;
        }
        default:
            break;
    }
}

- (void) setPro:(CGFloat)pro
{
    dispatch_async(dispatch_get_main_queue(),
                   ^{
                       _pro = pro;
                       
                       if (_pro <= 0.0f)
                       {
                           self.downloadStatus = Nothing;
                       }
                       else if (_pro > 0.0f &&
                                _pro < 1.0f)
                       {
                           if (self.downloadStatus != Downloading)
                           {
                               self.downloadStatus = Downloading;
                           }
                           self.proLabel.text = [NSString stringWithFormat:@"%1.0f%%", _pro * 100];
                       }
                       else if (_pro >= 1.0f)
                       {
                           self.downloadStatus = Finished;
                           
                           if ([self.delegate respondsToSelector:@selector(end:)])
                           {
                               [self.delegate end:self];
                           }
                       }
                       
                       [_proLabel setNeedsDisplay];
                   });
}

- (void) tapThis
{
    switch (_downloadStatus)
    {
        case Nothing:
        {
            self.downloadStatus = Downloading;
            
            if ([self.delegate respondsToSelector:@selector(start:)])
            {
                [self.delegate start:self];
            }
            
            break;
        }
        case Downloading:
        case Finished:
        {
            break;
        }
        default:
        {
            break;
            NSAssert(NO, @"不成立");
        }
    }
}

@end
