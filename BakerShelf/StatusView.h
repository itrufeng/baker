//
//  StatusView.h
//  Baker
//
//  Created by 张 舰 on 5/2/13.
//
//

#import <UIKit/UIKit.h>

@protocol StatusViewDelegate;

@interface StatusView : UIView

@property (retain, nonatomic) NSString *identify;
@property (assign, nonatomic) CGFloat pro;
@property (assign, nonatomic) id<StatusViewDelegate> delegate;

@end

@protocol StatusViewDelegate <NSObject>

@optional
- (void) start:(StatusView *)status;

- (void) pause:(StatusView *)status;

- (void) goon:(StatusView *)status;

- (void) end:(StatusView *)status;

@end
