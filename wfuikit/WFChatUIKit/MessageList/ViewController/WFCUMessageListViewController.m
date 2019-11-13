//
//  MessageListViewController.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/8/31.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCUMessageListViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "WFCUImagePreviewViewController.h"
#import "WFCUVoiceRecordView.h"

#import "WFCUImageCell.h"
#import "WFCUTextCell.h"
#import "WFCUVoiceCell.h"
#import "WFCULocationCell.h"
#import "WFCUFileCell.h"
#import "WFCUInformationCell.h"
#import "WFCUCallSummaryCell.h"
#import "WFCUStickerCell.h"
#import "WFCUVideoCell.h"
#import "WFCUBrowserViewController.h"
#import <WFChatClient/WFCChatClient.h>
#import "WFCUProfileTableViewController.h"

#import "WFCUChatInputBar.h"

#import "UIView+Toast.h"

#import "WFCUConversationSettingViewController.h"
#import "SDPhotoBrowser.h"
#import "WFCULocationViewController.h"
#import "WFCULocationPoint.h"
#import "WFCUVideoViewController.h"

#import "WFCUContactListViewController.h"
#import "WFCUBrowserViewController.h"

#import "MBProgressHUD.h"
#import "WFCUMediaMessageDownloader.h"

#import "VideoPlayerKit.h"

#import "WFCUForwardViewController.h"

#import <WFChatClient/WFCChatClient.h>
#if WFCU_SUPPORT_VOIP
#import <WFAVEngineKit/WFAVEngineKit.h>
#endif

#import "WFCUConfigManager.h"

@interface WFCUMessageListViewController () <UITextFieldDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UINavigationControllerDelegate, WFCUMessageCellDelegate, AVAudioPlayerDelegate, WFCUChatInputBarDelegate, SDPhotoBrowserDelegate, UIGestureRecognizerDelegate>
@property (nonatomic, strong)NSMutableArray<WFCUMessageModel *> *modelList;
@property (nonatomic, strong)NSMutableDictionary<NSNumber *, Class> *cellContentDict;

@property(nonatomic) AVAudioPlayer *player;
@property(nonatomic) NSTimer *playTimer;

@property(nonatomic, assign)long playingMessageId;
@property(nonatomic, assign)BOOL loadingMore;
@property(nonatomic, assign)BOOL hasMoreOld;
  
@property(nonatomic, strong)WFCCUserInfo *targetUser;
@property(nonatomic, strong)WFCCGroupInfo *targetGroup;
@property(nonatomic, strong)WFCCChannelInfo *targetChannel;
@property(nonatomic, strong)WFCCChatroomInfo *targetChatroom;

@property(nonatomic, strong)WFCUChatInputBar *chatInputBar;
@property(nonatomic, strong)VideoPlayerKit *videoPlayerViewController;
@property (strong, nonatomic) UICollectionView *collectionView;

@property (strong, nonatomic)NSArray<WFCCMessage *> *imageMsgs;

@property (strong, nonatomic)NSString *orignalDraft;

@property (nonatomic, strong)id<UIGestureRecognizerDelegate> scrollBackDelegate;

@property (nonatomic, strong)UIView *backgroundView;

@property (nonatomic, assign)BOOL showAlias;

@property (nonatomic, strong)WFCUMessageCellBase *cell4Menu;
@property (nonatomic, assign)BOOL firstAppear;

@property (nonatomic, assign)BOOL hasNewMessage;
@property (nonatomic, assign)BOOL loadingNew;

@property (nonatomic, strong)UICollectionReusableView *headerView;
@property (nonatomic, strong)UICollectionReusableView *footerView;
@property (nonatomic, strong)UIActivityIndicatorView *headerActivityView;
@property (nonatomic, strong)UIActivityIndicatorView *footerActivityView;

@property (nonatomic, strong)NSTimer *showTypingTimer;
@end

@implementation WFCUMessageListViewController

- (void)viewDidLoad {
    [super viewDidLoad];

  self.cellContentDict = [[NSMutableDictionary alloc] init];

  [self initializedSubViews];
    self.firstAppear = YES;
    self.hasMoreOld = YES;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onResetKeyboard:)];
    [self.collectionView addGestureRecognizer:tap];
    
    [self reloadMessageList];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onReceiveMessages:) name:kReceiveMessages object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onRecallMessages:) name:kRecallMessages object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSendingMessage:) name:kSendingMessageStatusUpdated object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMessageListChanged:) name:kMessageListChanged object:self.conversation];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMenuHidden:) name:UIMenuControllerDidHideMenuNotification object:nil];
    
    __weak typeof(self) ws = self;
    
  if(self.conversation.type == Single_Type) {
      [[NSNotificationCenter defaultCenter] addObserverForName:kUserInfoUpdated object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
          if ([ws.conversation.target isEqualToString:note.object]) {
              ws.targetUser = note.userInfo[@"userInfo"];
          }
      }];
      
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"nav_chat_single"] style:UIBarButtonItemStyleDone target:self action:@selector(onRightBarBtn:)];
  } else if(self.conversation.type == Group_Type) {
      [[NSNotificationCenter defaultCenter] addObserverForName:kGroupInfoUpdated object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
          if ([ws.conversation.target isEqualToString:note.object]) {
              ws.targetGroup = note.userInfo[@"groupInfo"];
          }
      }];
      
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"nav_chat_group"] style:UIBarButtonItemStyleDone target:self action:@selector(onRightBarBtn:)];
  } else if(self.conversation.type == Channel_Type) {
      [[NSNotificationCenter defaultCenter] addObserverForName:kChannelInfoUpdated object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
          if ([ws.conversation.target isEqualToString:note.object]) {
              ws.targetChannel = note.userInfo[@"channelInfo"];
          }
      }];
      
      self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"nav_chat_channel"] style:UIBarButtonItemStyleDone target:self action:@selector(onRightBarBtn:)];
  }
    
    self.chatInputBar = [[WFCUChatInputBar alloc] initWithParentView:self.backgroundView conversation:self.conversation delegate:self];
    
    self.orignalDraft = [[WFCCIMService sharedWFCIMService] getConversationInfo:self.conversation].draft;
    
    if (self.conversation.type == Chatroom_Type) {
        __block MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:ws.view animated:YES];
        hud.label.text = WFCString(@"JoinChatroom");
        [hud showAnimated:YES];
        
        [[WFCCIMService sharedWFCIMService] joinChatroom:ws.conversation.target success:^{
            NSLog(@"join chatroom successs");
            [ws sendChatroomWelcomeMessage];
            [hud hideAnimated:YES];
            [ws loadMoreMessage:YES];
        } error:^(int error_code) {
            NSLog(@"join chatroom error");
            hud.mode = MBProgressHUDModeText;
            hud.label.text = WFCString(@"JoinChatroomFailure");
//            hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
            [hud hideAnimated:YES afterDelay:1.f];
            hud.completionBlock = ^{
                [ws.navigationController popViewControllerAnimated:YES];
            };
        }];
    }
    
    WFCCConversationInfo *info = [[WFCCIMService sharedWFCIMService] getConversationInfo:self.conversation];
    self.chatInputBar.draft = info.draft;
    
    if (self.conversation.type == Group_Type) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSArray<WFCCGroupMember *> *groupMembers = [[WFCCIMService sharedWFCIMService] getGroupMembers:self.conversation.target forceUpdate:NO];
            NSMutableArray *memberIds = [[NSMutableArray alloc] init];
            for (WFCCGroupMember *member in groupMembers) {
                [memberIds addObject:member.memberId];
            }
            [[WFCCIMService sharedWFCIMService] getUserInfos:memberIds inGroup:self.conversation.target];
        });
    }
}

- (void)setLoadingMore:(BOOL)loadingMore {
    _loadingMore = loadingMore;
    if (_loadingMore) {
        [self.headerActivityView startAnimating];
    } else {
        [self.headerActivityView stopAnimating];
    }
}

- (UIActivityIndicatorView *)headerActivityView {
    if (!_headerActivityView) {
        _headerActivityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    }
    return _headerActivityView;
}

- (UIActivityIndicatorView *)footerActivityView {
    if (!_footerActivityView) {
        _footerActivityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    }
    return _footerActivityView;
}

- (void)setLoadingNew:(BOOL)loadingNew {
    _loadingNew = loadingNew;
    if (loadingNew) {
        [self.footerActivityView startAnimating];
    } else {
        [self.footerActivityView stopAnimating];
    }
}

- (void)setHasNewMessage:(BOOL)hasNewMessage {
    _hasNewMessage = hasNewMessage;
    UICollectionViewFlowLayout *_customFlowLayout = (UICollectionViewFlowLayout*)self.collectionView.collectionViewLayout;
    if (hasNewMessage) {
        _customFlowLayout.footerReferenceSize = CGSizeMake(320.0f, 20.0f);
    } else {
        _customFlowLayout.footerReferenceSize = CGSizeZero;
    }
}

- (void)loadMoreMessage:(BOOL)isHistory {
    __weak typeof(self) weakSelf = self;
    if (isHistory) {
        if (self.loadingMore) {
            return;
        }
        self.loadingMore = YES;
        long lastIndex = 0;
        long long lastUid = 0;
        if (weakSelf.modelList.count) {
            lastIndex = [weakSelf.modelList firstObject].message.messageId;
            lastUid = [weakSelf.modelList firstObject].message.messageUid;
        }
        
        dispatch_async(dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT), ^{
            NSArray *messageList = [[WFCCIMService sharedWFCIMService] getMessages:weakSelf.conversation contentTypes:nil from:lastIndex count:10 withUser:self.privateChatUser];
            if (!messageList.count) {
                [[WFCCIMService sharedWFCIMService] getRemoteMessages:weakSelf.conversation before:lastUid count:10 success:^(NSArray<WFCCMessage *> *messages) {
                    NSMutableArray *reversedMsgs = [[NSMutableArray alloc] init];
                    for (WFCCMessage *msg in messages) {
                        [reversedMsgs insertObject:msg atIndex:0];
                    }
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (!reversedMsgs.count) {
                            weakSelf.hasMoreOld = NO;
                        } else {
                            [weakSelf appendMessages:reversedMsgs newMessage:NO highlightId:0];
                        }
                        weakSelf.loadingMore = NO;
                    });
                } error:^(int error_code) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        weakSelf.hasMoreOld = NO;
                        weakSelf.loadingMore = NO;
                    });
                }];
            } else {
                [NSThread sleepForTimeInterval:0.5];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf appendMessages:messageList newMessage:NO highlightId:0];
                    weakSelf.loadingMore = NO;
                });
            }
        });
    } else {
            if (weakSelf.loadingNew || !weakSelf.hasNewMessage) {
                return;
            }
            weakSelf.loadingNew = YES;
        
            long lastIndex = 0;
            if (self.modelList.count) {
                lastIndex = [self.modelList lastObject].message.messageId;
            }
        
        dispatch_async(dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT), ^{
            NSArray *messageList = [[WFCCIMService sharedWFCIMService] getMessages:self.conversation contentTypes:nil from:lastIndex count:-10 withUser:self.privateChatUser];
            if (!messageList.count || messageList.count < 10) {
                self.hasNewMessage = NO;
            }
            NSMutableArray *mutableMessages = [messageList mutableCopy];
            for (int i = 0; i < mutableMessages.count/2; i++) {
                int j = (int)mutableMessages.count - 1 - i;
                WFCCMessage *msg = [mutableMessages objectAtIndex:i];
                [mutableMessages insertObject:[mutableMessages objectAtIndex:j] atIndex:i];
                [mutableMessages removeObjectAtIndex:i+1];
                [mutableMessages insertObject:msg atIndex:j];
                [mutableMessages removeObjectAtIndex:j+1];
            }
            [NSThread sleepForTimeInterval:3];
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf appendMessages:mutableMessages newMessage:YES highlightId:0];
                weakSelf.loadingNew = NO;
            });
        });
        
        
    }
}
- (void)sendChatroomWelcomeMessage {
    WFCCTipNotificationContent *tip = [[WFCCTipNotificationContent alloc] init];
    WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:[WFCCNetworkService sharedInstance].userId refresh:NO];
    tip.tip = [NSString stringWithFormat:WFCString(@"WelcomeJoinChatroomHint"), userInfo.displayName];
    [self sendMessage:tip];
}

- (void)sendChatroomLeaveMessage {
    __block WFCCConversation *strongConv = self.conversation;
    dispatch_async(dispatch_get_main_queue(), ^{
        WFCCTipNotificationContent *tip = [[WFCCTipNotificationContent alloc] init];
        WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:[WFCCNetworkService sharedInstance].userId refresh:NO];
        tip.tip = [NSString stringWithFormat:WFCString(@"LeaveChatroomHint"), userInfo.displayName];
        
        [[WFCCIMService sharedWFCIMService] send:strongConv content:tip success:^(long long messageUid, long long timestamp) {
            [[WFCCIMService sharedWFCIMService] quitChatroom:strongConv.target success:nil error:nil];
        } error:^(int error_code) {
            
        }];
    });
}

- (void)onLeftBtnPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)didMoveToParentViewController:(UIViewController*)parent
{
    [super didMoveToParentViewController:parent];
    if(!parent){
        [self leftMessageVC];
    }
}

- (void)leftMessageVC {
    if (self.conversation.type == Chatroom_Type) {
        [self sendChatroomLeaveMessage];
    }
}

- (void)onRightBarBtn:(UIBarButtonItem *)sender {
    WFCUConversationSettingViewController *gvc = [[WFCUConversationSettingViewController alloc] init];
    gvc.conversation = self.conversation;
    [self.navigationController pushViewController:gvc animated:YES];
}

- (void)setTargetUser:(WFCCUserInfo *)targetUser {
  _targetUser = targetUser;
    if(targetUser.friendAlias.length) {
        self.title = targetUser.friendAlias;
    } else if(targetUser.displayName.length == 0) {
        self.title = [NSString stringWithFormat:@"%@<%@>", WFCString(@"User"), self.conversation.target];
    } else {
        self.title = targetUser.displayName;
    }
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] init];
    self.navigationItem.backBarButtonItem.title = self.title;
}
  
- (void)setTargetGroup:(WFCCGroupInfo *)targetGroup {
  _targetGroup = targetGroup;
    if(targetGroup.name.length == 0) {
        self.title = WFCString(@"GroupChat");
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] init];
        self.navigationItem.backBarButtonItem.title = WFCString(@"Message");
    } else {
        self.title = [NSString stringWithFormat:@"%@(%d)", targetGroup.name, (int)targetGroup.memberCount];
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] init];
        self.navigationItem.backBarButtonItem.title = targetGroup.name;
  }
    ChatInputBarStatus defaultStatus = ChatInputBarDefaultStatus;
    if (targetGroup.mute) {
        if ([targetGroup.owner isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
            self.chatInputBar.inputBarStatus =  defaultStatus;
        } else {
            WFCCGroupMember *gm = [[WFCCIMService sharedWFCIMService] getGroupMember:targetGroup.target memberId:[WFCCNetworkService sharedInstance].userId];
            if (gm.type == Member_Type_Manager) {
                self.chatInputBar.inputBarStatus =  defaultStatus;
            } else {
                self.chatInputBar.inputBarStatus = ChatInputBarMuteStatus;
            }
        }
    } else {
        self.chatInputBar.inputBarStatus =  defaultStatus;
    }
}

- (void)setTargetChannel:(WFCCChannelInfo *)targetChannel {
    _targetChannel = targetChannel;
    if(targetChannel.name.length == 0) {
        self.title = WFCString(@"Channel");
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] init];
        self.navigationItem.backBarButtonItem.title = WFCString(@"Message");
    } else {
        self.title = targetChannel.name;
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] init];
        self.navigationItem.backBarButtonItem.title = targetChannel.name;
    }
}

- (void)setTargetChatroom:(WFCCChatroomInfo *)targetChatroom {
    _targetChatroom = targetChatroom;
    if(targetChatroom.title.length == 0) {
        self.title = WFCString(@"Chatroom");
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] init];
        self.navigationItem.backBarButtonItem.title = WFCString(@"Message");
    } else {
        self.title = targetChatroom.title;
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] init];
        self.navigationItem.backBarButtonItem.title = targetChatroom.title;
    }
}

- (void)setShowAlias:(BOOL)showAlias {
    _showAlias = showAlias;
    if (self.modelList) {
        for (WFCUMessageModel *model in self.modelList) {
            if (showAlias && model.message.direction == MessageDirection_Receive) {
                model.showNameLabel = YES;
            } else {
                model.showNameLabel = NO;
            }
        }
    }
}

- (void)scrollToBottom:(BOOL)animated {

    NSUInteger rowCount = [self.collectionView numberOfItemsInSection:0];
    if (rowCount == 0) {
        return;
    }
    NSUInteger finalRow = rowCount - 1;
    
    for (int i = 0; i < self.modelList.count; i++) {
        if ([self.modelList objectAtIndex:i].highlighted) {
            finalRow = i;
            break;
        }
    }
    
    NSIndexPath *finalIndexPath = [NSIndexPath indexPathForItem:finalRow inSection:0];
    [self.collectionView scrollToItemAtIndexPath:finalIndexPath
                                atScrollPosition:UICollectionViewScrollPositionBottom
                                        animated:animated];

}

- (void)initializedSubViews {
    UICollectionViewFlowLayout *_customFlowLayout = [[UICollectionViewFlowLayout alloc] init];
    _customFlowLayout.minimumLineSpacing = 0.0f;
    _customFlowLayout.sectionInset = UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f);
    _customFlowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    _customFlowLayout.headerReferenceSize = CGSizeMake(320.0f, 20.0f);
  
    UIEdgeInsets insets = UIEdgeInsetsZero;
    if (@available(iOS 11.0, *)) {
        insets = self.view.safeAreaInsets;
    }
    CGRect frame = self.view.bounds;
    frame.origin.y += kStatusBarAndNavigationBarHeight;
    frame.size.height -= (kTabbarSafeBottomMargin + kStatusBarAndNavigationBarHeight);
    self.backgroundView = [[UIView alloc] initWithFrame:frame];
    [self.view addSubview:self.backgroundView];
    
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, self.backgroundView.bounds.size.width, self.backgroundView.bounds.size.height - CHAT_INPUT_BAR_HEIGHT) collectionViewLayout:_customFlowLayout];

    [self.backgroundView addSubview:self.collectionView];
    
    self.backgroundView.backgroundColor = [UIColor whiteColor];
    self.collectionView.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
    self.collectionView.showsHorizontalScrollIndicator = NO;
    self.collectionView.showsVerticalScrollIndicator = NO;
    self.collectionView.alwaysBounceVertical = YES;
    
    
    self.view.backgroundColor = self.collectionView.backgroundColor;
    
    [self registerCell:[WFCUTextCell class] forContent:[WFCCTextMessageContent class]];
    [self registerCell:[WFCUTextCell class] forContent:[WFCCPTextMessageContent class]];
    [self registerCell:[WFCUImageCell class] forContent:[WFCCImageMessageContent class]];
    [self registerCell:[WFCUVoiceCell class] forContent:[WFCCSoundMessageContent class]];
    [self registerCell:[WFCUVideoCell class] forContent:[WFCCVideoMessageContent class]];
    [self registerCell:[WFCULocationCell class] forContent:[WFCCLocationMessageContent class]];
    [self registerCell:[WFCUFileCell class] forContent:[WFCCFileMessageContent class]];
    [self registerCell:[WFCUStickerCell class] forContent:[WFCCStickerMessageContent class]];
    
    [self registerCell:[WFCUInformationCell class] forContent:[WFCCCreateGroupNotificationContent class]];
    [self registerCell:[WFCUInformationCell class] forContent:[WFCCAddGroupeMemberNotificationContent class]];
    [self registerCell:[WFCUInformationCell class] forContent:[WFCCKickoffGroupMemberNotificaionContent class]];
    [self registerCell:[WFCUInformationCell class] forContent:[WFCCQuitGroupNotificationContent class]];
    [self registerCell:[WFCUInformationCell class] forContent:[WFCCDismissGroupNotificationContent class]];
    [self registerCell:[WFCUInformationCell class] forContent:[WFCCTransferGroupOwnerNotificationContent class]];
    [self registerCell:[WFCUInformationCell class] forContent:[WFCCModifyGroupAliasNotificationContent class]];
    [self registerCell:[WFCUInformationCell class] forContent:[WFCCChangeGroupNameNotificationContent class]];
    [self registerCell:[WFCUInformationCell class] forContent:[WFCCChangeGroupPortraitNotificationContent class]];
    [self registerCell:[WFCUCallSummaryCell class] forContent:[WFCCCallStartMessageContent class]];
    [self registerCell:[WFCUInformationCell class] forContent:[WFCCTipNotificationContent class]];
    [self registerCell:[WFCUInformationCell class] forContent:[WFCCUnknownMessageContent class]];
    [self registerCell:[WFCUInformationCell class] forContent:[WFCCRecallMessageContent class]];
    
    
    [self.collectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderView"];
    [self.collectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"FooterView"];
    
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
}

- (void)registerCell:(Class)cellCls forContent:(Class)msgContentCls {
    [self.collectionView registerClass:cellCls
            forCellWithReuseIdentifier:[NSString stringWithFormat:@"%d", [msgContentCls getContentType]]];
    [self.cellContentDict setObject:cellCls forKey:@([msgContentCls getContentType])];
}

- (void)showTyping:(WFCCTypingType)typingType {
    if (self.showTypingTimer) {
        [self.showTypingTimer invalidate];
    }
    
    self.showTypingTimer = [NSTimer timerWithTimeInterval:TYPING_INTERVAL/2 target:self selector:@selector(stopShowTyping) userInfo:nil repeats:NO];
    
    [[NSRunLoop mainRunLoop] addTimer:self.showTypingTimer forMode:NSDefaultRunLoopMode];
    if (typingType == Typing_TEXT) {
        self.title = WFCString(@"TypingHint");
    } else if(typingType == Typing_VOICE) {
        self.title = WFCString(@"RecordingHint");
    } else if(typingType == Typing_CAMERA) {
        self.title = WFCString(@"PhotographingHint");
    } else if(typingType == Typing_LOCATION) {
        self.title = WFCString(@"GetLocationHint");
    } else if(typingType == Typing_FILE) {
        self.title = WFCString(@"SelectingFileHint");
    }
    
}

- (void)stopShowTyping {
    if(self.showTypingTimer != nil) {
        [self.showTypingTimer invalidate];
        self.showTypingTimer = nil;
        if (self.conversation.type == Single_Type) {
            self.targetUser = self.targetUser;
        } else if(self.conversation.type == Group_Type) {
            self.targetGroup = self.targetGroup;
        } else if(self.conversation.type == Channel_Type) {
            self.targetChannel = self.targetChannel;
        } else if(self.conversation.type == Group_Type) {
            self.targetGroup = self.targetGroup;
        }
    }
}

- (void)onResetKeyboard:(id)sender {
  [self.chatInputBar resetInputBarStatue];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
    [self.chatInputBar willAppear];
    if(self.conversation.type == Single_Type) {
        WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:self.conversation.target refresh:YES];
        self.targetUser = userInfo;
    } else if(self.conversation.type == Group_Type) {
        WFCCGroupInfo *groupInfo = [[WFCCIMService sharedWFCIMService] getGroupInfo:self.conversation.target refresh:YES];
        self.targetGroup = groupInfo;
    } else if (self.conversation.type == Channel_Type) {
        WFCCChannelInfo *channelInfo = [[WFCCIMService sharedWFCIMService] getChannelInfo:self.conversation.target refresh:YES];
        self.targetChannel = channelInfo;
    } else if(self.conversation.type == Chatroom_Type) {
        __weak typeof(self)ws = self;
        [[WFCCIMService sharedWFCIMService] getChatroomInfo:self.conversation.target upateDt:ws.targetChatroom.updateDt success:^(WFCCChatroomInfo *chatroomInfo) {
            ws.targetChatroom = chatroomInfo;
        } error:^(int error_code) {
            
        }];
    }
    
  self.tabBarController.tabBar.hidden = YES;
    [self.collectionView reloadData];
    
    if (self.navigationController.viewControllers.count > 1) {          // 记录系统返回手势的代理
        _scrollBackDelegate = self.navigationController.interactivePopGestureRecognizer.delegate;          // 设置系统返回手势的代理为当前控制器
        self.navigationController.interactivePopGestureRecognizer.delegate = self;
    }
    
    if (self.conversation.type == Group_Type) {
        self.showAlias = ![[WFCCIMService sharedWFCIMService] isHiddenGroupMemberName:self.targetGroup.target];
    }
    
    if (self.firstAppear) {
        self.firstAppear = NO;
        [self scrollToBottom:NO];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
    NSString *newDraft = self.chatInputBar.draft;
    if (![self.orignalDraft isEqualToString:newDraft]) {
        self.orignalDraft = newDraft;
        [[WFCCIMService sharedWFCIMService] setConversation:self.conversation draft:newDraft];
    }
    // 设置系统返回手势的代理为我们刚进入控制器的时候记录的系统的返回手势代理
    self.navigationController.interactivePopGestureRecognizer.delegate = _scrollBackDelegate;
    
    [self.chatInputBar resetInputBarStatue];
}


- (void)sendMessage:(WFCCMessageContent *)content {
    //发送消息时，client会发出"kSendingMessageStatusUpdated“的通知，消息界面收到通知后加入到列表中。
    __weak typeof(self) ws = self;
    NSMutableArray *tousers = nil;
    if (self.privateChatUser) {
        tousers = [[NSMutableArray alloc] init];
        [tousers addObject:self.privateChatUser];
    }
    [[WFCCIMService sharedWFCIMService] send:self.conversation content:content toUsers:tousers expireDuration:0 success:^(long long messageUid, long long timestamp) {
        NSLog(@"send message success");
        if ([content isKindOfClass:[WFCCStickerMessageContent class]]) {
            [ws saveStickerRemoteUrl:(WFCCStickerMessageContent *)content];
        }
    } error:^(int error_code) {
        NSLog(@"send message fail(%d)", error_code);
    }];
}

- (void)onReceiveMessages:(NSNotification *)notification {
    NSArray<WFCCMessage *> *messages = notification.object;
    [self appendMessages:messages newMessage:YES highlightId:0];
    [[WFCCIMService sharedWFCIMService] clearUnreadStatus:self.conversation];
}

- (void)onRecallMessages:(NSNotification *)notification {
    long long messageUid = [notification.object longLongValue];
    WFCCMessage *msg = [[WFCCIMService sharedWFCIMService] getMessageByUid:messageUid];
    if (msg != nil) {
        for (int i = 0; i < self.modelList.count; i++) {
            WFCUMessageModel *model = [self.modelList objectAtIndex:i];
            if (model.message.messageUid == messageUid) {
                model.message = msg;
                [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]]];
                break;
            }
        }
    }
}

- (void)onSendingMessage:(NSNotification *)notification {
    WFCCMessage *message = [notification.userInfo objectForKey:@"message"];
    WFCCMessageStatus status = [[notification.userInfo objectForKey:@"status"] integerValue];
    if (status == Message_Status_Sending) {
        if ([message.conversation isEqual:self.conversation]) {
            [self appendMessages:@[message] newMessage:YES highlightId:0];
        }
    }
    
}

- (void)onMessageListChanged:(NSNotification *)notification {
    [self reloadMessageList];
}

- (void)reloadMessageList {
    NSArray *messageList;
    if (self.highlightMessageId > 0) {
        NSArray *messageListOld = [[WFCCIMService sharedWFCIMService] getMessages:self.conversation contentTypes:nil from:self.highlightMessageId+1 count:15 withUser:self.privateChatUser];
        NSArray *messageListNew = [[WFCCIMService sharedWFCIMService] getMessages:self.conversation contentTypes:nil from:self.highlightMessageId count:-15 withUser:self.privateChatUser];
        NSMutableArray *list = [[NSMutableArray alloc] init];
        [list addObjectsFromArray:messageListNew];
        [list addObjectsFromArray:messageListOld];
        messageList = [list copy];
        [[WFCCIMService sharedWFCIMService] clearUnreadStatus:self.conversation];
        if (messageListNew.count == 15) {
            self.hasNewMessage = YES;
        }
    } else {
        messageList = [[WFCCIMService sharedWFCIMService] getMessages:self.conversation contentTypes:nil from:0 count:15 withUser:self.privateChatUser];
        [[WFCCIMService sharedWFCIMService] clearUnreadStatus:self.conversation];
    }
    
    self.modelList = [[NSMutableArray alloc] init];
    
    [self appendMessages:messageList newMessage:NO highlightId:self.highlightMessageId];
    self.highlightMessageId = 0;
}

- (void)appendMessages:(NSArray<WFCCMessage *> *)messages newMessage:(BOOL)newMessage highlightId:(long)highlightId {
    if (messages.count == 0) {
        return;
    }
  
    int count = 0;
    for (int i = 0; i < messages.count; i++) {
        WFCCMessage *message = [messages objectAtIndex:i];
        
        if (![message.conversation isEqual:self.conversation]) {
            continue;
        }
        
        if ([message.content isKindOfClass:[WFCCTypingMessageContent class]] && message.direction == MessageDirection_Receive) {
            double now = [[NSDate date] timeIntervalSince1970];
            if (now - message.serverTime + [WFCCNetworkService sharedInstance].serverDeltaTime < TYPING_INTERVAL) {
                WFCCTypingMessageContent *content = (WFCCTypingMessageContent *)message.content;
                [self showTyping:content.type];
            }
            continue;
        }
        
        if (!([message.content.class getContentFlags] & 0x1)) {
            continue;
        }
        BOOL duplcated = NO;
        for (WFCUMessageModel *model in self.modelList) {
            if (model.message.messageUid !=0 && model.message.messageUid == message.messageUid) {
                duplcated = YES;
                break;
            }
        }
        if (duplcated) {
            continue;
        }
        
        count++;
        
        if (newMessage) {
            BOOL showTime = YES;
            if (self.modelList.count > 0 && (message.serverTime -  (self.modelList[self.modelList.count - 1]).message.serverTime < 60 * 1000)) {
                showTime = NO;
            }
            WFCUMessageModel *model = [WFCUMessageModel modelOf:message showName:message.direction == MessageDirection_Receive && self.showAlias showTime:showTime];
            if (highlightId > 0 && message.messageId == highlightId) {
                model.highlighted = YES;
            }
            [self.modelList addObject:model];
        } else {
            if (self.modelList.count > 0 && (self.modelList[0].message.serverTime - message.serverTime < 60 * 1000) && i != 0) {
                self.modelList[0].showTimeLabel = NO;
            }
            WFCUMessageModel *model = [WFCUMessageModel modelOf:message showName:message.direction == MessageDirection_Receive&&self.showAlias showTime:YES];
            if (highlightId > 0 && message.messageId == highlightId) {
                model.highlighted = YES;
            }
            [self.modelList insertObject:model atIndex:0];
        }
    }
    
    if (count > 0) {
        [self stopShowTyping];
    }
    
    BOOL isAtButtom = NO;
    if (newMessage) {
        if (@available(iOS 12.0, *)) {
            CGPoint offset = self.collectionView.contentOffset;
            CGSize size = self.collectionView.contentSize;
            CGSize visiableSize = CGSizeZero;
            visiableSize = self.collectionView.visibleSize;
            isAtButtom = (offset.y + visiableSize.height - size.height) > -100;
        } else {
            isAtButtom = YES;
        }
    }
    
  [self.collectionView reloadData];
    if (newMessage || self.modelList.count == messages.count) {
        if(isAtButtom) {
            [self scrollToBottom:YES];
        }
    } else {
        CGFloat offset = 0;
        for (int i = 0; i < count; i++) {
            CGSize size = [self collectionView:self.collectionView layout:self.collectionView.collectionViewLayout sizeForItemAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
            offset += size.height;
        }
        self.collectionView.contentOffset = CGPointMake(0, offset);
        
        [UIView animateWithDuration:0.2 animations:^{
            self.collectionView.contentOffset = CGPointMake(0, offset - 20);
        }];
    }
}

- (WFCUMessageModel *)modelOfMessage:(long)messageId {
    if (messageId <= 0) {
        return nil;
    }
    for (WFCUMessageModel *model in self.modelList) {
        if (model.message.messageId == messageId) {
            return model;
        }
    }
    return nil;
}

- (void)stopPlayer {
    if (self.player && [self.player isPlaying]) {
        [self.player stop];
        if ([self.playTimer isValid]) {
            [self.playTimer invalidate];
            self.playTimer = nil;
        }
    }
    [self modelOfMessage:self.playingMessageId].voicePlaying = NO;
    self.playingMessageId = 0;
    [[NSNotificationCenter defaultCenter] postNotificationName:kVoiceMessagePlayStoped object:nil];
}

-(void)prepardToPlay:(WFCUMessageModel *)model {

    if (self.playingMessageId == model.message.messageId) {
        [self stopPlayer];
    } else {
        [self stopPlayer];
        
        self.playingMessageId = model.message.messageId;
        
        WFCCSoundMessageContent *soundContent = (WFCCSoundMessageContent *)model.message.content;
        if (soundContent.localPath.length == 0) {
            model.mediaDownloading = YES;
            __weak typeof(self) weakSelf = self;
            
            [[WFCUMediaMessageDownloader sharedDownloader] tryDownload:model.message success:^(long long messageUid, NSString *localPath) {
                model.mediaDownloading = NO;
                [weakSelf startPlay:model];
            } error:^(long long messageUid, int error_code) {
                model.mediaDownloading = NO;
            }];
            
        } else {
            [self startPlay:model];
        }
        
    }
}

-(void)startPlay:(WFCUMessageModel *)model {
    
    if ([model.message.content isKindOfClass:[WFCCSoundMessageContent class]]) {
        // Setup audio session
        AVAudioSession *session = [AVAudioSession sharedInstance];
        [session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        
        
        [session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker
                                   error:nil];
        
        
        WFCCSoundMessageContent *snc = (WFCCSoundMessageContent *)model.message.content;
        NSError *error = nil;
        self.player = [[AVAudioPlayer alloc] initWithData:[snc getWavData] error:&error];
        [self.player setDelegate:self];
        [self.player prepareToPlay];
        [self.player play];
        model.voicePlaying = YES;
        [[NSNotificationCenter defaultCenter] postNotificationName:kVoiceMessageStartPlaying object:@(self.playingMessageId)];
    } else if([model.message.content isKindOfClass:[WFCCVideoMessageContent class]]) {
        WFCCVideoMessageContent *videoMsg = (WFCCVideoMessageContent *)model.message.content;
        NSURL *url = [NSURL fileURLWithPath:[videoMsg.localPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        
        if (!self.videoPlayerViewController) {
            self.videoPlayerViewController = [VideoPlayerKit videoPlayerWithContainingView:self.view optionalTopView:nil hideTopViewWithControls:YES];
//            self.videoPlayerViewController.delegate = self;
            self.videoPlayerViewController.allowPortraitFullscreen = YES;
        } else {
            [self.videoPlayerViewController.view removeFromSuperview];
        }
        
        [self.view addSubview:self.videoPlayerViewController.view];
        
        [self.videoPlayerViewController playVideoWithTitle:@" " URL:url videoID:nil shareURL:nil isStreaming:NO playInFullScreen:YES];
    }
    
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
  return self.modelList.count;
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  WFCUMessageModel *model = self.modelList[indexPath.row];
  NSString *objName = [NSString stringWithFormat:@"%d", [model.message.content.class getContentType]];
  
  WFCUMessageCellBase *cell = nil;
  if(![self.cellContentDict objectForKey:@([model.message.content.class getContentType])]) {
    cell = [collectionView dequeueReusableCellWithReuseIdentifier:[NSString stringWithFormat:@"%d", [WFCCUnknownMessageContent getContentType]] forIndexPath:indexPath];
  } else {
    cell = [collectionView dequeueReusableCellWithReuseIdentifier:objName forIndexPath:indexPath];
  }
  
  cell.delegate = self;
    
  [[NSNotificationCenter defaultCenter] removeObserver:cell];
  cell.model = model;
  
  return cell;
}

- (UICollectionReusableView *) collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        if(!self.headerView) {
            self.headerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"HeaderView" forIndexPath:indexPath];
            self.headerActivityView.center = CGPointMake(self.headerView.bounds.size.width/2, self.headerView.bounds.size.height/2);
            [self.headerView addSubview:self.headerActivityView];
        }
        return self.headerView;
    } else {
        if(!self.footerView) {
            self.footerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"FooterView" forIndexPath:indexPath];
            self.footerActivityView.center = CGPointMake(self.footerView.bounds.size.width/2, self.footerView.bounds.size.height/2);
            [self.footerView addSubview:self.footerActivityView];
        }
        return self.footerView;
    }
    return nil;
}

#pragma mark - UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
  
  WFCUMessageModel *model = self.modelList[indexPath.row];
    Class cellCls = self.cellContentDict[@([[model.message.content class] getContentType])];
  if (!cellCls) {
    cellCls = self.cellContentDict[@([[WFCCUnknownMessageContent class] getContentType])];
  }
  return [cellCls sizeForCell:model withViewWidth:self.collectionView.frame.size.width];
}

#pragma mark - MessageCellDelegate
- (void)didTapMessageCell:(WFCUMessageCellBase *)cell withModel:(WFCUMessageModel *)model {
    if ([model.message.content isKindOfClass:[WFCCImageMessageContent class]]) {
        if (self.conversation.type == Chatroom_Type) {
            NSMutableArray *imageMsgs = [[NSMutableArray alloc] init];
            for (WFCUMessageModel *msgModle in self.modelList) {
                if ([msgModle.message.content isKindOfClass:[WFCCImageMessageContent class]]) {
                    [imageMsgs addObject:msgModle.message];
                }
            }
            self.imageMsgs = imageMsgs;
        } else {
            self.imageMsgs = [[WFCCIMService sharedWFCIMService] getMessages:self.conversation contentTypes:@[@(MESSAGE_CONTENT_TYPE_IMAGE)] from:0 count:100 withUser:self.privateChatUser];
        }
        SDPhotoBrowser *browser = [[SDPhotoBrowser alloc] init];
        browser.sourceImagesContainerView = self.backgroundView;
        
        browser.imageCount = self.imageMsgs.count;
        int i;
        for (i = 0; i < self.imageMsgs.count; i++) {
            if ([self.imageMsgs objectAtIndex:i].messageId == model.message.messageId) {
                break;
            }
        }
        if (i == self.imageMsgs.count) {
            i = 0;
        }
        [self onResetKeyboard:nil];
        browser.currentImageIndex = i;
        browser.delegate = self;
        [browser show]; // 展示图片浏览器
    } else if([model.message.content isKindOfClass:[WFCCSoundMessageContent class]]) {
        if (model.message.direction == MessageDirection_Receive && model.message.status != Message_Status_Played) {
            [[WFCCIMService sharedWFCIMService] setMediaMessagePlayed:model.message.messageId];
            model.message.status = Message_Status_Played;
            [self.collectionView reloadItemsAtIndexPaths:@[[self.collectionView indexPathForCell:cell]]];
        }
        
        [self prepardToPlay:model];
    } else if([model.message.content isKindOfClass:[WFCCLocationMessageContent class]]) {
      WFCCLocationMessageContent *locContent = (WFCCLocationMessageContent *)model.message.content;
      WFCULocationViewController *vc = [[WFCULocationViewController alloc] initWithLocationPoint:[[WFCULocationPoint alloc] initWithCoordinate:locContent.coordinate andTitle:locContent.title]];
      [self.navigationController pushViewController:vc animated:YES];
    } else if ([model.message.content isKindOfClass:[WFCCFileMessageContent class]]) {
        WFCCFileMessageContent *fileContent = (WFCCFileMessageContent *)model.message.content;
        WFCUBrowserViewController *bvc = [[WFCUBrowserViewController alloc] init];
        bvc.url = fileContent.remoteUrl;
        [self.navigationController pushViewController:bvc animated:YES];
    } else if ([model.message.content isKindOfClass:[WFCCCallStartMessageContent class]]) {
        WFCCCallStartMessageContent *callStartMsg = (WFCCCallStartMessageContent *)model.message.content;
#if WFCU_SUPPORT_VOIP
        [self didTouchVideoBtn:callStartMsg.isAudioOnly];
#endif
    } else if([model.message.content isKindOfClass:[WFCCVideoMessageContent class]]) {
        WFCCVideoMessageContent *videoMsg = (WFCCVideoMessageContent *)model.message.content;
        if (model.message.direction == MessageDirection_Receive && model.message.status != Message_Status_Played) {
            [[WFCCIMService sharedWFCIMService] setMediaMessagePlayed:model.message.messageId];
            model.message.status = Message_Status_Played;
            [self.collectionView reloadItemsAtIndexPaths:@[[self.collectionView indexPathForCell:cell]]];
        }
        
        if (videoMsg.localPath.length == 0) {
            model.mediaDownloading = YES;
            __weak typeof(self) weakSelf = self;
            
            [[WFCUMediaMessageDownloader sharedDownloader] tryDownload:model.message success:^(long long messageUid, NSString *localPath) {
                model.mediaDownloading = NO;
                [weakSelf startPlay:model];
            } error:^(long long messageUid, int error_code) {
                model.mediaDownloading = NO;
            }];
        } else {
            [self startPlay:model];
        }
    }
}

- (void)didTapMessagePortrait:(WFCUMessageCellBase *)cell withModel:(WFCUMessageModel *)model {
    if(self.conversation.type == Group_Type) {
        if (self.targetGroup.privateChat) {
            if (![self.targetGroup.owner isEqualToString:model.message.fromUser] && ![self.targetGroup.owner isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
                WFCCGroupMember *gm = [[WFCCIMService sharedWFCIMService] getGroupMember:self.conversation.target memberId:[WFCCNetworkService sharedInstance].userId];
                if (gm.type != Member_Type_Manager) {
                    WFCCGroupMember *gm = [[WFCCIMService sharedWFCIMService] getGroupMember:self.conversation.target memberId:model.message.fromUser];
                    if (gm.type != Member_Type_Manager) {
                        [self.view makeToast:WFCString(@"NotAllowTemporarySession") duration:1 position:CSToastPositionCenter];
                        return;
                    }
                }
            }
        }
    }
  WFCUProfileTableViewController *vc = [[WFCUProfileTableViewController alloc] init];
  vc.userId = model.message.fromUser;
  vc.hidesBottomBarWhenPushed = YES;
  [self.navigationController pushViewController:vc animated:YES];
}

- (void)didLongPressMessageCell:(WFCUMessageCellBase *)cell withModel:(WFCUMessageModel *)model {
    if ([cell isKindOfClass:[WFCUMessageCellBase class]]) {
//        if (!self.isFirstResponder) {
//            [self becomeFirstResponder];
//        }

        [self displayMenu:(WFCUMessageCellBase *)cell];
    }
}

- (void)didLongPressMessagePortrait:(WFCUMessageCellBase *)cell withModel:(WFCUMessageModel *)model {
    if (self.conversation.type == Group_Type) {
        if (model.message.direction == MessageDirection_Receive) {
            WFCCUserInfo *sender = [[WFCCIMService sharedWFCIMService] getUserInfo:model.message.fromUser refresh:NO];
            [self.chatInputBar appendMention:model.message.fromUser name:sender.displayName];
        }
    } else if(self.conversation.type == Channel_Type) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:WFCString(@"Cancel") style:UIAlertActionStyleCancel handler:nil];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:WFCString(@"ChatWithSubscriber") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            if (model.message.direction == MessageDirection_Receive) {
                WFCCChannelInfo *channelInfo = [[WFCCIMService sharedWFCIMService] getChannelInfo:self.conversation.target refresh:NO];
                if ([channelInfo.owner isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
                    WFCUMessageListViewController *mvc = [[WFCUMessageListViewController alloc] init];
                    mvc.conversation = [WFCCConversation conversationWithType:self.conversation.type target:self.conversation.target line:self.conversation.line];
                    mvc.privateChatUser = model.message.fromUser;
                    [self.navigationController pushViewController:mvc animated:YES];
                }
            }

        }];
        [alertController addAction:cancelAction];
        [alertController addAction:okAction];
        [self presentViewController:alertController animated:YES completion:nil];
    }
}
- (void)didTapResendBtn:(WFCUMessageModel *)model {
    NSInteger index = [self.modelList indexOfObject:model];
    if (index >= 0) {
        NSIndexPath *path = [NSIndexPath indexPathForRow:index inSection:0];
        [self.modelList removeObjectAtIndex:index];
        [self.collectionView deleteItemsAtIndexPaths:@[path]];
        [[WFCCIMService sharedWFCIMService] deleteMessage:model.message.messageId];
        [self sendMessage:model.message.content];
    }
}

- (void)didSelectUrl:(WFCUMessageCellBase *)cell withModel:(WFCUMessageModel *)model withUrl:(NSString *)urlString {
    WFCUBrowserViewController *bvc = [[WFCUBrowserViewController alloc] init];
    bvc.url = urlString;
    [self.navigationController pushViewController:bvc animated:YES];
}

- (void)didSelectPhoneNumber:(WFCUMessageCellBase *)cell withModel:(WFCUMessageModel *)model withPhoneNumber:(NSString *)phoneNumber {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:WFCString(@"PhoneNumberHint"), phoneNumber] message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:WFCString(@"Cancel") style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *callAction = [UIAlertAction actionWithTitle:WFCString(@"Call") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSURL *url = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"telprompt:%@", phoneNumber]];
        [[UIApplication sharedApplication] openURL:url];
    }];
    
    UIAlertAction *copyAction = [UIAlertAction actionWithTitle:WFCString(@"CopyNumber") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = phoneNumber;
    }];
    
    [alertController addAction:cancelAction];
    [alertController addAction:callAction];
    [alertController addAction:copyAction];
//    [alertController addAction:addContactAction];
    [self presentViewController:alertController animated:YES completion:nil];
}
#pragma mark - AVAudioPlayerDelegate
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    NSLog(@"player finished");
    [self stopPlayer];
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error {
    NSLog(@"player decode error");
    [[[UIAlertView alloc] initWithTitle:WFCString(@"Warning") message:WFCString(@"NetworkError") delegate:nil cancelButtonTitle:WFCString(@"Ok") otherButtonTitles:nil, nil] show];
    [self stopPlayer];
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self.chatInputBar resetInputBarStatue];
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    if (self.hasNewMessage && targetContentOffset->y == (scrollView.contentSize.height - scrollView.bounds.size.height)) {
        [self loadMoreMessage:NO];
    }
    if (targetContentOffset->y == 0 && self.hasMoreOld) {
        [self loadMoreMessage:YES];
    }
    
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {


}
#pragma mark - ChatInputBarDelegate
- (void)imageDidCapture:(UIImage *)capturedImage {
    if (!capturedImage) {
        return;
    }
    
    WFCCImageMessageContent *imgContent = [WFCCImageMessageContent contentFrom:capturedImage];
    [self sendMessage:imgContent];
}

- (void)videoDidCapture:(NSString *)videoPath thumbnail:(UIImage *)image duration:(long)duration {
    WFCCVideoMessageContent *videoContent = [WFCCVideoMessageContent contentPath:videoPath thumbnail:image];
    [self sendMessage:videoContent];
}

- (void)didTouchSend:(NSString *)stringContent withMentionInfos:(NSMutableArray<WFCUMetionInfo *> *)mentionInfos {
  if (stringContent.length == 0) {
    return;
  }
  
    WFCCTextMessageContent *txtContent = [[WFCCTextMessageContent alloc] init];
    txtContent.text = stringContent;
    NSMutableArray *mentionTargets = [[NSMutableArray alloc] init];
    for (WFCUMetionInfo *mentionInfo in mentionInfos) {
        if (mentionInfo.mentionType == 2) {
            txtContent.mentionedType = 2;
            mentionTargets = nil;
            break;
        } else if(mentionInfo.mentionType == 1) {
            txtContent.mentionedType = 1;
            [mentionTargets addObject:mentionInfo.target];
        }
    }
    if (txtContent.mentionedType == 1) {
        txtContent.mentionedTargets = [mentionTargets copy];
    }
    
    [self sendMessage:txtContent];
}

- (void)recordDidEnd:(NSString *)dataUri duration:(long)duration error:(NSError *)error {
    [self sendMessage:[WFCCSoundMessageContent soundMessageContentForWav:dataUri duration:duration]];
}

- (void)willChangeFrame:(CGRect)newFrame withDuration:(CGFloat)duration keyboardShowing:(BOOL)keyboardShowing {
    [UIView animateWithDuration:duration animations:^{
        CGRect frame = self.collectionView.frame;
        CGFloat diff = MIN(frame.size.height, self.collectionView.contentSize.height) - newFrame.origin.y;
        if(diff > 0) {
            frame.origin.y = -diff;
            self.collectionView.frame = frame;
        } else {
            self.collectionView.frame = CGRectMake(0, 0, self.backgroundView.bounds.size.width, newFrame.origin.y);
        }
    } completion:^(BOOL finished) {
        self.collectionView.frame = CGRectMake(0, 0, self.backgroundView.bounds.size.width, newFrame.origin.y);
        
        if (keyboardShowing) {
            [self scrollToBottom:NO];
        }
    }];
}

- (UINavigationController *)requireNavi {
    return self.navigationController;
}

- (void)locationDidSelect:(CLLocationCoordinate2D)location locationName:(NSString *)locationName mapScreenShot:(UIImage *)mapScreenShot {
    WFCCLocationMessageContent *content = [WFCCLocationMessageContent contentWith:location title:locationName thumbnail:mapScreenShot];
    [self sendMessage:content];
}

- (void)didSelectFiles:(NSArray *)files {
    for (NSString *file in files) {
        WFCCFileMessageContent *content = [WFCCFileMessageContent fileMessageContentFromPath:file];
        [self sendMessage:content];
        [NSThread sleepForTimeInterval:0.05];
    }
}

- (void)saveStickerRemoteUrl:(WFCCStickerMessageContent *)stickerContent {
    if (stickerContent.localPath.length && stickerContent.remoteUrl.length) {
        [[NSUserDefaults standardUserDefaults] setObject:stickerContent.remoteUrl forKey:[NSString stringWithFormat:@"sticker_remote_for_%ld", stickerContent.localPath.hash]];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)didSelectSticker:(NSString *)stickerPath {
    WFCCStickerMessageContent * content = [WFCCStickerMessageContent contentFrom:stickerPath];
    NSString *remoteUrl = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"sticker_remote_for_%ld", stickerPath.hash]];
    content.remoteUrl = remoteUrl;
    
    [self sendMessage:content];
}
#if WFCU_SUPPORT_VOIP
- (void)didTouchVideoBtn:(BOOL)isAudioOnly {
    if(self.conversation.type == Single_Type) {
        WFCUVideoViewController *videoVC = [[WFCUVideoViewController alloc] initWithTarget:self.conversation.target conversation:self.conversation audioOnly:isAudioOnly];
        [[WFAVEngineKit sharedEngineKit] presentViewController:videoVC];
    } else {
      WFCUContactListViewController *pvc = [[WFCUContactListViewController alloc] init];
      pvc.selectContact = YES;
      pvc.multiSelect = YES;
      NSMutableArray *disabledUser = [[NSMutableArray alloc] init];
      [disabledUser addObject:[WFCCNetworkService sharedInstance].userId];
      pvc.disableUsers = disabledUser;
      NSMutableArray *candidateUser = [[NSMutableArray alloc] init];
      NSArray<WFCCGroupMember *> *members = [[WFCCIMService sharedWFCIMService] getGroupMembers:self.conversation.target forceUpdate:NO];
      for (WFCCGroupMember *member in members) {
        [candidateUser addObject:member.memberId];
      }
      pvc.candidateUsers = candidateUser;
      __weak typeof(self)ws = self;
      pvc.selectResult = ^(NSArray<NSString *> *contacts) {
        if (contacts.count == 1) {
          WFCUVideoViewController *videoVC = [[WFCUVideoViewController alloc] initWithTarget:[contacts objectAtIndex:0] conversation:ws.conversation audioOnly:isAudioOnly];
          [[WFAVEngineKit sharedEngineKit] presentViewController:videoVC];
        }
      };
      pvc.disableUsersSelected = YES;
      
      UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:pvc];
      [self.navigationController presentViewController:navi animated:YES completion:nil];
    }
}
#endif

- (void)onTyping:(WFCCTypingType)type {
    if (self.conversation.type == Single_Type) {
        [self sendMessage:[WFCCTypingMessageContent contentType:type]];
    }
}

#pragma mark - SDPhotoBrowserDelegate
- (UIImage *)photoBrowser:(SDPhotoBrowser *)browser placeholderImageForIndex:(NSInteger)index {
    WFCCMessage *msg = [self.imageMsgs objectAtIndex:index];
    if ([[msg.content class] getContentType] == MESSAGE_CONTENT_TYPE_IMAGE) {
        WFCCImageMessageContent *imgContent = (WFCCImageMessageContent *)msg.content;
        return imgContent.thumbnail;
    }
    return nil;
}

- (NSURL *)photoBrowser:(SDPhotoBrowser *)browser highQualityImageURLForIndex:(NSInteger)index {
    WFCCMessage *msg = [self.imageMsgs objectAtIndex:index];
    if ([[msg.content class] getContentType] == MESSAGE_CONTENT_TYPE_IMAGE) {
        WFCCImageMessageContent *imgContent = (WFCCImageMessageContent *)msg.content;
        return [NSURL URLWithString:[imgContent.remoteUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    }
    return nil;
}

- (void)photoBrowserDidDismiss:(SDPhotoBrowser *)browser {
    self.imageMsgs = nil;
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return self.navigationController.childViewControllers.count > 1;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return self.navigationController.viewControllers.count > 1;
}


#pragma mark - menu
- (void)displayMenu:(WFCUMessageCellBase *)baseCell {
    UIMenuController *menu = [UIMenuController sharedMenuController];
    
    UIMenuItem *deleteItem = [[UIMenuItem alloc]initWithTitle:WFCString(@"Delete") action:@selector(performDelete:)];
    UIMenuItem *copyItem = [[UIMenuItem alloc]initWithTitle:WFCString(@"Copy") action:@selector(performCopy:)];
    UIMenuItem *forwardItem = [[UIMenuItem alloc]initWithTitle:WFCString(@"Forward") action:@selector(performForward:)];
    UIMenuItem *recallItem = [[UIMenuItem alloc]initWithTitle:WFCString(@"Recall") action:@selector(performRecall:)];
    UIMenuItem *complainItem = [[UIMenuItem alloc]initWithTitle:WFCString(@"Complain") action:@selector(performComplain:)];
    
    CGRect menuPos;
    if ([baseCell isKindOfClass:[WFCUMessageCell class]]) {
        WFCUMessageCell *msgCell = (WFCUMessageCell *)baseCell;
        menuPos = msgCell.bubbleView.frame;
    } else {
        menuPos = baseCell.frame;
    }
    
    [menu setTargetRect:menuPos inView:baseCell];
    WFCCMessage *msg = baseCell.model.message;
    
    NSMutableArray *items = [[NSMutableArray alloc] init];
    [items addObject:deleteItem];
    if ([msg.content isKindOfClass:[WFCCTextMessageContent class]]) {
        [items addObject:copyItem];
    }
    
    if (baseCell.model.message.direction == MessageDirection_Receive) {
        [items addObject:complainItem];
    }
    
    if ([msg.content isKindOfClass:[WFCCImageMessageContent class]] ||
        [msg.content isKindOfClass:[WFCCTextMessageContent class]] ||
        [msg.content isKindOfClass:[WFCCLocationMessageContent class]] ||
        [msg.content isKindOfClass:[WFCCFileMessageContent class]] ||
        [msg.content isKindOfClass:[WFCCVideoMessageContent class]] ||
//        [msg.content isKindOfClass:[WFCCSoundMessageContent class]] || //语音消息禁止转发，出于安全原因考虑，微信就禁止转发。如果您能确保安全，可以把这行注释打开
        [msg.content isKindOfClass:[WFCCStickerMessageContent class]]) {
        [items addObject:forwardItem];
    }
    
    BOOL canRecall = NO;
    if ([baseCell isKindOfClass:[WFCUMessageCell class]] &&
        msg.direction == MessageDirection_Send
        ) {
        NSDate *cur = [NSDate date];
        if ([cur timeIntervalSince1970]*1000 - msg.serverTime < 60 * 1000) {
            canRecall = YES;
        }
        
    }
    
    if (!canRecall && self.conversation.type == Group_Type) {
        WFCCGroupInfo *groupInfo = [[WFCCIMService sharedWFCIMService] getGroupInfo:self.conversation.target refresh:NO];
        if([groupInfo.owner isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
            canRecall = YES;
            if ([groupInfo.owner isEqualToString:msg.fromUser]) {
                canRecall = NO;
            }
        } else {
            __block BOOL isManager = false;
            NSArray *memberList = [[WFCCIMService sharedWFCIMService] getGroupMembers:self.conversation.target forceUpdate:NO];
            [memberList enumerateObjectsUsingBlock:^(WFCCGroupMember * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([obj.memberId isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
                    if (obj.type != Member_Type_Normal && ![msg.fromUser isEqualToString:obj.memberId]) {
                        isManager = YES;
                    }
                    *stop = YES;
                }
            }];
            if(isManager && ![msg.fromUser isEqualToString:groupInfo.owner]) {
                canRecall = YES;
            }
        }
    }
    
    if (canRecall) {
        [items addObject:recallItem];
    }
    
    [menu setMenuItems:items];
    self.cell4Menu = baseCell;
    
    [menu setMenuVisible:YES];
}


-(BOOL)canBecomeFirstResponder {
    return YES;
}

-(BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if(self.cell4Menu) {
        if (action == @selector(performDelete:) || action == @selector(performCopy:) || action == @selector(performForward:) || action == @selector(performRecall:) || action == @selector(performComplain:)) {
            return YES; //显示自定义的菜单项
        } else {
            return NO;
        }
    }
    
    if (action == @selector(paste:)) {
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        return pasteboard.string != nil;
    }
    return NO;//[super canPerformAction:action withSender:sender];
}

- (void)paste:(id)sender {
    [self.chatInputBar paste:sender];
}

-(void)performDelete:(UIMenuController *)sender {
    [[WFCCIMService sharedWFCIMService] deleteMessage:self.cell4Menu.model.message.messageId];
    [self.modelList removeObject:self.cell4Menu.model];
    [self.collectionView deleteItemsAtIndexPaths:@[[self.collectionView indexPathForCell:self.cell4Menu]]];
}

-(void)performCopy:(UIMenuItem *)sender {
    if (self.cell4Menu) {
        if ([self.cell4Menu.model.message.content isKindOfClass:[WFCCTextMessageContent class]]) {
            UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            pasteboard.string = ((WFCCTextMessageContent *)self.cell4Menu.model.message.content).text;
        }
    }
}

-(void)performForward:(UIMenuItem *)sender {
    if (self.cell4Menu) {
        WFCUForwardViewController *controller = [[WFCUForwardViewController alloc] init];
        controller.message = self.cell4Menu.model.message;
        UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:controller];
        [self.navigationController presentViewController:navi animated:YES completion:nil];
    }
}

-(void)performRecall:(UIMenuItem *)sender {
    if (self.cell4Menu.model.message) {
        __block MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.label.text = WFCString(@"Recalling");
        [hud showAnimated:YES];
        __weak typeof(self) ws = self;
        long messageId = self.cell4Menu.model.message.messageId;
        WFCUMessageCellBase *cell = self.cell4Menu;
        [[WFCCIMService sharedWFCIMService] recall:self.cell4Menu.model.message success:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [hud hideAnimated:YES];
                if (cell.model.message.messageId == messageId) {
                    cell.model.message = [[WFCCIMService sharedWFCIMService] getMessage:messageId];
                    [ws.collectionView reloadItemsAtIndexPaths:@[[ws.collectionView indexPathForCell:cell]]];
                }
            });
        } error:^(int error_code) {
            dispatch_async(dispatch_get_main_queue(), ^{
                hud.mode = MBProgressHUDModeText;
                hud.label.text = WFCString(@"RecallFailure");
                [hud hideAnimated:YES afterDelay:1.f];
            });
        }];
    }
}

- (void)performComplain:(UIMenuItem *)sender {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:WFCString(@"Complain") message:@"如果您发现有违反法律和道德的内容，或者您的合法权益受到侵犯，请截图之后发送给我们。我们会在24小时之内处理。处理办法包括不限于删除内容，对作者进行警告，冻结账号，甚至报警处理。举报请到\"设置->设置->举报\"联系我们！" preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *action = [UIAlertAction actionWithTitle:WFCString(WFCString(@"Ok")) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        
    }];
    [alertController addAction:action];
    
    [self presentViewController:alertController animated:YES completion:nil];
}
- (void)onMenuHidden:(id)sender {
    UIMenuController *menu = [UIMenuController sharedMenuController];
    [menu setMenuItems:nil];
    __weak typeof(self)ws = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        ws.cell4Menu = nil;
    });
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            [self.navigationController popViewControllerAnimated:NO];
        }
    }
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
