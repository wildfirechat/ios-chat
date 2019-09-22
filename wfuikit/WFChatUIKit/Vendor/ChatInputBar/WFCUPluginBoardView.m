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
@end

@implementation WFCUPluginBoardView
- (instancetype)initWithDelegate:(id<WFCUPluginBoardViewDelegate>)delegate withVoip:(BOOL)withWoip {
    CGFloat width = [UIScreen mainScreen].bounds.size.width-16;
    self = [super initWithFrame:CGRectMake(0, 0, width, PLUGIN_AREA_HEIGHT)];
    if (self) {
        self.delegate = delegate;
        self.hasVoip = withWoip;
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
        if (self.hasVoip) {
            _pluginItems = [@[
                              [[PluginItem alloc] initWithTitle:WFCString(@"Album") image:[UIImage imageNamed:@"chat_input_plugin_album"] tag:1],
                              [[PluginItem alloc] initWithTitle:@"拍摄" image:[UIImage imageNamed:@"chat_input_plugin_camera"] tag:2],
                              [[PluginItem alloc] initWithTitle:@"位置" image:[UIImage imageNamed:@"chat_input_plugin_location"] tag:3],
#if WFCU_SUPPORT_VOIP
                              [[PluginItem alloc] initWithTitle:@"视频通话" image:[UIImage imageNamed:@"chat_input_plugin_video_call"] tag:4],
#endif
                              [[PluginItem alloc] initWithTitle:@"文件" image:[UIImage imageNamed:@"chat_input_plugin_file"] tag:5]
                              ] mutableCopy];
        } else {
            _pluginItems = [@[
                              [[PluginItem alloc] initWithTitle:WFCString(@"Album") image:[UIImage imageNamed:@"chat_input_plugin_album"] tag:1],
                              [[PluginItem alloc] initWithTitle:@"拍摄" image:[UIImage imageNamed:@"chat_input_plugin_camera"] tag:2],
                              [[PluginItem alloc] initWithTitle:@"位置" image:[UIImage imageNamed:@"chat_input_plugin_location"] tag:3],
                              [[PluginItem alloc] initWithTitle:@"文件" image:[UIImage imageNamed:@"chat_input_plugin_file"] tag:5]
                              ] mutableCopy];
        }
        
    }
    return _pluginItems;
}
@end
