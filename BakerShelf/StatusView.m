//
//  StatusView.m
//  Baker
//
//  Created by 张 舰 on 5/2/13.
//
//

#import "StatusView.h"

typedef enum {Nothing,Downloading,Paused,Finished} DownloadStatus;

@interface StatusView ()

// 点击下载
@property (retain, nonatomic) UIImageView *downloadImage;
@property (retain, nonatomic) UIImageView *downloadingImage;
@property (retain, nonatomic) UIImageView *pausedImage;
@property (retain, nonatomic) UILabel *proLabel;

@property (retain, nonatomic) UITapGestureRecognizer *tap;
@property (assign, nonatomic) DownloadStatus downloadStatus;

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
        
        // pausedImage
        _pausedImage = [[UIImageView alloc] initWithFrame:CGRectMake(95, 0, 88, 88)];
        _pausedImage.hidden = YES;
        _pausedImage.image = [UIImage imageNamed:@"pause-bg.png"];
        [self addSubview:_pausedImage];
        
        // proLabel
        _proLabel = [[UILabel alloc] initWithFrame:CGRectMake(128, 10, 70, 20)];
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
    [_pausedImage release];
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
            _pausedImage.hidden = YES;
            _proLabel.hidden = YES;
            break;
        }
        case Downloading:
        {
            _downloadImage.hidden = YES;
            _downloadingImage.hidden = NO;
            _pausedImage.hidden = YES;
            _proLabel.hidden = NO;
            break;
        }
        case Paused:
        {
            _downloadImage.hidden = YES;
            _downloadingImage.hidden = YES;
            _pausedImage.hidden = NO;
            _proLabel.hidden = YES;
            break;
        }
        case Finished:
        {
            _downloadImage.hidden = YES;
            _downloadingImage.hidden = YES;
            _pausedImage.hidden = YES;
            _proLabel.hidden = YES;
            break;
        }
        default:
            break;
    }
}

- (void) setPro:(CGFloat)pro
{
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
            self.proLabel.text = [NSString stringWithFormat:@"%1.0f%%", _pro * 100];
        }
    }
    else if (_pro >= 1.0f)
    {
        self.downloadStatus = Finished;
        
        if ([self.delegate respondsToSelector:@selector(end:)])
        {
            [self.delegate end:self];
        }
    }
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
        {
            self.downloadStatus = Paused;
            
            if ([self.delegate respondsToSelector:@selector(pause:)])
            {
                [self.delegate pause:self];
            }
            
            break;
        }
        case Paused:
        {
            self.downloadStatus = Downloading;
            
            if ([self.delegate respondsToSelector:@selector(goon:)])
            {
                [self.delegate goon:self];
            }
            
            break;
        }
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
