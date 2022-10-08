//
//  PluginBoardView.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/10/29.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCUPluginBoardView.h"
#import "WFCUPluginItemView.h"
#import "WFCUConfigManager.h"
#import "WFCUImage.h"

#define PLUGIN_AREA_HEIGHT 211

#define LeftOffset ([UIScreen mainScreen].bounds.size.width-75*4)/5.0
#define RCPlaginBoardCellSize ((CGSize){ 75, 80 })
#define HorizontalItemsCount 4
#define VerticalItemsCount 2

@interface PluginItem : NSObject
@property(nonatomic, strong)UIImage *image;
@property(nonatomic, strong)NSString *title;
@property(nonatomic, assign)NSUInteger tag;
- (instancetype)initWithTitle:(NSString *)title image:(UIImage *)image tag:(NSUInteger)tag;
@end


@implementation PluginItem
- (instancetype)initWithTitle:(NSString *)title image:(UIImage *)image tag:(NSUInteger)tag {
    self = [super init];
    if (self) {
        self.title = title;
        self.image = image;
        self.tag = tag;
    }
    return self;
}
@end



@interface WFCUPluginBoardView()
@property (nonatomic, strong)NSMutableArray *pluginItems;
@property (nonatomic, weak)id<WFCUPluginBoardViewDelegate> delegate;
@property (nonatomic, assign)BOOL hasVoip;
@property (nonatomic, assign)BOOL hasPtt;
@end

@implementation WFCUPluginBoardView
- (instancetype)initWithDelegate:(id<WFCUPluginBoardViewDelegate>)delegate withVoip:(BOOL)withWoip withPtt:(BOOL)withPtt {
    CGFloat width = [UIScreen mainScreen].bounds.size.width-16;
    self = [super initWithFrame:CGRectMake(0, 0, width, PLUGIN_AREA_HEIGHT)];
    if (self) {
        self.delegate = delegate;
        self.hasVoip = withWoip;
        self.hasPtt = withPtt;
        self.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
        
        int FACE_COUNT_ALL = (int)self.pluginItems.count;
        
        CGRect frame;
        frame.size.width = RCPlaginBoardCellSize.width;
        frame.size.height = RCPlaginBoardCellSize.height;
        __weak typeof(self)ws = self;
        for (int i = 0; i < FACE_COUNT_ALL; i++) {
            NSInteger currentRow = (NSInteger)floor((double)i / (double)HorizontalItemsCount);
            NSInteger currentColumn = i % HorizontalItemsCount;
            frame.origin.x = RCPlaginBoardCellSize.width * currentColumn + LeftOffset * (currentColumn+1);
            frame.origin.y = RCPlaginBoardCellSize.height * currentRow + 15 + currentRow * 18;
            
            PluginItem *pluginItem = self.pluginItems[i];
            
            
            WFCUPluginItemView *item = [[WFCUPluginItemView alloc] initWithTitle:pluginItem.title image:pluginItem.image frame:frame];
            item.tag = pluginItem.tag;
            NSUInteger tag = item.tag;
            item.onItemClicked = ^(void) {
                NSLog(@"on item %lu pressed", tag);
                [ws.delegate onItemClicked:tag];
            };
            [self addSubview:item];
        }
    }
    
    return self;
}

- (NSMutableArray *)pluginItems {
    if (!_pluginItems) {
        _pluginItems = [@[
                          [[PluginItem alloc] initWithTitle:WFCString(@"Album") image:[WFCUImage imageNamed:@"chat_input_plugin_album"] tag:1],
                          [[PluginItem alloc] initWithTitle:WFCString(@"TakePhoto") image:[WFCUImage imageNamed:@"chat_input_plugin_camera"] tag:2],
                          [[PluginItem alloc] initWithTitle:WFCString(@"Location") image:[WFCUImage imageNamed:@"chat_input_plugin_location"] tag:3],
                          [[PluginItem alloc] initWithTitle:WFCString(@"Files") image:[WFCUImage imageNamed:@"chat_input_plugin_file"] tag:5],
                          [[PluginItem alloc] initWithTitle:WFCString(@"Card") image:[WFCUImage imageNamed:@"chat_input_plugin_card"] tag:6]
                          ] mutableCopy];

#if WFCU_SUPPORT_VOIP
        if (self.hasVoip) {
            [_pluginItems insertObject:[[PluginItem alloc] initWithTitle:WFCString(@"VideoCall") image:[WFCUImage imageNamed:@"chat_input_plugin_video_call"] tag:4] atIndex:2];
        }
#endif
#ifdef WFC_PTT
        if(self.hasPtt) {
            [_pluginItems addObject:[[PluginItem alloc] initWithTitle:WFCString(@"Talk") image:[WFCUImage imageNamed:@"chat_input_plugin_intercom"] tag:7]];
        }
#endif
    }
    return _pluginItems;
}
@end
