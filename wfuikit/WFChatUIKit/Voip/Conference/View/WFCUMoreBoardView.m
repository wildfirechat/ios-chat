//
//  WFCUMoreBoardView.m
//  WFChatUIKit
//
//  Created by Rain on 2022/9/28.
//  Copyright © 2022 Tom Lee. All rights reserved.
//

#import "WFCUMoreBoardView.h"

@implementation MoreItem
- (instancetype)initWithTitle:(NSString *)title image:(UIImage *)image callback:(MoreItem *(^)(void))onClicked; {
    self = [super init];
    if (self) {
        self.title = title;
        self.image = image;
        self.onClicked = onClicked;
    }
    return self;
}
@end


@interface WFCUMoreBoardView ()
@property(nonatomic, strong)NSArray<MoreItem *> *items;
@property(nonatomic, strong)void(^cancelBlock)(WFCUMoreBoardView *boardView);
@end

#define ITEM_COUNT_OF_LINE 4

#define ITEM_SIZE 48
#define CANCEL_BTN_HEIGHT 36

@implementation WFCUMoreBoardView
- (instancetype)initWithItems:(NSArray<MoreItem *> *)items cancel:(void(^)(WFCUMoreBoardView *boardView))cancelBlock {
    self = [super initWithFrame:CGRectZero];
    if(self) {
        self.items = items;
        self.cancelBlock = cancelBlock;
        [self setupSubViews];
    }
    return self;
}

- (void)setupSubViews {
    self.backgroundColor = [UIColor colorWithRed:0.2 green:0.37 blue:0.9 alpha:1];
    for (int i = 0; i < self.items.count; i++) {
        [self addButtonAtIndex:i];
    }
    
    CGFloat boardWidth = [UIScreen mainScreen].bounds.size.width - 16 - 16;
    CGFloat padding = boardWidth/ITEM_COUNT_OF_LINE - ITEM_SIZE;
    
    int line = (int)self.items.count / ITEM_COUNT_OF_LINE;
    UIButton *cancelBtn = [[UIButton alloc] initWithFrame:CGRectMake(16, (padding+ITEM_SIZE)*(line+1), boardWidth - 32, CANCEL_BTN_HEIGHT)];
    [cancelBtn setTitle:@"取消" forState:UIControlStateNormal];
    [cancelBtn addTarget:self action:@selector(onCancelBtn:) forControlEvents:UIControlEventTouchDown];
    cancelBtn.titleLabel.font = [UIFont systemFontOfSize:16];
    cancelBtn.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1];
    cancelBtn.layer.masksToBounds = YES;
    cancelBtn.layer.cornerRadius = 5.f;
    [self addSubview:cancelBtn];
    
    
    self.frame = CGRectMake(16, 0, boardWidth, (line+1)*(padding+ITEM_SIZE) + CANCEL_BTN_HEIGHT + 16);
    
    self.layer.masksToBounds = YES;
    self.layer.cornerRadius = 10.f;
}

- (void)addButtonAtIndex:(int)i {
    CGFloat boardWidth = [UIScreen mainScreen].bounds.size.width - 16 - 16;
    CGFloat padding = boardWidth/ITEM_COUNT_OF_LINE - ITEM_SIZE;
    
    int line = i / ITEM_COUNT_OF_LINE;
    int row = i % ITEM_COUNT_OF_LINE;
    
    CGFloat startX = padding/2 + (ITEM_SIZE + padding) * row;
    CGFloat startY = padding/2 + (ITEM_SIZE + padding) * line;
    
    MoreItem *item = self.items[i];
    
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(startX, startY, ITEM_SIZE, ITEM_SIZE)];
    btn.tag = i;
    [btn setImage:item.image forState:UIControlStateNormal];
    [btn setTitle:item.title forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:12];
    btn.titleEdgeInsets = UIEdgeInsetsMake(btn.imageView.frame.size.height / 2-6, -btn.imageView.frame.size.width, -btn.imageView.frame.size.height, 0);
    btn.imageEdgeInsets = UIEdgeInsetsMake(-4, 0, btn.imageView.frame.size.height / 2, -btn.titleLabel.bounds.size.width);
    
    [btn addTarget:self action:@selector(onClickItem:) forControlEvents:UIControlEventTouchDown];
    
    [self addSubview:btn];
}

- (void)onCancelBtn:(UIButton *)btn {
    if(self.cancelBlock) {
        self.cancelBlock(self);
    }
}

- (void)onClickItem:(UIButton *)btn {
    MoreItem *moreItem = self.items[btn.tag].onClicked();
    if(moreItem) {
        [[self.items mutableCopy] replaceObjectAtIndex:btn.tag withObject:moreItem];
        [btn removeFromSuperview];
        [self addButtonAtIndex:(int)btn.tag];
    }
    [self removeFromSuperview];
}
@end
