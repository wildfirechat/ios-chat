//
//  WFCUWaitingAnimationView.m
//  WFChatUIKit
//
//  Created by Tom Lee on 2020/2/23.
//  Copyright © 2020 Tom Lee. All rights reserved.
//

#import "WFCUWaitingAnimationView.h"

@interface WFCUWaitingAnimationView ()
@property(nonatomic, strong)NSTimer *animatedTimer;
@property(nonatomic, assign)int index;
@property(nonatomic, strong)UIImageView *centerImageView;
@end

@implementation WFCUWaitingAnimationView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
- (void)start {
    if (!self.animatedTimer) {
        self.animatedTimer = [NSTimer scheduledTimerWithTimeInterval:self.animationDuration target:self selector:@selector(setNextImage) userInfo:nil repeats:YES];
        [self setNextImage];
    }
}

-(void)setNextImage
{
    if (!self.animationImages.count) {
        return;
    }
    
    self.index++;
    if (self.index >= self.animationImages.count) {
        self.index = 0;
    }
    self.centerImageView.image = [self.animationImages objectAtIndex:self.index];
}

- (void)stop {
    [self.animatedTimer invalidate];
    self.animatedTimer = nil;
    self.centerImageView.image = nil;
}

- (void)setImage:(UIImage *)image {
    self.centerImageView.image = image;
}

- (UIImageView *)centerImageView {
    if (!_centerImageView) {
        CGFloat width = self.frame.size.width;
        _centerImageView = [[UIImageView alloc] initWithFrame:CGRectMake(width/4, width/4, width/2, width/2)];
        [self addSubview:_centerImageView];
    }
    return _centerImageView;
}
@end
