//
//  ViewController.m
//  WFDemo
//
//  Created by heavyrain on 17/9/27.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#if WFCU_SUPPORT_VOIP
#import "WFCUConferenceViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>

#import <WebRTC/WebRTC.h>
#import <WFAVEngineKit/WFAVEngineKit.h>
#import "WFCUFloatingWindow.h"
#import "WFCUConferenceParticipantCollectionViewCell.h"
#import <SDWebImage/SDWebImage.h>
#import <WFChatClient/WFCCConversation.h>
#import "WFCUConferencePortraitCollectionViewCell.h"
#import "WFCUParticipantCollectionViewLayout.h"
#import "WFCUSeletedUserViewController.h"
#import "UIView+Toast.h"
#import "WFCUConferenceInviteViewController.h"
#import "WFCUConferenceMemberManagerViewController.h"
#import "WFCUConferenceCollectionViewLayout.h"
#import "WFCUConferenceManager.h"
#import "WFCUImage.h"
#import "WFZConferenceInfo.h"
#import "WFCUConferenceLabelView.h"
#import "WFCUConfigManager.h"
#import "WFCUUtilities.h"
#import "WFCUMessageListViewController.h"
#import "WFCUMoreBoardView.h"
#import "WFCUConferenceAudioCollectionViewCell.h"

@interface WFCUConferenceViewController () <UITextFieldDelegate
    ,WFAVCallSessionDelegate
    ,UICollectionViewDataSource
    ,UICollectionViewDelegate
    ,WFCUConferenceManagerDelegate
    ,UITableViewDataSource
>

@property (nonatomic, strong) UICollectionView *participantCollectionView;
@property (nonatomic, strong) UIButton *moreButton;
@property (nonatomic, strong) UIButton *hangupButton;
@property (nonatomic, strong) UIButton *switchCameraButton;
@property (nonatomic, strong) UIButton *audioButton;
@property (nonatomic, strong) UIButton *floatingAudioButton;
@property (nonatomic, strong) UIButton *speakerButton;
@property (nonatomic, strong) UIButton *videoButton;
@property (nonatomic, strong) UIButton *managerButton;
@property (nonatomic, strong) UIButton *screenSharingButton;
@property (nonatomic, strong) UIButton *informationButton;

@property (nonatomic, strong)WFCUConferenceParticipantCollectionViewCell *smallVideoView;

@property (nonatomic, strong) UIImageView *portraitView;
@property (nonatomic, strong) UILabel *userNameLabel;
@property (nonatomic, strong) UILabel *stateLabel;
@property (nonatomic, strong) UILabel *connectTimeLabel;

@property (nonatomic, strong) WFAVCallSession *currentSession;

@property (nonatomic, assign) WFAVVideoScalingType scalingType;

@property (nonatomic, assign) CGPoint panStartPoint;
@property (nonatomic, assign) CGRect panStartVideoFrame;
@property (nonatomic, strong) NSTimer *connectedTimer;

@property(nonatomic, strong)UIView *conferenceInfoView;

@property (nonatomic, strong) NSMutableArray<WFAVParticipantProfile *> *participants;

@property(nonatomic, strong)UIView *bottomBarView;
@property(nonatomic, strong)UIView *topBarView;

@property(nonatomic, strong)NSTimer *hidePanelTimer;


@property (nonatomic, strong)UITableView *messageTableView;
@property (nonatomic, strong)NSMutableArray<WFCCMessage *> *messages;
@property (nonatomic, strong)NSTimer *removeOldMessageTimer;
@property (nonatomic, strong)UIButton *chatButton;
@property(nonatomic, strong)UIView *inputContainer;
@property(nonatomic, strong)UITextField *inputTextField;
@property (nonatomic, strong)UIButton *rotateButton;
@property (nonatomic, strong)UIButton *lockButton;
@property(nonatomic, assign)UIInterfaceOrientation currentOrientation;

@property(nonatomic, strong)WFAVParticipantProfile *focusUserProfile;

@property(nonatomic, strong)UIPageControl *pageControl;
@property(nonatomic, strong)WFCUMoreBoardView *boardView;

@property(nonatomic, strong)WFZConferenceInfo *conferenceInfo;
@end

#define ButtonSize 60
#define BottomPadding 36
#define SmallVideoView 120
#define OperationTitleFont 10
#define OperationButtonSize 50

#define PortraitItemSize 48
#define PortraitLabelSize 16

#define CONFERENCE_TOP_BAR_WIDTH  48
#define CONFERENCE_BAR_HEIGHT  48
#define TopViewHeigh ([WFCUUtilities wf_statusBarHeight] + CONFERENCE_BAR_HEIGHT)

#define FLOATING_AUDIO_BUTTON_SIZE 48

/*
 视频会议窗口排列规则：
 1. 首页显示大窗口，大窗口中有一个覆盖全屏的窗口，和一个小的预览窗口。大窗口显示焦点用户，预览窗口显示自己。可以点击预览窗口切换自己和焦点用户。
 2. 如果只有一个其他用户，只显示第一页。如果多于一个其他用户，从第二页开始显示网格窗口，自己和其他人分布排列。自己在第一个位置。
 3. 点击网格窗口，则设置为焦点用户，界面切换至首页。自己不能被设置为焦点用户。
 */
@implementation WFCUConferenceViewController
- (instancetype)initWithSession:(WFAVCallSession *)session conferenceInfo:(WFZConferenceInfo *)conferenceInfo {
    self = [super init];
    if (self) {
        self.currentSession = session;
        self.currentSession.delegate = self;
        [WFCUConferenceManager sharedInstance].currentConferenceInfo = conferenceInfo;
        self.currentSession.autoSwitchVideoType = NO;
        self.currentSession.defaultVideoType = WFAVVideoType_None;
        [[WFCUConferenceManager sharedInstance] joinChatroom];
    }
    return self;
}

- (instancetype)initWithCallId:(NSString *_Nullable)callId
                     audioOnly:(BOOL)audioOnly
                           pin:(NSString *_Nullable)pin
                          host:(NSString *_Nullable)host
                         title:(NSString *_Nullable)title
                          desc:(NSString *_Nullable)desc
                      audience:(BOOL)audience
                      advanced:(BOOL)advanced
                        record:(BOOL)record
                        moCall:(BOOL)moCall
               maxParticipants:(int)maxParticipants
                         extra:(NSString *)extra {
    self = [super init];
    if (self) {
        if (moCall) {
            self.currentSession = [[WFAVEngineKit sharedEngineKit] startConference:callId audioOnly:audioOnly pin:pin host:host title:title desc:desc callExtra:extra audience:audience advanced:advanced record:NO maxParticipants:maxParticipants sessionDelegate:self];
            
            [self didChangeState:kWFAVEngineStateOutgoing];
        } else {
            self.currentSession = [[WFAVEngineKit sharedEngineKit]
                                   joinConference:callId
                                   audioOnly:audioOnly
                                   pin:pin
                                   host:host
                                   title:title
                                   desc:desc
                                   callExtra:extra
                                   audience:audience
                                   advanced:advanced
                                   muteAudio:NO
                                   muteVideo:NO
                                   sessionDelegate:self];
            [self didChangeState:kWFAVEngineStateIncomming];
            
        }
        self.currentSession.autoSwitchVideoType = NO;
        self.currentSession.defaultVideoType = WFAVVideoType_None;
    }
    return self;
}

-(instancetype)initWithConferenceInfo:(WFZConferenceInfo *)conferenceInfo muteAudio:(BOOL)muteAudio muteVideo:(BOOL)muteVideo {
    self = [super init];
    if (self) {
        [WFCUConferenceManager sharedInstance].currentConferenceInfo = conferenceInfo;
        self.currentSession = [[WFAVEngineKit sharedEngineKit] joinConference:conferenceInfo.conferenceId audioOnly:NO pin:conferenceInfo.pin host:conferenceInfo.owner title:conferenceInfo.conferenceTitle desc:nil callExtra:nil audience:(muteAudio && muteVideo) || conferenceInfo.audience advanced:conferenceInfo.advance muteAudio:muteAudio muteVideo:muteVideo sessionDelegate:self];
        self.currentSession.autoSwitchVideoType = NO;
        self.currentSession.defaultVideoType = WFAVVideoType_None;
        [self didChangeState:kWFAVEngineStateIncomming];
        [[WFCUConferenceManager sharedInstance] joinChatroom];
    }
    return self;
}

- (WFZConferenceInfo *)conferenceInfo {
    return [WFCUConferenceManager sharedInstance].currentConferenceInfo;
}

/*
 session的participantIds是除了自己外的所有成员。这里把自己也加入列表，然后把发起者放到最后面。
 */
- (void)rearrangeParticipants {
    self.participants = [[NSMutableArray alloc] init];
    
    BOOL audioOnly = YES;
    NSArray<WFAVParticipantProfile *> *ps = self.currentSession.participants;
    NSString *focus = [WFCUConferenceManager sharedInstance].currentConferenceInfo.focus;
    for (WFAVParticipantProfile *p in ps) {
        if([self.focusUserProfile.userId isEqualToString:p.userId] && self.focusUserProfile.screeSharing == p.screeSharing) {
            [self.participants insertObject:p atIndex:0];
        } else {
            [self.participants addObject:p];
        }
        
        if(!p.audience && !p.videoMuted) {
            audioOnly = NO;
        }
    }
    
    if(audioOnly) {
        if((!self.currentSession.audience && !self.currentSession.videoMuted) || [self.currentSession isBroadcasting]) {
            audioOnly = NO;
        }
    }
    
    [self.participants sortUsingComparator:^NSComparisonResult(WFAVParticipantProfile *obj1, WFAVParticipantProfile *obj2) {
        //焦点用户拥有最高优先级
        if([obj1.userId isEqualToString:self.focusUserProfile.userId] && obj1.screeSharing == self.focusUserProfile.screeSharing) {
            return NSOrderedAscending;
        }
        if([obj2.userId isEqualToString:self.focusUserProfile.userId] &&obj2.screeSharing == self.focusUserProfile.screeSharing) {
            return NSOrderedDescending;
        }
        
        //比较两个profile的大小，开视频的<关视频的<观众
        if(obj1.audience && !obj2.audience) {
            return NSOrderedDescending;
        } else if(!obj1.audience && obj2.audience) {
            return NSOrderedAscending;
        } else { //obj1.audience == obj2.audience
            if(obj1.videoMuted == obj2.videoMuted) {
                return [obj1.userId compare:obj2.userId];
            }
            if(obj1.videoMuted && !obj2.videoMuted) {
                return NSOrderedDescending;
            }
            return NSOrderedAscending;
        }
    }];
    
    [self.participants insertObject:self.currentSession.myProfile atIndex:0];
    
    __block BOOL focusExist = NO;
    if(focus.length) {
        [self.participants enumerateObjectsUsingBlock:^(WFAVParticipantProfile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if([obj.userId isEqualToString:focus]) {
                if(![self.focusUserProfile.userId isEqualToString:obj.userId] || self.focusUserProfile.screeSharing == NO) {
                    self.focusUserProfile = obj;
                    focusExist = YES;
                }
            }
        }];
    }
    
    if(!focusExist && (!self.focusUserProfile || [self.focusUserProfile.userId isEqualToString:[WFCCNetworkService sharedInstance].userId])) {
        self.focusUserProfile = self.currentSession.myProfile;
        [self.participants enumerateObjectsUsingBlock:^(WFAVParticipantProfile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if(![obj.userId isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
                self.focusUserProfile = obj;
                *stop = YES;
            }
        }];
    }
    
    if(self.focusUserProfile) {
        self.focusUserProfile = [self.currentSession profileOfUser:self.focusUserProfile.userId isScreenSharing:self.focusUserProfile.screeSharing];
    }
    
    [self.managerButton setTitle:[NSString stringWithFormat:@"管理(%ld)", self.participants.count] forState:UIControlStateNormal];
    
    
    self.managerButton.titleEdgeInsets = UIEdgeInsetsMake(self.managerButton.imageView.frame.size.height / 2-12, -self.managerButton.imageView.frame.size.width,
                                              -self.managerButton.imageView.frame.size.height, 0);
    self.managerButton.imageEdgeInsets = UIEdgeInsetsMake(-8,
                                              0, self.managerButton.imageView.frame.size.height / 2, -self.managerButton.titleLabel.bounds.size.width);
    
    WFCUConferenceCollectionViewLayout *layout = (WFCUConferenceCollectionViewLayout *)self.participantCollectionView.collectionViewLayout;
    layout.audioOnly = audioOnly;
    
    self.pageControl.numberOfPages = [self getPagesCount];
    self.pageControl.hidden = self.pageControl.numberOfPages == 1;
    if(self.pageControl.currentPage > self.pageControl.numberOfPages) {
        [self.pageControl setCurrentPage:0];
    }
}


- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor blackColor]];
    self.messages = [[NSMutableArray alloc] init];
    
    WFCUConferenceCollectionViewLayout *layout = [[WFCUConferenceCollectionViewLayout alloc] init];
    self.scalingType = kWFAVVideoScalingTypeAspectFit;
    
    //    CGRect collectionRect = CGRectMake(0, TopViewHeigh, self.view.bounds.size.width, self.view.bounds.size.height - TopViewHeigh - [WFCUUtilities wf_safeDistanceBottom] - CONFERENCE_BAR_HEIGHT);
    CGRect collectionRect = CGRectMake(0, [WFCUUtilities wf_statusBarHeight], self.view.bounds.size.width, self.view.bounds.size.height- [WFCUUtilities wf_statusBarHeight] - [WFCUUtilities wf_safeDistanceBottom]);
    
    self.participantCollectionView = [[UICollectionView alloc] initWithFrame:collectionRect collectionViewLayout:layout];
    self.participantCollectionView.dataSource = self;
    self.participantCollectionView.delegate = self;
    [self.participantCollectionView registerClass:[WFCUConferenceParticipantCollectionViewCell class] forCellWithReuseIdentifier:@"main"];
    [self.participantCollectionView registerClass:[WFCUConferenceParticipantCollectionViewCell class] forCellWithReuseIdentifier:@"sub"];
    [self.participantCollectionView registerClass:[WFCUConferenceAudioCollectionViewCell class] forCellWithReuseIdentifier:@"audio_cell"];
    [self.participantCollectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"broadcasting"];
    self.participantCollectionView.backgroundColor = [UIColor clearColor];
    if (self.currentSession.audioOnly) {
        self.participantCollectionView.hidden = YES;
    }
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onClickedParticipantCollectionView:)];
    [self.participantCollectionView addGestureRecognizer:tap];
    tap.cancelsTouchesInView = NO;
    [self.view addSubview:self.participantCollectionView];
    
    [self bottomBarView];
    [self topBarView];
    
    self.pageControl = [[UIPageControl alloc]initWithFrame:CGRectMake(self.view.bounds.size.width/2-100, self.view.bounds.size.height - [WFCUUtilities wf_safeDistanceBottom] - 20, 200, 20)];
    [self.pageControl addTarget:self
                         action:@selector(pageChange:)
               forControlEvents:UIControlEventValueChanged];
    
    self.pageControl.pageIndicatorTintColor = [UIColor colorWithRed:0.7 green:0.7 blue:0.7 alpha:1.f];
    self.pageControl.currentPageIndicatorTintColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.f];
    self.pageControl.backgroundColor = [UIColor clearColor];
    
    self.pageControl.numberOfPages = 0;
    self.pageControl.currentPage = 0;
    if (@available(iOS 14.0, *)) {
        self.pageControl.backgroundStyle = UIPageControlBackgroundStyleMinimal;
        self.pageControl.allowsContinuousInteraction = YES;
    }
    [self.view addSubview:self.pageControl];
    
    [self rearrangeParticipants];
    
    self.smallVideoView = [[WFCUConferenceParticipantCollectionViewCell alloc] initWithFrame:CGRectMake(8, CONFERENCE_BAR_HEIGHT, SmallVideoView, SmallVideoView * 4 /3)];
    [self.smallVideoView addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onSmallVideoPan:)]];
    [self.smallVideoView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onSmallVideoTaped:)]];
    //因为smallVideoView是加在主窗口的视频view上，当音视频引擎收到流后会在主窗口视频view上添加子view，可能会盖住smallVideoView。
    //这里设置一个特殊的tag，当音视频引擎添加子view时，会把有特殊tag的窗口放到最上方。
    self.smallVideoView.tag = 666;
    
    if(self.currentSession.state == kWFAVEngineStateOutgoing && !self.currentSession.isAudioOnly) {
        [[WFAVEngineKit sharedEngineKit] startVideoPreview];
    }
    
    WFCCUserInfo *user = [[WFCCIMService sharedWFCIMService] getUserInfo:self.currentSession.initiator inGroup:self.currentSession.conversation.type == Group_Type ? self.currentSession.conversation.target : nil refresh:NO];
    
    self.portraitView = [[UIImageView alloc] init];
    [self.portraitView sd_setImageWithURL:[NSURL URLWithString:[user.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:[WFCUImage imageNamed:@"PersonalChat"]];
    self.portraitView.layer.masksToBounds = YES;
    self.portraitView.layer.cornerRadius = 8.f;
    [self.view addSubview:self.portraitView];
    
    
    self.userNameLabel = [[UILabel alloc] init];
    self.userNameLabel.font = [UIFont systemFontOfSize:26];
    self.userNameLabel.text = user.displayName;
    self.userNameLabel.textColor = [UIColor whiteColor];
    [self.view addSubview:self.userNameLabel];
    
    self.stateLabel = [[UILabel alloc] init];
    self.stateLabel.font = [UIFont systemFontOfSize:16];
    self.stateLabel.textColor = [UIColor whiteColor];
    [self.view addSubview:self.stateLabel];
    
    
    [self updatePortraitAndStateViewFrame];
    self.bottomBarView.hidden = NO;
    
    
    [self didChangeState:self.currentSession.state];//update ui
    
    [self onDeviceOrientationDidChange];
    
    [WFCUConferenceManager sharedInstance].delegate = self;
    [self startHidePanelTimer];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onReceiveMessages:) name:kReceiveMessages object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onLocalMuteStateChanged:) name:kMuteStateChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMessageSent:) name:kSendingMessageStatusUpdated object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onBroadcastingStatusUpdated:) name:@"kBroadcastingStatusUpdated" object:nil];
}

- (UIButton *)chatButton {
    if(!_chatButton) {
        _chatButton = [[UIButton alloc] initWithFrame:CGRectZero];
        [_chatButton setTitle:WFCString(@"TalkAboutSomething") forState:UIControlStateNormal];
        [_chatButton setTitleColor:[UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:0.5] forState:UIControlStateNormal];
        _chatButton.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.5];
        _chatButton.layer.masksToBounds = YES;
        _chatButton.layer.cornerRadius = 3.f;
        _chatButton.titleLabel.font = [UIFont systemFontOfSize:13];
        [_chatButton addTarget:self action:@selector(chatButtonDidTap:) forControlEvents:UIControlEventTouchDown];
        [self.view addSubview:_chatButton];
    }
    return _chatButton;
}

- (UIButton *)rotateButton {
    if(!_rotateButton) {
        _rotateButton = [[UIButton alloc] initWithFrame:CGRectZero];
        [_rotateButton setImage:[WFCUImage imageNamed:@"rotate_screen"] forState:UIControlStateNormal];
        _rotateButton.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.5];
        _rotateButton.layer.masksToBounds = YES;
        _rotateButton.layer.cornerRadius = 3.f;
        [_rotateButton addTarget:self action:@selector(rotateButtonDidTap:) forControlEvents:UIControlEventTouchDown];
        [self.view addSubview:_rotateButton];
    }
    return _rotateButton;
}

- (UIButton *)lockButton {
    if(!_lockButton) {
        _lockButton = [[UIButton alloc] initWithFrame:CGRectZero];
        [_lockButton setImage:[WFCUImage imageNamed:@"rotate_lock_off"] forState:UIControlStateNormal];
        [_lockButton setImage:[WFCUImage imageNamed:@"rotate_lock_on"] forState:UIControlStateSelected];
        _lockButton.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.5];
        _lockButton.layer.masksToBounds = YES;
        _lockButton.layer.cornerRadius = 3.f;
        [_lockButton addTarget:self action:@selector(lockButtonDidTap:) forControlEvents:UIControlEventTouchDown];
        [self.view addSubview:_lockButton];
    }
    return _lockButton;
}

- (UITableView *)messageTableView {
    if(!_messageTableView) {
        _messageTableView = [[UITableView alloc] initWithFrame:CGRectZero];
        _messageTableView.dataSource = self;
        _messageTableView.backgroundColor = [UIColor clearColor];
        _messageTableView.rowHeight = UITableViewAutomaticDimension;
        _messageTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _messageTableView.showsVerticalScrollIndicator = NO;
        _messageTableView.allowsSelection = NO;
        
        if (@available(iOS 10.0, *)) {
            __weak typeof(self)ws = self;
            self.removeOldMessageTimer = [NSTimer scheduledTimerWithTimeInterval:3 repeats:YES block:^(NSTimer * _Nonnull timer) {
                [ws removeOldMessageAndShow];
            }];
            [self.removeOldMessageTimer fire];
        } else {
            // Fallback on earlier versions
        }
        
        [self.view addSubview:_messageTableView];
        
    }
    return _messageTableView;
}

- (UIButton *)floatingAudioButton {
    if(!_floatingAudioButton) {
        CGRect bound = self.view.bounds;
        _floatingAudioButton = [[UIButton alloc] initWithFrame:CGRectMake((bound.size.width - FLOATING_AUDIO_BUTTON_SIZE)/2, bound.size.height - [WFCUUtilities wf_safeDistanceBottom] - FLOATING_AUDIO_BUTTON_SIZE - CONFERENCE_BAR_HEIGHT, FLOATING_AUDIO_BUTTON_SIZE, FLOATING_AUDIO_BUTTON_SIZE)];
        [_floatingAudioButton setImage:[WFCUImage imageNamed:@"conference_audio"] forState:UIControlStateNormal];
        _floatingAudioButton.hidden = YES;
        _floatingAudioButton.backgroundColor = [UIColor grayColor];
        _floatingAudioButton.layer.masksToBounds = YES;
        _floatingAudioButton.layer.cornerRadius = FLOATING_AUDIO_BUTTON_SIZE/2;
        [_floatingAudioButton addTarget:self action:@selector(audioButtonDidTap:) forControlEvents:UIControlEventTouchDown];
        [self.view addSubview:_floatingAudioButton];
    }
    return _floatingAudioButton;
}

- (void)updateAudioVolume:(NSInteger)volume {
    if(self.currentSession.isAudioMuted)
        return;
    
    int v = (int)(volume/1000);
    if(v < 0) {
        v = 0;
    }
    if(v > 10) {
        v = 10;
    }
    __weak typeof(self)ws = self;
    [UIView animateWithDuration:0.2 animations:^{
        [ws.floatingAudioButton setImage:[WFCUImage imageNamed:[NSString stringWithFormat:@"mic_%d", v]] forState:UIControlStateNormal];
    }];
}

- (UIButton *)createBarButtom:(NSString *)title imageName:(NSString *)imageName selectedImageName:(NSString *)selectedImageName select:(SEL)selector frame:(CGRect)frame {
    UIButton *btn = [[UIButton alloc] initWithFrame:frame];
    btn.clipsToBounds = YES;
    [btn setImage:[WFCUImage imageNamed:imageName] forState:UIControlStateNormal];
    [btn setTitle:title forState:UIControlStateNormal];
    btn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    btn.titleLabel.font = [UIFont systemFontOfSize:12];
    
//    [btn setTitleEdgeInsets:UIEdgeInsetsMake((btn.imageView.frame.size.height+24)/2 ,-btn.imageView.frame.size.width, 0.0,0.0)];
//    [btn setImageEdgeInsets:UIEdgeInsetsMake((-btn.titleLabel.frame.size.height-24)/2, 0.0,0.0, -btn.titleLabel.bounds.size.width)];
//
    
    [btn setTitleColor:[UIColor colorWithRed:0.85 green:0.85 blue:0.85 alpha:1] forState:UIControlStateNormal];
    [btn addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
    [btn setImage:[WFCUImage imageNamed:selectedImageName] forState:UIControlStateHighlighted];
    [btn setImage:[WFCUImage imageNamed:selectedImageName] forState:UIControlStateSelected];
    
    btn.titleEdgeInsets = UIEdgeInsetsMake(btn.imageView.frame.size.height / 2-12, -btn.imageView.frame.size.width,
                                              -btn.imageView.frame.size.height, 0);
    btn.imageEdgeInsets = UIEdgeInsetsMake(-8,
                                              0, btn.imageView.frame.size.height / 2, -btn.titleLabel.bounds.size.width);
    
    return btn;
}

- (NSInteger)getPagesCount {
    WFCUConferenceCollectionViewLayout *layout = (WFCUConferenceCollectionViewLayout *)self.participantCollectionView.collectionViewLayout;
    if(layout.audioOnly) {
        return (self.participants.count - 1)/12 + 1;
    } else {
        if(self.participants.count == 1 || self.participants.count == 2) {
            return 1;
        }
        return (self.participants.count-1)/4+1+1;
    }
}
- (void)updateTopBarViewFrame:(BOOL)landscape {
    CGFloat topPadding = landscape ? 0 : [WFCUUtilities wf_statusBarHeight];
    self.topBarView.frame = CGRectMake(0, 0, self.view.bounds.size.width, topPadding + CONFERENCE_TOP_BAR_WIDTH);
    self.informationButton.frame = CGRectMake(self.view.bounds.size.width/2 - 70, topPadding + 6, 140, 14);
    if(self.conferenceInfo.conferenceTitle.length) {
        CGFloat space = 4;
        _informationButton.titleEdgeInsets = UIEdgeInsetsMake(0, - _informationButton.imageView.image.size.width - space,0,_informationButton.imageView.image.size.width + space);
        _informationButton.imageEdgeInsets = UIEdgeInsetsMake(0, _informationButton.titleLabel.frame.size.width + space, 0,  -_informationButton.titleLabel.frame.size.width - space);
    }
    
    self.connectTimeLabel.frame = CGRectMake(self.view.bounds.size.width/2 - 60, topPadding + 6 + 18 + 4 , 120, 14);
    self.hangupButton.frame = CGRectMake(self.view.bounds.size.width - 8 - CONFERENCE_TOP_BAR_WIDTH, topPadding + 2, CONFERENCE_TOP_BAR_WIDTH, CONFERENCE_BAR_HEIGHT);
    self.speakerButton.frame = CGRectMake(8, topPadding + 2, CONFERENCE_TOP_BAR_WIDTH, CONFERENCE_BAR_HEIGHT);
    self.switchCameraButton.frame = CGRectMake(8+CONFERENCE_TOP_BAR_WIDTH+4, topPadding + 2, CONFERENCE_TOP_BAR_WIDTH, CONFERENCE_BAR_HEIGHT);
}

- (UIView *)topBarView {
    if(!_topBarView) {
        _topBarView = [[UIView alloc] initWithFrame:CGRectZero];
        _topBarView.backgroundColor = [UIColor colorWithRed:0.2 green:0.37 blue:0.9 alpha:1];
        [self.view addSubview:_topBarView];
        
        _informationButton = [[UIButton alloc] initWithFrame:CGRectZero];
        [_informationButton setImage:[WFCUImage imageNamed:@"conference_information"] forState:UIControlStateNormal];
        _informationButton.backgroundColor = [UIColor clearColor];
        _informationButton.titleLabel.font = [UIFont systemFontOfSize:14];
        [_informationButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        if(self.conferenceInfo.conferenceTitle.length) {
            [_informationButton setTitle:self.conferenceInfo.conferenceTitle forState:UIControlStateNormal];
        }
        [_informationButton addTarget:self action:@selector(informationButtonDidTap:) forControlEvents:UIControlEventTouchDown];
        [_topBarView addSubview:_informationButton];
        
        _connectTimeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _connectTimeLabel.textAlignment = NSTextAlignmentCenter;
        _connectTimeLabel.font = [UIFont systemFontOfSize:14];
        _connectTimeLabel.textColor = [UIColor whiteColor];
        [_topBarView addSubview:_connectTimeLabel];
        
        _hangupButton = [[UIButton alloc] initWithFrame:CGRectZero];
        [_hangupButton setImage:[WFCUImage imageNamed:@"conference_end_call"] forState:UIControlStateNormal];
        _hangupButton.backgroundColor = [UIColor clearColor];
        [_hangupButton addTarget:self action:@selector(hanupButtonDidTap:) forControlEvents:UIControlEventTouchDown];
        [_topBarView addSubview:_hangupButton];
        
        _speakerButton = [[UIButton alloc] initWithFrame:CGRectZero];
        [_speakerButton setImage:[WFCUImage imageNamed:@"conference_speaker"] forState:UIControlStateNormal];
        [_speakerButton setImage:[WFCUImage imageNamed:@"conference_speaker"] forState:UIControlStateHighlighted];
        [_speakerButton setImage:[WFCUImage imageNamed:@"conference_speaker"] forState:UIControlStateSelected];
        _speakerButton.backgroundColor = [UIColor clearColor];
        [_speakerButton addTarget:self action:@selector(speakerButtonDidTap:) forControlEvents:UIControlEventTouchDown];
        [_topBarView addSubview:_speakerButton];
        
        _switchCameraButton = [[UIButton alloc] initWithFrame:CGRectZero];
        [_switchCameraButton setImage:[WFCUImage imageNamed:@"conference_switch_camera"] forState:UIControlStateNormal];
        _switchCameraButton.backgroundColor = [UIColor clearColor];
        [_switchCameraButton addTarget:self action:@selector(switchCameraButtonDidTap:) forControlEvents:UIControlEventTouchDown];
        _switchCameraButton.hidden = YES;
        [_topBarView addSubview:_switchCameraButton];
    }
    return _topBarView;
}

- (void)updatebottomBarViewFrame:(BOOL)landscape {
    CGFloat bottomPadding = landscape ? 0 : [WFCUUtilities wf_safeDistanceBottom];
    self.bottomBarView.frame = CGRectMake(0, self.view.bounds.size.height - bottomPadding-CONFERENCE_BAR_HEIGHT, self.view.bounds.size.width, CONFERENCE_BAR_HEIGHT+bottomPadding);

    int index = 0;
    CGFloat btnWidth = self.view.bounds.size.width/(self.currentSession.isAudioOnly ? 4 : 5);
    self.audioButton.frame = CGRectMake(btnWidth * index++, 0, btnWidth, CONFERENCE_BAR_HEIGHT);
    self.videoButton.frame = CGRectMake(btnWidth * index++, 0, btnWidth, CONFERENCE_BAR_HEIGHT);
    if(!self.currentSession.isAudioOnly) {
        self.screenSharingButton.frame = CGRectMake(btnWidth * index++, 0, btnWidth, CONFERENCE_BAR_HEIGHT);
    }
    self.managerButton.frame = CGRectMake(btnWidth * index++, 0, btnWidth, CONFERENCE_BAR_HEIGHT);
    self.moreButton.frame = CGRectMake(btnWidth * index++, 0, btnWidth, CONFERENCE_BAR_HEIGHT);
}

- (UIView *)bottomBarView {
    if(!_bottomBarView) {
        _bottomBarView = [[UIView alloc] initWithFrame:CGRectZero];
        _bottomBarView.backgroundColor = [UIColor colorWithRed:0.2 green:0.37 blue:0.9 alpha:1];
        CGFloat btnWidth = self.view.bounds.size.width/(self.currentSession.isAudioOnly ? 4 : 5);
        
        int index = 1;
        self.audioButton = [self createBarButtom:@"静音" imageName:@"conference_audio" selectedImageName:@"conference_audio" select:@selector(audioButtonDidTap:) frame:CGRectMake(0, 0, btnWidth, CONFERENCE_BAR_HEIGHT)];
        [_bottomBarView addSubview:self.audioButton];
        
        self.videoButton = [self createBarButtom:@"视频" imageName:@"conference_video" selectedImageName:@"conference_video" select:@selector(videoButtonDidTap:) frame:CGRectMake(btnWidth, 0, btnWidth, CONFERENCE_BAR_HEIGHT)];
        [_bottomBarView addSubview:self.videoButton];
        
        index++;
        if(!self.currentSession.isAudioOnly) {
            self.screenSharingButton = [self createBarButtom:@"屏幕共享" imageName:@"conference_screen_sharing" selectedImageName:@"conference_screen_sharing_hover" select:@selector(screenSharingButtonDidTap:) frame:CGRectMake(btnWidth*index++, 0, btnWidth, CONFERENCE_BAR_HEIGHT)];
            
            if(self.currentSession.state == kWFAVEngineStateConnected)
                self.screenSharingButton.hidden = NO;
            else
                self.screenSharingButton.hidden = YES;
            [self updateScreenSharingButton];
            [_bottomBarView addSubview:self.screenSharingButton];
        }
        
        self.managerButton = [self createBarButtom:[NSString stringWithFormat:@"管理(%ld)", self.participants.count] imageName:@"conference_members" selectedImageName:@"conference_members" select:@selector(managerButtonDidTap:) frame:CGRectMake(btnWidth*index++, 0, btnWidth, CONFERENCE_BAR_HEIGHT)];
        [_bottomBarView addSubview:self.managerButton];
        
        self.moreButton = [self createBarButtom:@"更多" imageName:@"conference_more" selectedImageName:@"conference_more" select:@selector(moreButtonDidTap:) frame:CGRectMake(btnWidth*index++, 0, btnWidth, CONFERENCE_BAR_HEIGHT)];
        [_bottomBarView addSubview:self.moreButton];
        
        [self.view addSubview:_bottomBarView];
    }
    return _bottomBarView;
}

- (void)onReceiveMessages:(NSNotification *)notification {
    NSArray<WFCCMessage *> *messages = notification.object;
    [self append:messages];
}

- (void)onMessageSent:(NSNotification *)notification {
    WFCCMessage *message = notification.userInfo[@"message"];
    [self append:@[message]];
}

- (void)onLocalMuteStateChanged:(id)sender {
    [self rearrangeParticipants];
    [self reloadParticipantCollectionView];
    
    [self updateAudioButton];
    [self updateVideoButton];
}

- (void)append:(NSArray<WFCCMessage *> *)messages {
    [messages enumerateObjectsUsingBlock:^(WFCCMessage * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if(obj.messageId != 0 && obj.conversation.type == Chatroom_Type && [obj.conversation.target isEqualToString:self.currentSession.callId]) {
            __block BOOL alreadyExist = NO;
            [self.messages enumerateObjectsUsingBlock:^(WFCCMessage * _Nonnull obj2, NSUInteger idx, BOOL * _Nonnull stop) {
                if(obj2.messageUid == obj.messageUid) {
                    alreadyExist = YES;
                    *stop = YES;
                }
            }];
            if(!alreadyExist) {
                [self.messages addObject:obj];
            }
        }
    }];
    
    if(!self.messages.count) {
        return;
    }
    
    NSMutableArray *expired = [[NSMutableArray alloc] init];
    int64_t now = [[[NSDate alloc] init] timeIntervalSince1970]*1000;
    [self.messages enumerateObjectsUsingBlock:^(WFCCMessage * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if(now - obj.serverTime + [WFCCNetworkService sharedInstance].serverDeltaTime > 30000) {
            [expired addObject:obj];
        }
    }];
    [self.messages removeObjectsInArray:expired];
    [self.messageTableView reloadData];
    if(self.messages.count) {
        [self.messageTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.messages.count-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
    }
    
    [self resizeMessageTable];
}

- (void)removeOldMessageAndShow {
    if(!self.messages.count) {
        return;
    }
    
    NSMutableArray *expiredMsgs = [[NSMutableArray alloc] init];
    NSMutableArray *expiredItems = [[NSMutableArray alloc] init];
    int64_t now = [[[NSDate alloc] init] timeIntervalSince1970]*1000;
    for (int i = 0; i < self.messages.count; i++) {
        WFCCMessage *obj = self.messages[i];
        if(now - obj.serverTime + [WFCCNetworkService sharedInstance].serverDeltaTime > 30000) {
            [expiredMsgs addObject:obj];
            [expiredItems addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        }
    }
    [self.messages removeObjectsInArray:expiredMsgs];
    [self.messageTableView deleteRowsAtIndexPaths:expiredItems withRowAnimation:UITableViewRowAnimationNone];
    
    [self resizeMessageTable];
}

- (void)resizeMessageTable {
    CGSize size = self.messageTableView.contentSize;
    if(size.height > 200) {
        size.height = 200;
    }
    
    BOOL landscape = [UIDevice currentDevice].orientation == UIInterfaceOrientationLandscapeLeft || [UIDevice currentDevice].orientation == UIInterfaceOrientationLandscapeRight;
    self.messageTableView.frame = CGRectMake(0, self.view.bounds.size.height - (landscape ? 0 :[WFCUUtilities wf_safeDistanceBottom]) - CONFERENCE_BAR_HEIGHT - 16 - 20 - size.height, 200, size.height);
}

- (void)sendTextMessage:(NSString *)text {
    WFCCMessage *msg = [[WFCCIMService sharedWFCIMService] send:[WFCCConversation conversationWithType:Chatroom_Type target:self.currentSession.callId line:0] content:[WFCCTextMessageContent contentWith:text] success:^(long long messageUid, long long timestamp) {
        
    } error:^(int error_code) {
        
    }];
    
    [self append:@[msg]];
}

- (UIView *)inputContainer {
    if(!_inputContainer) {
        CGRect bound = self.view.bounds;
        _inputContainer = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - [WFCUUtilities wf_safeDistanceBottom] - CONFERENCE_BAR_HEIGHT - 28 - 68 + 24, bound.size.width, 40)];
        _inputContainer.backgroundColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:0.3];
        _inputContainer.hidden = YES;
        [self.view addSubview:_inputContainer];
    }
    return _inputContainer;
}

- (UITextField *)inputTextField {
    if(!_inputTextField) {
        _inputTextField = [[UITextField alloc] initWithFrame:CGRectMake(8, 8, self.view.bounds.size.width - 16, 40 - 16)];
        _inputTextField.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.5];
        _inputTextField.returnKeyType = UIReturnKeyDone;
        _inputTextField.delegate = self;
        [self.inputContainer addSubview:_inputTextField];
    }
    return _inputTextField;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    self.inputTextField.returnKeyType = UIReturnKeyDone;
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *str = [textField.text stringByReplacingCharactersInRange:range withString:string];
    if(str.length) {
        if(self.inputTextField.returnKeyType != UIReturnKeySend) {
            self.inputTextField.returnKeyType = UIReturnKeySend;
            [textField reloadInputViews];
        }
    } else {
        if(self.inputTextField.returnKeyType != UIReturnKeyDone) {
            self.inputTextField.returnKeyType = UIReturnKeyDone;
            [textField reloadInputViews];
        }
    }
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if(self.inputTextField.text.length) {
        [self sendTextMessage:self.inputTextField.text];
        self.inputTextField.text = nil;
    }
    [self.inputTextField resignFirstResponder];
    [self startHidePanelTimer];
    
    return NO;
}

- (void)showInput {
    [self startHidePanelTimer];
    self.inputContainer.hidden = NO;
    [self.inputTextField becomeFirstResponder];
}

- (void)startConnectedTimer {
    [self stopConnectedTimer];
    self.connectedTimer = [NSTimer scheduledTimerWithTimeInterval:1
                                                           target:self
                                                         selector:@selector(updateConnectedTimeLabel)
                                                         userInfo:nil
                                                          repeats:YES];
    [self.connectedTimer fire];
}

- (void)stopConnectedTimer {
    if (self.connectedTimer) {
        [self.connectedTimer invalidate];
        self.connectedTimer = nil;
    }
}

- (void)updateConnectedTimeLabel {
    long sec = [[NSDate date] timeIntervalSince1970] - (self.currentSession.connectedTime+500) / 1000;
    if(sec <0) {
        sec = 0;
    }
    
    if (sec < 60 * 60) {
        self.connectTimeLabel.text = [NSString stringWithFormat:@"%02ld:%02ld", sec / 60, sec % 60];
    } else {
        self.connectTimeLabel.text = [NSString stringWithFormat:@"%02ld:%02ld:%02ld", sec / 60 / 60, (sec / 60) % 60, sec % 60];
    }
}

- (void)moreButtonDidTap:(UIButton *)button {
    __weak typeof(self)ws = self;
    
    [self startHidePanelTimer];
    NSArray<MoreItem *> *boardItems;
    MoreItem *inviteItem = [[MoreItem alloc] initWithTitle:WFCString(@"Invite") image:[WFCUImage imageNamed:@"conference_invite"] callback:^MoreItem * _Nonnull{
        WFCUConferenceInviteViewController *pvc = [[WFCUConferenceInviteViewController alloc] init];
        
        WFCCConferenceInviteMessageContent *invite = [[WFCCConferenceInviteMessageContent alloc] init];
        WFAVCallSession *currentSession = [WFAVEngineKit sharedEngineKit].currentSession;
        invite.callId = currentSession.callId;
        invite.pin = currentSession.pin;
        invite.audioOnly = currentSession.audioOnly;
        invite.host = currentSession.host;
        invite.title = currentSession.title;
        invite.desc = currentSession.desc;
        invite.audience = currentSession.defaultAudience;
        invite.advanced = currentSession.isAdvanced;
        invite.password = ws.conferenceInfo.password;
        
        pvc.invite = invite;
        UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:pvc];
        [ws presentViewController:navi animated:YES completion:nil];
        return nil;
    }];
    
    MoreItem *chatItem = [[MoreItem alloc] initWithTitle:WFCString(@"Chat") image:[WFCUImage imageNamed:@"conference_chat"] callback:^MoreItem * _Nonnull{
        WFCUMessageListViewController *mvc = [[WFCUMessageListViewController alloc] init];
        mvc.conversation = [WFCCConversation conversationWithType:Chatroom_Type target:ws.currentSession.callId line:0];
        mvc.keepInChatroom = YES;
        mvc.silentJoinChatroom = YES;
        mvc.presented = YES;
        
        mvc.hidesBottomBarWhenPushed = YES;
        UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:mvc];
        navi.modalPresentationStyle = UIModalPresentationFullScreen;
        [ws presentViewController:navi animated:YES completion:nil];
        return nil;
    }];
    
    MoreItem *minimizeItem = [[MoreItem alloc] initWithTitle:WFCString(@"Floating") image:[WFCUImage imageNamed:@"conference_minimize"] callback:^MoreItem * _Nonnull {
        [ws minimize];
        return nil;
    }];
    
    MoreItem *recordItem = [WFCUConferenceManager sharedInstance].currentConferenceInfo.recording ?
    [[MoreItem alloc] initWithTitle:WFCString(@"CancelRecord") image:[WFCUImage imageNamed:@"conference_recording"] callback:^MoreItem * _Nonnull {
        if(![ws.conferenceInfo.owner isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
            [ws showCommandToast:@"请联系主持人取消录制"];
            return nil;
        }
        [[WFCUConferenceManager sharedInstance] requestRecording:NO];
        return nil;
    }]
    :
    [[MoreItem alloc] initWithTitle:WFCString(@"Record") image:[WFCUImage imageNamed:@"conference_record"] callback:^MoreItem * _Nonnull {
        if(![ws.conferenceInfo.owner isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
            [ws showCommandToast:@"请联系主持人录制"];
            return nil;
        }
        [[WFCUConferenceManager sharedInstance] requestRecording:YES];
        return nil;
    }];
    
    MoreItem *settingItem = [[MoreItem alloc] initWithTitle:WFCString(@"Setting") image:[WFCUImage imageNamed:@"conference_setting"] callback:^MoreItem * _Nonnull {
        return nil;
    }];
    
    MoreItem *handupItem = [WFCUConferenceManager sharedInstance].isHandup ?
    [[MoreItem alloc] initWithTitle:WFCString(@"PutDown") image:[WFCUImage imageNamed:@"conference_handup_hover"] callback:^MoreItem * _Nonnull{
        [[WFCUConferenceManager sharedInstance] handup:NO];
        [ws showCommandToast:@"已放下举手"];
        return nil;
    }]
    :
    [[MoreItem alloc] initWithTitle:WFCString(@"Handup") image:[WFCUImage imageNamed:@"conference_handup"] callback:^MoreItem * _Nonnull{
        [[WFCUConferenceManager sharedInstance] handup:YES];
        [ws showCommandToast:@"已举手，等待管理员处理"];
        return nil;
    }];
    
    if([self.conferenceInfo.owner isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
        boardItems = @[inviteItem, chatItem, minimizeItem, recordItem, settingItem];
    } else {
        boardItems = @[inviteItem, chatItem, handupItem, minimizeItem, recordItem, settingItem];
    }
    
    self.boardView = [[WFCUMoreBoardView alloc] initWithWidth:self.view.bounds.size.width
                                                        items:boardItems
                                                       cancel:^(WFCUMoreBoardView * _Nonnull boardView) {
        [UIView animateWithDuration:0.5 animations:^{
            CGRect boardFrame = boardView.frame;
            boardFrame.origin.y = ws.view.bounds.size.height;
            boardView.frame = boardFrame;
        } completion:^(BOOL finished) {
            [boardView removeFromSuperview];
        }];
    }];
    
    CGRect boardFrame = self.boardView.frame;
    boardFrame.origin.y = self.view.bounds.size.height;
    self.boardView.frame = boardFrame;
    [self.view addSubview:self.boardView];
    
    [UIView animateWithDuration:0.5 animations:^{
        CGRect frame = ws.boardView.frame;
        frame.origin.y = ws.view.bounds.size.height - [WFCUUtilities wf_safeDistanceBottom] - boardFrame.size.height;
        ws.boardView.frame = frame;
    }];
}

- (void)hanupButtonDidTap:(UIButton *)button {
    if([self.currentSession.host isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
        __weak typeof(self)ws = self;
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:@"如果您想让与会人员继续开会，请选择退出会议" preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *action1 = [UIAlertAction actionWithTitle:WFCString(@"QuitConference") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            [[WFCUConferenceManager sharedInstance] leaveConference:NO];
        }];
        [alertController addAction:action1];
        
        UIAlertAction *action2 = [UIAlertAction actionWithTitle:WFCString(@"DestroyConference") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            [[WFCUConferenceManager sharedInstance] leaveConference:YES];
        }];
        [alertController addAction:action2];
        
        [ws presentViewController:alertController animated:YES completion:nil];
    } else {
        [[WFCUConferenceManager sharedInstance] leaveConference:NO];
    }
}


- (void)managerButtonDidTap:(UIButton *)button {
    WFCUConferenceMemberManagerViewController *vc = [[WFCUConferenceMemberManagerViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)onBroadcastingStatusUpdated:(NSNotification *)notification {
    [self updateScreenSharingButton];
    [self reloadParticipantCollectionView];
}

- (void)unsubscribeAllVideoStream {
    [self.participants enumerateObjectsUsingBlock:^(WFAVParticipantProfile * _Nonnull profile, NSUInteger idx, BOOL * _Nonnull stop) {
        if(![profile.userId isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
            [self.currentSession setParticipant:profile.userId screenSharing:profile.screeSharing videoType:WFAVVideoType_None];
        }
    }];
}

- (void)showAlert {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"警告" message:@"屏幕共享功能有可能泄漏您的隐私，已经有多个诈骗案例使用屏幕共享进行远程遥控诈骗。此功能野火测试环境上已经被关闭，私有部署的环境会开放此功能。" preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        
    }];
    [alertController addAction:action1];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)screenSharingButtonDidTap:(UIButton *)button {
#if DISABLE_SCREEN_SHARING
    [self showAlert];
#else
    if([[WFCUConferenceManager sharedInstance] isBroadcasting]) {
        [[WFCUConferenceManager sharedInstance] stopScreansharing];
    } else {
        [[WFCUConferenceManager sharedInstance] startScreansharing:self.view withAudio:YES];
    }
#endif
}

- (void)updateScreenSharingButton {
    self.screenSharingButton.selected = self.currentSession.isBroadcasting;
    if([WFAVEngineKit sharedEngineKit].screenSharingReplaceMode) {
        self.videoButton.enabled = !self.currentSession.isBroadcasting;
    }
}

- (void)minimize {
    __block WFAVParticipantProfile *focusUser = self.focusUserProfile;
    [WFCUFloatingWindow startCallFloatingWindow:self.currentSession focusUser:focusUser withTouchedBlock:^(WFAVCallSession *callSession, WFZConferenceInfo *conferenceInfo) {
        WFCUConferenceViewController *vc = [[WFCUConferenceViewController alloc] initWithSession:callSession conferenceInfo:conferenceInfo];
        vc.focusUserProfile = focusUser;
        [[WFAVEngineKit sharedEngineKit] presentViewController:vc];
     }];
    
    [self leftVC];
}

- (void)leftVC {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self stopHidePanelTimer];
    [[WFAVEngineKit sharedEngineKit] dismissViewController:self];
}

- (void)informationButtonDidTap:(UIButton *)button {
    [self showConferenceInfoView];
    [self startHidePanelTimer];
}

- (void)switchCameraButtonDidTap:(UIButton *)button {
    if (self.currentSession.state != kWFAVEngineStateIdle) {
        [self.currentSession switchCamera];
        [self startHidePanelTimer];
    }
}

- (void)audioButtonDidTap:(UIButton *)button {
    if (self.currentSession.state != kWFAVEngineStateIdle) {
        if(!self.currentSession.isAudience && !self.currentSession.audioMuted) {
            [[WFCUConferenceManager sharedInstance] muteAudio:!(self.currentSession.audioMuted || self.currentSession.audience)];
            [self updateAudioButton];
        } else {
            if (self.conferenceInfo.allowTurnOnMic || [self.conferenceInfo.owner isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
                [[WFCUConferenceManager sharedInstance] muteAudio:!(self.currentSession.audioMuted || self.currentSession.audience)];
                [self updateAudioButton];
            } else {
                __weak typeof(self)ws = self;
                if([WFCUConferenceManager sharedInstance].isApplyingUnmuteAudio) {
                    [[WFCUConferenceManager sharedInstance] presentCommandAlertView:self message:@"您正在申请解除静音" actionTitle:@"继续申请" cancelTitle:@"取消申请" contentText:@"主持人不允许解除静音，您已经申请解除静音，正在等待主持人操作" checkBox:NO actionHandler:^(BOOL checked) {
                        [[WFCUConferenceManager sharedInstance] applyUnmute:NO isAudio:YES];
                        [ws showCommandToast:@"已重新发送申请，请耐心等待主持人操作"];
                    } cancelHandler:^{
                        [[WFCUConferenceManager sharedInstance] applyUnmute:YES isAudio:YES];
                        [ws showCommandToast:@"已取消申请"];
                    }];
                } else {
                    [[WFCUConferenceManager sharedInstance] presentCommandAlertView:self message:@"你已静音" actionTitle:@"申请解除静音" cancelTitle:nil contentText:@"主持人不允许解除静音，您可以向主持人申请解除静音" checkBox:NO actionHandler:^(BOOL checked) {
                        [[WFCUConferenceManager sharedInstance] applyUnmute:NO isAudio:YES];
                        [ws showCommandToast:@"已发送申请，请耐心等待主持人操作"];
                    } cancelHandler:nil];
                }
            }
        }
        
        
        if(button == self.audioButton) {
            [self startHidePanelTimer];
        }
    }
}

- (void)updateAudioButton {
    if (self.currentSession.audioMuted || self.currentSession.isAudience) {
        [self.audioButton setImage:[WFCUImage imageNamed:@"conference_audio_mute"] forState:UIControlStateNormal];
        [self.floatingAudioButton setImage:[WFCUImage imageNamed:@"conference_audio_mute"] forState:UIControlStateNormal];
    } else {
        [self.audioButton setImage:[WFCUImage imageNamed:@"conference_audio"] forState:UIControlStateNormal];
        [self.floatingAudioButton setImage:[WFCUImage imageNamed:@"conference_audio"] forState:UIControlStateNormal];
    }
}

- (void)speakerButtonDidTap:(UIButton *)button {
    if (self.currentSession.state != kWFAVEngineStateIdle) {
        [self.currentSession enableSpeaker:!self.currentSession.isSpeaker];
        [self updateSpeakerButton];
        [self startHidePanelTimer];
    }
}

- (void)updateSpeakerButton {
    if (!self.currentSession.isSpeaker) {
        if([self.currentSession isHeadsetPluggedIn]) {
            [self.speakerButton setImage:[WFCUImage imageNamed:@"conference_speaker_headset"] forState:UIControlStateNormal];
        } else if([self.currentSession isBluetoothSpeaker]) {
            [self.speakerButton setImage:[WFCUImage imageNamed:@"conference_speaker_bluetooth"] forState:UIControlStateNormal];
        } else {
            [self.speakerButton setImage:[WFCUImage imageNamed:@"conference_speaker_hover"] forState:UIControlStateNormal];
        }
    } else {
        [self.speakerButton setImage:[WFCUImage imageNamed:@"conference_speaker"] forState:UIControlStateNormal];
    }
}

- (void)updateVideoButton {
    if (self.currentSession.videoMuted || self.currentSession.isAudience) {
        [self.videoButton setImage:[WFCUImage imageNamed:@"conference_video_mute"] forState:UIControlStateNormal];
        self.switchCameraButton.hidden = YES;
    } else {
        [self.videoButton setImage:[WFCUImage imageNamed:@"conference_video"] forState:UIControlStateNormal];
        self.switchCameraButton.hidden = NO;
    }
}

//1.决定当前界面是否开启自动转屏，如果返回NO，后面两个方法也不会被调用，只是会支持默认的方向
- (BOOL)shouldAutorotate {
      return YES;
}

//2.返回支持的旋转方向
//iPad设备上，默认返回值UIInterfaceOrientationMaskAllButUpSideDwon
//iPad设备上，默认返回值是UIInterfaceOrientationMaskAll
- (UIInterfaceOrientationMask)supportedInterfaceOrientations{
    if(self.lockButton.selected) {
        if(self.currentOrientation == UIInterfaceOrientationLandscapeLeft) {
            return UIInterfaceOrientationMaskLandscapeLeft;
        } else if(self.currentOrientation == UIInterfaceOrientationPortrait) {
            return UIInterfaceOrientationMaskPortrait;
        } else if(self.currentOrientation == UIInterfaceOrientationLandscapeRight) {
            return UIInterfaceOrientationMaskLandscapeRight;
        } else {
            return UIInterfaceOrientationMaskPortrait;
        }
    }
    return UIInterfaceOrientationMaskAll;
}

//3.返回进入界面默认显示方向
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
     return UIInterfaceOrientationPortrait;
}

- (void)updateUIByOrientationChanged:(BOOL)landscape {
    CGRect bounds = self.view.bounds;
    if(landscape) {
        self.smallVideoView.frame = CGRectMake(0, CONFERENCE_BAR_HEIGHT, SmallVideoView* 4 /3, SmallVideoView);
        self.participantCollectionView.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
    } else {
        self.smallVideoView.frame = CGRectMake(0, CONFERENCE_BAR_HEIGHT, SmallVideoView, SmallVideoView * 4 /3);
        self.participantCollectionView.frame = CGRectMake(0, [WFCUUtilities wf_statusBarHeight], self.view.bounds.size.width, self.view.bounds.size.height- [WFCUUtilities wf_statusBarHeight] - [WFCUUtilities wf_safeDistanceBottom]);
    }
    
    self.floatingAudioButton.frame = CGRectMake((bounds.size.width - FLOATING_AUDIO_BUTTON_SIZE)/2, bounds.size.height - (landscape ? 0 : [WFCUUtilities wf_safeDistanceBottom]) - FLOATING_AUDIO_BUTTON_SIZE - CONFERENCE_BAR_HEIGHT, FLOATING_AUDIO_BUTTON_SIZE, FLOATING_AUDIO_BUTTON_SIZE);
    
    [self updateTopBarViewFrame:landscape];
    [self updatebottomBarViewFrame:landscape];
    [self reloadParticipantCollectionView];
    
    [self resizeMessageTable];
    self.chatButton.frame = CGRectMake(8, bounds.size.height - (landscape ? 0 : [WFCUUtilities wf_safeDistanceBottom]) - CONFERENCE_BAR_HEIGHT - 16 - 20, 80, 20);
    self.rotateButton.frame = CGRectMake(bounds.size.width - 30 - 8, bounds.size.height - (landscape ? 0 : [WFCUUtilities wf_safeDistanceBottom]) - CONFERENCE_BAR_HEIGHT - 16 - 30 + 3, 30, 30);
    self.lockButton.frame = CGRectMake(bounds.size.width - 30 - 8 - 30 - 8, bounds.size.height - (landscape ? 0 : [WFCUUtilities wf_safeDistanceBottom]) - CONFERENCE_BAR_HEIGHT - 16 - 30 + 3, 30, 30);
    if(landscape) {
        [self.inputTextField resignFirstResponder];
    }
    [self.boardView removeFromSuperview];
    self.pageControl.frame = CGRectMake(self.view.bounds.size.width/2-100, self.view.bounds.size.height - (landscape ? 0 : [WFCUUtilities wf_safeDistanceBottom]) - 20, 200, 20);
}

- (BOOL)onDeviceOrientationDidChange{
    UIDevice *device = [UIDevice currentDevice] ;
    UIInterfaceOrientation orientation = UIInterfaceOrientationUnknown;
    switch (device.orientation) {
        case UIDeviceOrientationLandscapeLeft:
            orientation = UIInterfaceOrientationLandscapeRight;
            break;
        case UIDeviceOrientationLandscapeRight:
            orientation = UIInterfaceOrientationLandscapeLeft;
            break;
        case UIDeviceOrientationPortrait:
        default:
            orientation = UIInterfaceOrientationPortrait;
            break;
    }
    
    [self rotateUI:orientation];
    [self updateUIByOrientationChanged:orientation != UIInterfaceOrientationPortrait];
    return YES;
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self reloadVideoUI];
    if (_currentSession.state == kWFAVEngineStateConnected) {
        [self updateConnectedTimeLabel];
        [self startConnectedTimer];
        [self updateAudioButton];
        [self updateVideoButton];
        [self updateSpeakerButton];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self stopConnectedTimer];
}

- (void)setPanStartPoint:(CGPoint)panStartPoint {
    _panStartPoint = panStartPoint;
    _panStartVideoFrame = self.smallVideoView.frame;
}

- (void)moveToPanPoint:(CGPoint)panPoint {
    CGRect frame = self.panStartVideoFrame;
    CGSize moveSize = CGSizeMake(panPoint.x - self.panStartPoint.x, panPoint.y - self.panStartPoint.y);
    
    frame.origin.x += moveSize.width;
    frame.origin.y += moveSize.height;
    self.smallVideoView.frame = frame;
}

- (void)onSmallVideoPan:(UIPanGestureRecognizer *)recognize {
    switch (recognize.state) {
        case UIGestureRecognizerStateBegan:
            self.panStartPoint = [recognize translationInView:self.view];
            break;
        case UIGestureRecognizerStateChanged: {
            CGPoint currentPoint = [recognize translationInView:self.view];
            [self moveToPanPoint:currentPoint];
            break;
        }
        case UIGestureRecognizerStateEnded: {
            CGPoint endPoint = [recognize translationInView:self.view];
            [self moveToPanPoint:endPoint];
            break;
        }
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
        default:
            break;
        }
}

- (void)onSmallVideoTaped:(id)sender {
    if (self.currentSession.state == kWFAVEngineStateConnected) {
//        self.swapVideoView = !_swapVideoView;
    }
}

- (void)videoButtonDidTap:(UIButton *)button {
    if (self.currentSession.state != kWFAVEngineStateIdle) {
        if(!self.currentSession.isAudience && !self.currentSession.videoMuted) {
            [[WFCUConferenceManager sharedInstance] muteVideo:!(self.currentSession.audience || self.currentSession.videoMuted)];
            [self updateVideoButton];
        } else {
            if (self.conferenceInfo.allowTurnOnMic || [self.conferenceInfo.owner isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
                [[WFCUConferenceManager sharedInstance] muteVideo:!(self.currentSession.audience || self.currentSession.videoMuted)];
                [self updateVideoButton];
            } else {
                __weak typeof(self)ws = self;
                if([WFCUConferenceManager sharedInstance].isApplyingUnmuteVideo) {
                    [[WFCUConferenceManager sharedInstance] presentCommandAlertView:self message:@"主持人不允许开启摄像头，您已经申请开启，正在等待主持人允许" actionTitle:@"继续申请" cancelTitle:@"取消申请" contentText:nil checkBox:NO actionHandler:^(BOOL checked) {
                        [[WFCUConferenceManager sharedInstance] applyUnmute:NO isAudio:NO];
                        [ws showCommandToast:@"已重新发送申请，请耐心等待主持人操作"];
                    } cancelHandler:^{
                        [[WFCUConferenceManager sharedInstance] applyUnmute:YES isAudio:NO];
                        [ws showCommandToast:@"已取消申请"];
                    }];
                } else {
                    [[WFCUConferenceManager sharedInstance] presentCommandAlertView:self message:@"你已关闭摄像头" actionTitle:@"申请开启" cancelTitle:nil contentText:@"主持人不允许开启摄像头，您可以向主持人申请开启" checkBox:NO actionHandler:^(BOOL checked) {
                        [[WFCUConferenceManager sharedInstance] applyUnmute:NO isAudio:NO];
                        [ws showCommandToast:@"已发送申请，请耐心等待主持人操作"];
                    } cancelHandler:nil];
                }
            }
        }
    }
    [self startHidePanelTimer];
}

- (void)chatButtonDidTap:(UIButton *)button {
    [self showInput];
}

- (void)rotateButtonDidTap:(UIButton *)button {
    UIInterfaceOrientation orientation = self.view.bounds.size.width > self.view.bounds.size.height ? UIInterfaceOrientationPortrait : UIInterfaceOrientationLandscapeRight;
    if(self.lockButton.selected) {
        self.currentOrientation = orientation;
    }
    [self rotateUI:orientation];
}

- (void)lockButtonDidTap:(UIButton *)button {
    self.lockButton.selected = !self.lockButton.selected;
    if (@available(iOS 16, *)) {
        [self setNeedsUpdateOfSupportedInterfaceOrientations];
    }
}

- (void)showConferenceInfoView {
    CGRect bounds = self.view.bounds;
    self.conferenceInfoView = [[UIView alloc] initWithFrame:bounds];
    self.conferenceInfoView.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.5];
    self.conferenceInfoView.userInteractionEnabled = YES;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hiddenConferenceInfoView)];
    [self.conferenceInfoView addGestureRecognizer:tap];
    [self.view addSubview:self.conferenceInfoView];
    [self.view bringSubviewToFront:self.conferenceInfoView];
    
    UIView *panel = [[UIView alloc] initWithFrame:CGRectZero];
    panel.backgroundColor = [UIColor whiteColor];
    
    CGFloat offset = 40;
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, offset, 200, 18)];
    titleLabel.font = [UIFont boldSystemFontOfSize:16];
    titleLabel.text = self.conferenceInfo.conferenceTitle;
    [panel addSubview:titleLabel];
    offset += 8;
    
    CGFloat copyBtnWidth = 14;
    CGFloat titleWidth = 64;
    CGFloat blockOffset = 24;
    
    
    offset += blockOffset;
    UILabel *numberTitle = [[UILabel alloc] initWithFrame:CGRectMake(16, offset, titleWidth, 14)];
    numberTitle.font = [UIFont systemFontOfSize:12];
    numberTitle.textColor = [UIColor grayColor];
    numberTitle.text = @"会议号";
    UILabel *numberLabel = [[UILabel alloc] initWithFrame:CGRectMake(titleWidth + 16, offset, bounds.size.width-titleWidth - 16 - 16 - copyBtnWidth - 8, 14)];
    numberLabel.font = [UIFont systemFontOfSize:12];
    numberLabel.text = self.conferenceInfo.conferenceId;
    UIButton *numberCopyBtn = [[UIButton alloc] initWithFrame:CGRectMake(bounds.size.width - copyBtnWidth - 16, offset, copyBtnWidth, copyBtnWidth)];
    [numberCopyBtn setImage:[WFCUImage imageNamed:@"copy"] forState:UIControlStateNormal];
    [numberCopyBtn addTarget:self action:@selector(onCopy:) forControlEvents:UIControlEventTouchUpInside];
    numberCopyBtn.tag = 1;
    [panel addSubview:numberTitle];
    [panel addSubview:numberLabel];
    [panel addSubview:numberCopyBtn];
    
    if(self.conferenceInfo.password.length) {
        offset += blockOffset;
        UILabel *pwdTitle = [[UILabel alloc] initWithFrame:CGRectMake(16, offset, titleWidth, 14)];
        pwdTitle.font = [UIFont systemFontOfSize:12];
        pwdTitle.textColor = [UIColor grayColor];
        pwdTitle.text = @"会议密码";
        UILabel *pwdLabel = [[UILabel alloc] initWithFrame:CGRectMake(titleWidth + 16, offset, bounds.size.width-titleWidth - 16 - 16 - copyBtnWidth - 8, 14)];
        pwdLabel.font = [UIFont systemFontOfSize:12];
        pwdLabel.text = self.conferenceInfo.password;
        UIButton *pwdCopyBtn = [[UIButton alloc] initWithFrame:CGRectMake(bounds.size.width - copyBtnWidth - 16, offset, copyBtnWidth, copyBtnWidth)];
        [pwdCopyBtn setImage:[WFCUImage imageNamed:@"copy"] forState:UIControlStateNormal];
        [pwdCopyBtn addTarget:self action:@selector(onCopy:) forControlEvents:UIControlEventTouchUpInside];
        pwdCopyBtn.tag = 2;
        [panel addSubview:pwdTitle];
        [panel addSubview:pwdLabel];
        [panel addSubview:pwdCopyBtn];
    }
    
    offset += blockOffset;
    UILabel *ownerTitle = [[UILabel alloc] initWithFrame:CGRectMake(16, offset, titleWidth, 14)];
    ownerTitle.font = [UIFont systemFontOfSize:12];
    ownerTitle.textColor = [UIColor grayColor];
    ownerTitle.text = @"主持人";
    UILabel *ownerLabel = [[UILabel alloc] initWithFrame:CGRectMake(titleWidth + 16, offset, bounds.size.width-titleWidth - 16 -16, 14)];
    ownerLabel.font = [UIFont systemFontOfSize:12];
    WFCCUserInfo *owner = [[WFCCIMService sharedWFCIMService] getUserInfo:self.conferenceInfo.owner refresh:NO];
    ownerLabel.text = owner.displayName;
    [panel addSubview:ownerTitle];
    [panel addSubview:ownerLabel];
    
    offset += blockOffset;
    UILabel *linkTitle = [[UILabel alloc] initWithFrame:CGRectMake(16, offset, titleWidth, 14)];
    linkTitle.font = [UIFont systemFontOfSize:12];
    linkTitle.textColor = [UIColor grayColor];
    linkTitle.text = @"会议链接";
    UILabel *linkLabel = [[UILabel alloc] initWithFrame:CGRectMake(titleWidth + 16, offset, bounds.size.width-titleWidth - 16 - 16 - copyBtnWidth - 8, 14)];
    linkLabel.font = [UIFont systemFontOfSize:12];
    linkLabel.text = [self conferenceLink];
    UIButton *linkCopyBtn = [[UIButton alloc] initWithFrame:CGRectMake(bounds.size.width - copyBtnWidth - 16, offset, copyBtnWidth, copyBtnWidth)];
    [linkCopyBtn setImage:[WFCUImage imageNamed:@"copy"] forState:UIControlStateNormal];
    [linkCopyBtn addTarget:self action:@selector(onCopy:) forControlEvents:UIControlEventTouchUpInside];
    linkCopyBtn.tag = 3;
    [panel addSubview:linkTitle];
    [panel addSubview:linkLabel];
    [panel addSubview:linkCopyBtn];
    
    offset += 40;
    offset += [WFCUUtilities wf_safeDistanceBottom];
    panel.layer.cornerRadius = 10.f;
    panel.clipsToBounds = YES;
    
    [self.conferenceInfoView addSubview:panel];
    panel.frame = CGRectMake(0, bounds.size.height, bounds.size.width, offset+10);
    [UIView animateWithDuration:0.2 animations:^{
        panel.frame = CGRectMake(0, bounds.size.height - offset, bounds.size.width, offset+10);
    }];
}

- (void)rotateUI:(UIInterfaceOrientation)orientation {
    self.currentOrientation = orientation;
    __weak typeof(self)ws = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (@available(iOS 16, *)) {
            UIWindowScene *scene = (UIWindowScene *)[[[UIApplication sharedApplication].connectedScenes allObjects] firstObject];
            UIWindowSceneGeometryPreferencesIOS *preferences = [[UIWindowSceneGeometryPreferencesIOS alloc] init];
            preferences.interfaceOrientations = UIInterfaceOrientationMaskPortrait;
            if(orientation == UIInterfaceOrientationLandscapeLeft) {
                preferences.interfaceOrientations = UIInterfaceOrientationMaskLandscapeLeft;
            } else if(orientation == UIInterfaceOrientationLandscapeRight) {
                preferences.interfaceOrientations = UIInterfaceOrientationMaskLandscapeRight;
            }
            
            [ws setNeedsUpdateOfSupportedInterfaceOrientations];
            [scene requestGeometryUpdateWithPreferences:preferences errorHandler:^(NSError * _Nonnull error) {
                NSLog(@"Unsupport orientations");
            }];
        } else {
            [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger:orientation] forKey:@"orientation"];
        }
    });
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    dispatch_async(dispatch_get_main_queue(), ^{
        if(!self.rotateButton.selected) {
            self.currentOrientation = [[[UIDevice currentDevice] valueForKey:@"orientation"] intValue];
        }
        [self updateUIByOrientationChanged:size.width>size.height];
        [self reloadVideoUI];
    });
}

- (void)onCopy:(id)sender {
    UIButton *btn = (UIButton *)sender;
    NSString *text;
    if(btn.tag == 1) {
        text = self.conferenceInfo.conferenceId;
    } else if(btn.tag == 2) {
        text = self.conferenceInfo.password;
    } else {
        text = [self conferenceLink];
    }
    
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = text;
    [self.view makeToast:@"已拷贝到剪贴板！" duration:1 position:CSToastPositionCenter];
}

- (NSString *)conferenceLink {
    return [[WFCUConferenceManager sharedInstance] linkFromConferenceId:self.conferenceInfo.conferenceId password:self.conferenceInfo.password];
}

- (void)hiddenConferenceInfoView {
    [self.conferenceInfoView removeFromSuperview];
    self.conferenceInfoView = nil;
}


- (void)updatePortraitAndStateViewFrame {
        CGFloat containerWidth = self.view.bounds.size.width;
        
        self.portraitView.frame = CGRectMake((containerWidth-64)/2, [WFCUUtilities wf_navigationFullHeight], 64, 64);;
        
        self.userNameLabel.frame = CGRectMake((containerWidth - 240)/2, [WFCUUtilities wf_navigationFullHeight] + 64 + 8, 240, 26);
        self.userNameLabel.textAlignment = NSTextAlignmentCenter;
            
        self.stateLabel.frame = CGRectMake((containerWidth - 240)/2, self.participantCollectionView.frame.origin.y + self.participantCollectionView.frame.size.height - 130, 240, 16);
        self.stateLabel.textAlignment = NSTextAlignmentCenter;
}

- (void)onClickedBigVideoView:(id)sender {
    if([self.inputTextField isFirstResponder]) {
        [self.inputTextField resignFirstResponder];
        return;
    }
    
    if (self.currentSession.state != kWFAVEngineStateConnected) {
        return;
    }
    
    if (self.currentSession.audioOnly) {
        return;
    }
    
    if (self.bottomBarView.hidden) {
        [self showPanel];
    } else {
        [self hidePanel];
    }
    
    [self.boardView dismiss];
}

- (void)showPanel {
    if(!self.boardView.hidden && !self.topBarView.hidden) {
        return;
    }
    
    self.floatingAudioButton.hidden = YES;
    CGRect bounds = self.view.bounds;
    BOOL landscape = bounds.size.width > bounds.size.height;
    CGRect floatingAudioBtnFrame = CGRectMake((bounds.size.width - FLOATING_AUDIO_BUTTON_SIZE)/2, bounds.size.height - (landscape ? 0 : [WFCUUtilities wf_safeDistanceBottom]) - FLOATING_AUDIO_BUTTON_SIZE - CONFERENCE_BAR_HEIGHT, FLOATING_AUDIO_BUTTON_SIZE, FLOATING_AUDIO_BUTTON_SIZE);
    floatingAudioBtnFrame.origin.y = self.view.bounds.size.height;
    self.floatingAudioButton.frame = floatingAudioBtnFrame;
    
    CGFloat previousBottomBarHeigh = landscape ? CONFERENCE_BAR_HEIGHT : CONFERENCE_BAR_HEIGHT+[WFCUUtilities wf_safeDistanceBottom];
    self.bottomBarView.frame = CGRectMake(0, self.view.bounds.size.height, self.view.bounds.size.width, previousBottomBarHeigh);
    
    self.bottomBarView.hidden = NO;
    self.topBarView.hidden = NO;
    
    [UIView animateWithDuration:0.5 animations:^{
        CGFloat bottomBarHeigh = landscape ? CONFERENCE_BAR_HEIGHT : CONFERENCE_BAR_HEIGHT+[WFCUUtilities wf_safeDistanceBottom];
        self.bottomBarView.frame = CGRectMake(0, self.view.bounds.size.height - bottomBarHeigh, self.view.bounds.size.width, bottomBarHeigh);
        
        self.topBarView.frame = CGRectMake(0, 0, self.view.bounds.size.width, landscape ? CONFERENCE_TOP_BAR_WIDTH : [WFCUUtilities wf_statusBarHeight] + CONFERENCE_TOP_BAR_WIDTH);
        
        CGRect smallVideoRect = self.smallVideoView.frame;
        if(smallVideoRect.origin.y < CONFERENCE_TOP_BAR_WIDTH) {
            smallVideoRect.origin.y = CONFERENCE_TOP_BAR_WIDTH;
        }
        
        if(smallVideoRect.origin.y + smallVideoRect.size.height > self.view.bounds.size.height - bottomBarHeigh) {
            smallVideoRect.origin.y = self.view.bounds.size.height - bottomBarHeigh - smallVideoRect.size.height;
        }
        self.smallVideoView.frame = smallVideoRect;
        self.chatButton.hidden = NO;
        self.rotateButton.hidden = NO;
        self.lockButton.hidden = NO;
    } completion:^(BOOL finished) {
        
    }];
    
    if (self.currentSession.audioOnly) {
        self.videoButton.hidden = YES;
    } else {
        self.videoButton.hidden = NO;
    }
    self.participantCollectionView.hidden = NO;
    [self startHidePanelTimer];
    [self.view bringSubviewToFront:self.bottomBarView];
    [self.view bringSubviewToFront:self.topBarView];
}

- (void)hidePanel {
    if(self.boardView.hidden && self.topBarView.hidden) {
        return;
    }
    
    BOOL landscape = [UIDevice currentDevice].orientation == UIInterfaceOrientationLandscapeLeft || [UIDevice currentDevice].orientation == UIInterfaceOrientationLandscapeRight;
    
    [UIView animateWithDuration:0.5 animations:^{
        CGFloat bottomBarHeigh = landscape ? CONFERENCE_BAR_HEIGHT : CONFERENCE_BAR_HEIGHT+[WFCUUtilities wf_safeDistanceBottom];
        self.bottomBarView.frame = CGRectMake(0, self.view.bounds.size.height, self.view.bounds.size.width, bottomBarHeigh);

        CGFloat topViewHeigh =  landscape ? CONFERENCE_TOP_BAR_WIDTH : CONFERENCE_TOP_BAR_WIDTH + [WFCUUtilities wf_statusBarHeight];
        self.topBarView.frame = CGRectMake(0, -topViewHeigh, self.view.bounds.size.width, topViewHeigh);

        CGRect smallVideoRect = self.smallVideoView.frame;
        if(smallVideoRect.origin.y == CONFERENCE_TOP_BAR_WIDTH) {
            smallVideoRect.origin.y = 0;
        }
        if(smallVideoRect.origin.y + smallVideoRect.size.height == self.view.bounds.size.height - bottomBarHeigh) {
            smallVideoRect.origin.y = self.view.bounds.size.height - (landscape ? 0 : [WFCUUtilities wf_safeDistanceBottom]) - smallVideoRect.size.height;
        }
        self.smallVideoView.frame = smallVideoRect;
        self.chatButton.hidden = YES;
        self.rotateButton.hidden = YES;
        self.lockButton.hidden = YES;
    } completion:^(BOOL finished) {
        self.bottomBarView.hidden = YES;
        self.topBarView.hidden = YES;
        self.floatingAudioButton.hidden = NO;
        [UIView animateWithDuration:0.3 animations:^{
            CGRect floatingAudioBtnFrame = self.floatingAudioButton.frame;
            floatingAudioBtnFrame.origin.y = self.view.bounds.size.height - (landscape ? 0 : [WFCUUtilities wf_safeDistanceBottom]) - FLOATING_AUDIO_BUTTON_SIZE - CONFERENCE_BAR_HEIGHT;
            self.floatingAudioButton.frame = floatingAudioBtnFrame;
        }];
    }];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    if (![self.inputTextField isFirstResponder]) {
        return;
    }
    NSDictionary *userInfo = [notification userInfo];
    NSValue *value = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardRect = [value CGRectValue];
    
    CGFloat duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    
    CGRect frame = self.inputContainer.frame;
    frame.origin.y = self.view.bounds.size.height;
    self.inputContainer.frame = frame;
    
    frame.origin.y = keyboardRect.origin.y - frame.size.height;
    [UIView animateWithDuration:duration animations:^{
        self.inputContainer.frame = frame;
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    
    CGFloat duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];

    CGRect frame = self.inputContainer.frame;
    frame.origin.y = self.view.frame.size.height - [WFCUUtilities wf_safeDistanceBottom] - CONFERENCE_BAR_HEIGHT - 28 - 68 + 20;
    [UIView animateWithDuration:duration animations:^{
        self.inputContainer.frame = frame;
        self.inputContainer.hidden = YES;
    } completion:^(BOOL finished) {
        
    }];
}

-(void)keyboardDidHide:(NSNotification *)notification{
    
}


- (void)startHidePanelTimer {
    if(self.currentSession.isAudioOnly) {
        return;
    }
    
    [self.hidePanelTimer invalidate];
    __weak typeof(self)ws = self;
    if (@available(iOS 10.0, *)) {
        self.hidePanelTimer = [NSTimer scheduledTimerWithTimeInterval:5 repeats:NO block:^(NSTimer * _Nonnull timer) {
            [ws hidePanel];
        }];
    } else {
        // Fallback on earlier versions
    }
}

- (void)stopHidePanelTimer {
    [self.hidePanelTimer invalidate];
    self.hidePanelTimer = nil;
}

#pragma mark - WFAVEngineDelegate
- (void)didChangeState:(WFAVEngineState)state {
    if (!self.viewLoaded) {
        return;
    }
    switch (state) {
        case kWFAVEngineStateIdle:
            self.topBarView.hidden = YES;
            self.bottomBarView.hidden = YES;
            self.moreButton.hidden = YES;
            self.audioButton.hidden = YES;
            self.videoButton.hidden = YES;
            [self stopConnectedTimer];
            self.userNameLabel.hidden = YES;
            self.portraitView.hidden = YES;
            self.stateLabel.text = WFCString(@"CallEnded");
            self.participantCollectionView.hidden = YES;
            self.speakerButton.hidden = YES;
            self.screenSharingButton.hidden = YES;
            self.managerButton.hidden = YES;
            self.informationButton.hidden = NO;
            [self updatePortraitAndStateViewFrame];
            break;
        case kWFAVEngineStateOutgoing:
            self.moreButton.hidden = NO;
            self.topBarView.hidden = YES;
            if (self.currentSession.isAudioOnly) {
                self.speakerButton.hidden = YES;
                [self updateSpeakerButton];
                self.audioButton.hidden = YES;
            } else {
                self.speakerButton.hidden = YES;
                self.audioButton.hidden = YES;
            }
            self.managerButton.hidden = YES;
            self.screenSharingButton.hidden = YES;
            self.videoButton.hidden = YES;
            self.stateLabel.text = WFCString(@"WaitingAccept");
            self.participantCollectionView.hidden = YES;
            self.userNameLabel.hidden = YES;
            self.portraitView.hidden = YES;
            [self updatePortraitAndStateViewFrame];
            
            break;
        case kWFAVEngineStateConnecting:
            self.moreButton.hidden = NO;
            self.speakerButton.hidden = YES;
            self.topBarView.hidden = YES;
            self.audioButton.hidden = YES;
            self.videoButton.hidden = YES;
            self.managerButton.hidden = YES;
            self.screenSharingButton.hidden = YES;
            self.participantCollectionView.hidden = NO;
            [self reloadParticipantCollectionView];
            self.stateLabel.text = WFCString(@"CallConnecting");
            self.portraitView.hidden = YES;
            self.userNameLabel.hidden = YES;
            break;
        case kWFAVEngineStateConnected:
            [self rearrangeParticipants];
            self.moreButton.hidden = NO;
            self.stateLabel.hidden = YES;
            self.managerButton.hidden = NO;
            self.screenSharingButton.hidden = NO;
            if (self.currentSession.isAudioOnly) {
                self.audioButton.hidden = NO;
                self.videoButton.hidden = YES;
            } else {
                self.audioButton.hidden = NO;
                self.videoButton.hidden = NO;
            }
            self.hangupButton.hidden = NO;
            self.speakerButton.hidden = NO;
            [self updateAudioButton];
            [self updateVideoButton];
            [self updateSpeakerButton];
            
            self.informationButton.hidden = NO;
            self.topBarView.hidden = NO;
            self.participantCollectionView.hidden = NO;
            [self reloadParticipantCollectionView];
            self.userNameLabel.hidden = YES;
            self.portraitView.hidden = YES;
            [self updateConnectedTimeLabel];
            [self startConnectedTimer];
            [self updatePortraitAndStateViewFrame];
            [self reloadVideoUI];
            [self showPanel];
            break;
        case kWFAVEngineStateIncomming:
            self.moreButton.hidden = NO;
            self.topBarView.hidden = YES;
            self.audioButton.hidden = YES;
            self.videoButton.hidden = YES;
            self.stateLabel.text = WFCString(@"InvitingYou");
            self.participantCollectionView.hidden = YES;
            break;
        default:
            break;
    }
}

- (void)didCreateLocalVideoTrack:(RTCVideoTrack *)localVideoTrack {
    
}

- (void)didReceiveRemoteVideoTrack:(RTCVideoTrack *)remoteVideoTrack fromUser:(NSString *)userId screenSharing:(BOOL)screenSharing {
}

- (void)didVideoMuted:(BOOL)videoMuted fromUser:(NSString *)userId {
    [self reloadVideoUI];
}

- (void)didReportAudioVolume:(NSInteger)volume ofUser:(NSString *)userId {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"wfavVolumeUpdated" object:userId userInfo:@{@"volume":@(volume)}];
    if([userId isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
        [self updateAudioVolume:volume];
    }
}

- (void)didCallEndWithReason:(WFAVCallEndReason)reason {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kConferenceEnded" object:nil];
    if(reason == kWFAVCallEndReasonRoomNotExist) {
        [self restartConference];
    } else if(reason == kWFAVCallEndReasonRoomParticipantsFull) {
        [self rejoinConferenceAsAudience];
    } else {
        if(reason == kWFAVCallEndReasonHangup || reason == kWFAVCallEndReasonAllLeft || reason == kWFAVCallEndReasonRoomDestroyed || reason == kWFAVCallEndReasonRemoteHangup) {
            [self.view makeToast:@"已离开会议" duration:1 position:CSToastPositionCenter];
        } else {
            [self.view makeToast:[NSString stringWithFormat:@"已离开会议(%ld)", reason] duration:1 position:CSToastPositionCenter];
        }
        [[WFCUConferenceManager sharedInstance] addHistory:self.conferenceInfo duration:(int)(self.currentSession.endTime - self.currentSession.startTime)];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self leftVC];
        });
    }
}

- (void)didParticipantJoined:(NSString *)userId screenSharing:(BOOL)screenSharing {
    [self updateSpeakerButton];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kConferenceMemberChanged" object:nil];
    
    if ([userId isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
        return;
    }
    
    //检查此profile是否已经在当前界面中了，如果已经存在忽略此事件
    for (WFAVParticipantProfile *profile in self.participants) {
        if([profile.userId isEqualToString:userId] && profile.screeSharing == screenSharing) {
            return;
        }
    }
    
    //屏幕分享的profile设置为焦点用户
    for (WFAVParticipantProfile *profile in self.currentSession.participants) {
        if([profile.userId isEqualToString:userId] && profile.screeSharing == screenSharing) {
            self.focusUserProfile = profile;
        }
    }
    
    [self rearrangeParticipants];
    [self reloadVideoUI];
    WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:userId refresh:NO];
    NSString *text;
    if(screenSharing) {
        text = [NSString stringWithFormat:@"%@ 开始屏幕分享", userInfo.friendAlias.length ? userInfo.friendAlias : userInfo.displayName];
    } else {
        text = [NSString stringWithFormat:@"%@ 加入了会议", userInfo.friendAlias.length ? userInfo.friendAlias : userInfo.displayName];
    }
    [self.view makeToast:text duration:1 position:CSToastPositionCenter];
}

- (void)didParticipantConnected:(NSString *)userId screenSharing:(BOOL)screenSharing {

}

- (void)didParticipantLeft:(NSString *)userId screenSharing:(BOOL)screenSharing withReason:(WFAVCallEndReason)reason {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kConferenceMemberChanged" object:nil];
    if([self.focusUserProfile.userId isEqualToString:userId] && screenSharing == self.focusUserProfile.screeSharing) {
        self.focusUserProfile = nil;
    }
    
    [self rearrangeParticipants];
    [self reloadVideoUI];
    
    
    WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:userId inGroup:self.currentSession.conversation.type == Group_Type ? self.currentSession.conversation.target : nil refresh:NO];
    
    NSString *reasonStr;
    if(screenSharing) {
        reasonStr = @"结束了屏幕分享";
    } else if (reason == kWFAVCallEndReasonTimeout) {
        reasonStr = @"未接听";
    } else if(reason == kWFAVCallEndReasonBusy) {
        reasonStr = @"网络忙";
    } else if(reason == kWFAVCallEndReasonInterrupted) {
        reasonStr = @"通话中断";
    } else if(reason == kWFAVCallEndReasonRemoteInterrupted) {
        reasonStr = @"对方通话中断";
    } else if(reason == kWFAVCallEndReasonRemoteHangup) {
        reasonStr = @"离开会议";
    } else {
        reasonStr = @"离开会议"; //"网络错误";
    }
    
    [self.view makeToast:[NSString stringWithFormat:@"%@ %@", userInfo.displayName, reasonStr] duration:1 position:CSToastPositionCenter];
}

- (void)didChangeMode:(BOOL)isAudioOnly {
    [self didChangeState:self.currentSession.state];
}

- (void)didError:(NSError *)error {
    if([error.domain isEqualToString:@"room_participants_full"]) {
        [self.view makeToast:@"发言人数已满，无法切换到发言人!" duration:1 position:CSToastPositionCenter];
    }
}

- (void)didGetStats:(NSArray *)stats {
    
}

- (void)didChangeType:(BOOL)audience ofUser:(NSString *)userId screenSharing:(BOOL)screenSharing {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kConferenceMemberChanged" object:nil];
    [self rearrangeParticipants];
    
    if([userId isEqualToString:[WFCCNetworkService sharedInstance].userId] || !userId) {
        [self updateAudioButton];
        [self updateVideoButton];
        [self updateScreenSharingButton];
    }
    
    [self reloadVideoUI];
}

- (void)didChangeAudioRoute {
    [self updateSpeakerButton];
}

- (void)didChangeInitiator:(NSString * _Nullable)initiator { 
    NSLog(@"did change initiator");
}

- (void)didMuteStateChanged:(NSArray<NSString *> *_Nonnull)userIds {
    if(self.currentSession) {
        [self rearrangeParticipants];
        [self reloadParticipantCollectionView];
        [self reloadVideoUI];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"kConferenceMutedStateChanged" object:nil];
    }
}

- (void)didMedia:(NSString *_Nullable)media lostPackage:(int)lostPackage screenSharing:(BOOL)screenSharing {
    //发送方丢包超过6为网络不好
    if(lostPackage > 6) {
        [self.view makeToast:@"您的网络不好" duration:3 position:CSToastPositionCenter];
    }
}

- (void)didMedia:(NSString *)media lostPackage:(int)lostPackage uplink:(BOOL)uplink ofUser:(NSString *)userId screenSharing:(BOOL)screenSharing {
    //如果uplink ture对方网络不好，false您的网络不好
    //接受方丢包超过10为网络不好
    if(lostPackage > 10) {
        if(uplink) {
            NSLog(@"对方的网络不好");
            [self.view makeToast:@"对方的网络不好" duration:3 position:CSToastPositionCenter];
        } else {
            NSLog(@"您的网络不好");
            [self.view makeToast:@"您的网络不好" duration:3 position:CSToastPositionCenter];
        }
    }
}

- (void)onScreenSharingFailure {
    
}

- (void)onStopBroadcastBtn:(id)sender {
    [[WFCUConferenceManager sharedInstance] stopScreansharing];
}

- (void)rejoinConferenceAsAudience {
    __weak typeof(self)ws = self;
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:@"会议发言人数已满，是否以观众身份入会？" preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *action1 = [UIAlertAction actionWithTitle:WFCString(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [ws leftVC];
    }];
    [alertController addAction:action1];
    
    BOOL audioOnly = self.currentSession.isAudioOnly;
    NSString *title = self.currentSession.title;
    NSString *desc = self.currentSession.desc;
    NSString *conferenceId = self.currentSession.callId;
    NSString *pin = self.currentSession.pin;
    NSString *host = self.currentSession.host;
    BOOL advanced = self.currentSession.isAdvanced;
    
    
    UIAlertAction *action2 = [UIAlertAction actionWithTitle:WFCString(@"Ok") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [ws leftVC];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            WFCUConferenceViewController *vc = [[WFCUConferenceViewController alloc] initWithCallId:conferenceId audioOnly:audioOnly pin:pin host:host title:title desc:desc audience:YES advanced:advanced record:NO moCall:NO maxParticipants:0 extra:nil];
            vc.conferenceInfo = self.conferenceInfo;
            [[WFAVEngineKit sharedEngineKit] presentViewController:vc];
        });
    }];
    [alertController addAction:action2];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [ws presentViewController:alertController animated:YES completion:nil];
    });
}

- (void)restartConference {
    if([self.currentSession.host isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
        __weak typeof(self)ws = self;
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:@"会议未开始或者已经结束，请点击启动来开始会议" preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *action1 = [UIAlertAction actionWithTitle:WFCString(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            [ws leftVC];
        }];
        [alertController addAction:action1];
        
        BOOL audioOnly = self.currentSession.isAudioOnly;
        BOOL defaultAudience = self.currentSession.defaultAudience;
        NSString *title = self.currentSession.title;
        NSString *desc = self.currentSession.desc;
        NSString *conferenceId = self.currentSession.callId;
        NSString *pin = self.currentSession.pin;
        BOOL advanced = self.currentSession.isAdvanced;
        
        
        UIAlertAction *action2 = [UIAlertAction actionWithTitle:@"启动" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            [ws leftVC];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                WFCUConferenceViewController *vc = [[WFCUConferenceViewController alloc] initWithCallId:conferenceId audioOnly:audioOnly pin:pin host:[WFCCNetworkService sharedInstance].userId title:title desc:desc audience:defaultAudience advanced:advanced record:NO moCall:YES maxParticipants:self.conferenceInfo.maxParticipants extra:nil];
                vc.conferenceInfo = self.conferenceInfo;
                [[WFAVEngineKit sharedEngineKit] presentViewController:vc];
            });
        }];
        [alertController addAction:action2];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [ws presentViewController:alertController animated:YES completion:nil];
        });
    } else {
        WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:self.currentSession.host refresh:NO];
        
        __weak typeof(self)ws = self;
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:[NSString stringWithFormat:@"会议未开始或者已经结束，请联系 %@ 启动会议", userInfo.friendAlias.length ? userInfo.friendAlias : userInfo.displayName] preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction *action1 = [UIAlertAction actionWithTitle:WFCString(@"Ok") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            [ws leftVC];
        }];
        [alertController addAction:action1];
        dispatch_async(dispatch_get_main_queue(), ^{
            [ws presentViewController:alertController animated:YES completion:nil];
        });
    }
}
- (void)reloadVideoUI {
    [self reloadParticipantCollectionView];
}

- (void)reloadParticipantCollectionView {
    [self.participantCollectionView reloadData];
    __weak typeof(self)ws = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [ws updateVideoStreams];
    });
}

- (void)updateVideoStreams {
    if([[WFCUConferenceManager sharedInstance] isBroadcasting]) {
        [self unsubscribeAllVideoStream];
        return;
    }
    
    WFCUConferenceCollectionViewLayout *layout = (WFCUConferenceCollectionViewLayout *)self.participantCollectionView.collectionViewLayout;
    if(layout.audioOnly) {
        [self unsubscribeAllVideoStream];
        return;
    }
    
    NSArray<NSIndexPath *> *visiableItems = [self.participantCollectionView indexPathsForVisibleItems];
    NSMutableArray *leaveItems = [[NSMutableArray alloc] init];
    __block BOOL hasMain = NO;
    [visiableItems enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if(obj.row == 0) {
            hasMain = YES;
            *stop = YES;
        }
    }];
    
    CGPoint pos = [layout getOffsetOfItems:visiableItems];
    BOOL needScroll = NO;
    CGPoint targetContentOffset = self.participantCollectionView.contentOffset;
    if(pos.x != targetContentOffset.x) {
        needScroll = YES;
        __block int row;
        if (ABS(pos.x-targetContentOffset.x) > ABS(pos.y - targetContentOffset.x)) {
            row = 0;
            [visiableItems enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if(obj.row > row) {
                    row = obj.row;
                }
            }];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.participantCollectionView scrollRectToVisible:CGRectMake(pos.y, 0, pos.y-pos.x, 100) animated:YES];
            });
        } else {
            targetContentOffset.x = pos.x;
            row = 0x1FFFFFFF;
            [visiableItems enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if(obj.row < row) {
                    row = obj.row;
                }
            }];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.participantCollectionView scrollRectToVisible:CGRectMake(pos.x, 0, pos.y-pos.x, 100) animated:YES];
            });
        }
        
        int page;
        if(row == 0) {
            page = 0;
        } else {
            page = (row -1)/4 + 1;
        }
        if(page > 0) {
            [self hidePanel];
        }
        [self.pageControl setCurrentPage:page];
        [self.pageControl updateCurrentPageDisplay];
    }
    
    if(!needScroll) {
        if(self.participants.count > 1) {
            [self.participants enumerateObjectsUsingBlock:^(WFAVParticipantProfile * _Nonnull obj, NSUInteger idx1, BOOL * _Nonnull stop) {
                if(obj.videoType != WFAVVideoType_None && !obj.audience) {
                    [leaveItems addObject:[NSIndexPath indexPathForRow:idx1+1 inSection:0]];
                }
            }];
        }
        
        CGPoint targetContentOffset = self.participantCollectionView.contentOffset;
        int page = (targetContentOffset.x + 1)/self.participantCollectionView.bounds.size.width;
        [self onItemsEnter:[layout itemsInPage:page] itemsLeave:leaveItems];
    }
}
- (BOOL)switchVideoView:(NSUInteger)index {
    WFAVParticipantProfile *user = self.participants[index];
    
    BOOL canSwitch = NO;
    for (WFAVParticipantProfile *profile in self.currentSession.participants) {
        if ([profile.userId isEqualToString:user.userId] && profile.screeSharing == user.screeSharing) {
            if (profile.state == kWFAVEngineStateConnected) {
                canSwitch = YES;
            }
            break;
        }
    }
    
    if ([user.userId isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
        if (self.currentSession.state == kWFAVEngineStateConnected) {
            canSwitch = YES;
        }
    }
    
    if (canSwitch) {
        self.focusUserProfile = user;
        [self rearrangeParticipants];
        [self.participantCollectionView reloadData];
        [self.participantCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
    }
    
    return canSwitch;
}

- (void)pageChange:(id)sender {
    
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if([[WFCUConferenceManager sharedInstance] isBroadcasting]) {
        return 1;
    }
    WFCUConferenceCollectionViewLayout *layout = (WFCUConferenceCollectionViewLayout *)collectionView.collectionViewLayout;
    if(layout.audioOnly) {
        NSLog(@"count %d", (self.participants.count-1) / 12 + 1);
        return (self.participants.count-1) / 12 + 1;
    } else {
        if(self.participants.count == 1 || self.participants.count == 2) {
            NSLog(@"count %d", 1);
            return 1;
        }
        NSLog(@"count %d", self.participants.count+1);
        return self.participants.count+1;
    }
}

#pragma mark - UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    WFCUConferenceCollectionViewLayout *layout = (WFCUConferenceCollectionViewLayout *)collectionView.collectionViewLayout;
    CGSize size = collectionView.frame.size;
    
    if(layout.audioOnly || indexPath.row == 0) {
        return size;
    } else {
        size.width /= 2;
        size.height /= 2;
        return size;
    }
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if([[WFCUConferenceManager sharedInstance] isBroadcasting]) {
        UICollectionViewCell *broadcastingCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"broadcasting" forIndexPath:indexPath];
        for (UIView *subView in broadcastingCell.contentView.subviews) {
            [subView removeFromSuperview];
        }
        UIButton *stopBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 120, 120)];
        CGRect bounds = self.view.bounds;
        stopBtn.center = CGPointMake(bounds.size.width/2, bounds.size.height/2);
        [stopBtn setImage:[WFCUImage imageNamed:@"conference_stop_screen_sharing"] forState:UIControlStateNormal];
        [stopBtn setTitle:@"停止共享" forState:UIControlStateNormal];
        stopBtn.titleLabel.font = [UIFont systemFontOfSize:14];

        stopBtn.titleEdgeInsets = UIEdgeInsetsMake(stopBtn.imageView.frame.size.height / 2-8, -stopBtn.imageView.frame.size.width,
                                                  -stopBtn.imageView.frame.size.height, 0);
        stopBtn.imageEdgeInsets = UIEdgeInsetsMake(-4,
                                                  0, stopBtn.imageView.frame.size.height / 2, -stopBtn.titleLabel.bounds.size.width);
        
        stopBtn.imageView.layer.masksToBounds = YES;
        stopBtn.imageView.layer.cornerRadius = 10.f;
        
        [stopBtn addTarget:self action:@selector(onStopBroadcastBtn:) forControlEvents:UIControlEventTouchDown];
        
        [broadcastingCell.contentView addSubview:stopBtn];
        return broadcastingCell;
    }
    
    WFCUConferenceCollectionViewLayout *layout = (WFCUConferenceCollectionViewLayout *)self.participantCollectionView.collectionViewLayout;
    if(layout.audioOnly) {
        WFCUConferenceAudioCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"audio_cell" forIndexPath:indexPath];
        [cell setProfiles:self.participants pages:indexPath.row];
        return cell;
    } else {
        WFAVParticipantProfile *user = self.focusUserProfile;
        if(indexPath.row > 0) {
            user = self.participants[indexPath.row-1];
        }
        
        WFAVParticipantProfile *refreshProfile = [[WFAVEngineKit sharedEngineKit].currentSession profileOfUser:user.userId isScreenSharing:user.screeSharing];
        if(refreshProfile) {
            user = refreshProfile;
        }
        
        BOOL isMain = (indexPath.row == 0);
        WFCUConferenceParticipantCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:isMain ? @"main" : @"sub" forIndexPath:indexPath];
        if(isMain) {
            cell.backgroundColor = [UIColor blackColor];
        } else {
            UITapGestureRecognizer *doubleTapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(onDoubleClickedParticipantCollectionView:)];
            doubleTapGesture.numberOfTapsRequired = 2;
            doubleTapGesture.numberOfTouchesRequired = 1;
            [cell setGestureRecognizers:@[doubleTapGesture]];
        }
        
        WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:user.userId inGroup:self.currentSession.conversation.type == Group_Type ? self.currentSession.conversation.target : nil refresh:NO];
        
        [cell setUserInfo:userInfo callProfile:user];
        
        return cell;
    }
}

- (void)onClickedParticipantCollectionView:(id)sender {
    [self onClickedBigVideoView:self.participantCollectionView];
}

- (void)onDoubleClickedParticipantCollectionView:(id)sender {
    UITapGestureRecognizer *tap = (UITapGestureRecognizer *)sender;
    UIView * view = tap.view;
    while (view && ![view isKindOfClass:[WFCUConferenceParticipantCollectionViewCell class]]) {
        view = view.superview;
    }
    if(view) {
        NSIndexPath *indexPath = [self.participantCollectionView indexPathForCell:(WFCUConferenceParticipantCollectionViewCell *)view];
        if(indexPath && indexPath.row > 0) {
            [self switchVideoView:indexPath.row-1];
        }
    }
}
#pragma mark - UICollectionViewDelegate
-(void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    WFCUConferenceCollectionViewLayout *layout = (WFCUConferenceCollectionViewLayout *)self.participantCollectionView.collectionViewLayout;
    if(!layout.audioOnly) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateVideoStreams];
        });
    }
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {

}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    WFCUConferenceCollectionViewLayout *layout = (WFCUConferenceCollectionViewLayout *)self.participantCollectionView.collectionViewLayout;
    NSArray<NSIndexPath *> *items = [self.participantCollectionView indexPathsForVisibleItems];
    if (items.count >= 2) {
        WFCUConferenceCollectionViewLayout *layout = (WFCUConferenceCollectionViewLayout *)self.participantCollectionView.collectionViewLayout;
        CGPoint pos = [layout getOffsetOfItems:items];
        if(pos.x == pos.y) {
            return;
        }
        
        __block int row;
        if (ABS(pos.x-targetContentOffset->x) > ABS(pos.y - targetContentOffset->x)) {
            targetContentOffset->x = pos.y;
            row = 0;
            [items enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if(obj.row > row) {
                    row = obj.row;
                }
            }];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.participantCollectionView scrollRectToVisible:CGRectMake(pos.y, 0, pos.y-pos.x, 100) animated:YES];
            });
        } else {
            targetContentOffset->x = pos.x;
            row = 0x1FFFFFFF;
            [items enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if(obj.row < row) {
                    row = obj.row;
                }
            }];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.participantCollectionView scrollRectToVisible:CGRectMake(pos.x, 0, pos.y-pos.x, 100) animated:YES];
            });
        }

        int page;
        if(layout.audioOnly) {
            page = (row -1)/12 + 1;
        } else {
            if(row == 0) {
                page = 0;
            } else {
                page = (row -1)/4 + 1;
            }
        }
        
        if(page > 0) {
            [self hidePanel];
        }
        [self.pageControl setCurrentPage:page];
        [self.pageControl updateCurrentPageDisplay];
    }
}

- (void)onItemsEnter:(NSArray<NSIndexPath *> *)enterItems itemsLeave:(NSMutableArray<NSIndexPath *> *)leaveItems {
    __block BOOL hasMain = NO;
    [enterItems enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if(obj.row == 0) {
            hasMain = YES;
            *stop = YES;
        }
    }];
    
    [enterItems enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull indexPath, NSUInteger idx, BOOL * _Nonnull stop) {
        UICollectionViewCell *cell = [self.participantCollectionView cellForItemAtIndexPath:indexPath];
        BOOL isMain = (indexPath.row == 0);
        WFAVParticipantProfile *profile = ((WFCUConferenceParticipantCollectionViewCell *)cell).profile;

        if([profile.userId isEqualToString:[WFCCNetworkService sharedInstance].userId] || !profile.userId) {
            [self.currentSession setupLocalVideoView:cell scalingType:self.scalingType];
        } else {
            [self.currentSession setupRemoteVideoView:cell scalingType:self.scalingType forUser:profile.userId screenSharing:profile.screeSharing];

            if(isMain) {
                [self.currentSession setParticipant:profile.userId screenSharing:profile.screeSharing videoType:WFAVVideoType_BigStream];
            } else {
                [self.currentSession setParticipant:profile.userId screenSharing:profile.screeSharing videoType:WFAVVideoType_SmallStream];
            }
        }

        if(isMain) {
            if([profile.userId isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
                self.smallVideoView.hidden = YES;
            } else {
                if(!self.smallVideoView.superview) {
                    [cell addSubview:self.smallVideoView];
                }

                WFCCUserInfo *myUserInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:[WFCCNetworkService sharedInstance].userId refresh:NO];
                [self.smallVideoView setUserInfo:myUserInfo callProfile:self.currentSession.myProfile];
                [self.currentSession setupLocalVideoView:self.smallVideoView scalingType:self.scalingType];
                self.smallVideoView.hidden = NO;
                [cell bringSubviewToFront:self.smallVideoView];
            }
        }
        
        [leaveItems removeObject:indexPath];
        [leaveItems enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            WFAVParticipantProfile *leaveProfile = obj.row > 0 ? self.participants[obj.row-1] : self.focusUserProfile;
            if([profile.userId isEqualToString:leaveProfile.userId] && profile.screeSharing == leaveProfile.screeSharing) {
                [leaveItems removeObject:obj];
                *stop = YES;
            }
        }];
    }];
    
    [leaveItems enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull indexPath, NSUInteger idx, BOOL * _Nonnull stop) {
        WFAVParticipantProfile *profile = indexPath.row > 0 ? self.participants[indexPath.row-1] : self.focusUserProfile;
        if(profile && ![profile.userId isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
            [self.currentSession setParticipant:profile.userId screenSharing:profile.screeSharing videoType:WFAVVideoType_None];
        }
    }];
}

#pragma mark - WFCUConferenceManagerDelegate
-(void)onChangeModeRequest:(BOOL)isAudience {
    if(isAudience) {
        [[WFAVEngineKit sharedEngineKit].currentSession switchAudience:isAudience];
    } else {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"" message:@"主持人邀请您发言" preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *action1 = [UIAlertAction actionWithTitle:WFCString(@"Ignore") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            
        }];
        [alertController addAction:action1];
        
        UIAlertAction *action2 = [UIAlertAction actionWithTitle:WFCString(@"Accept") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            [[WFAVEngineKit sharedEngineKit].currentSession switchAudience:isAudience];
        }];
        [alertController addAction:action2];
        
        [self presentViewController:alertController animated:YES completion:nil];
    }
}
-(void)onReceiveCommand:(WFCUConferenceCommandType)commandType content:(WFCUConferenceCommandContent *)commandContent fromUser:(NSString *)sender {
    WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:sender refresh:NO];
    NSString *userName = @"对方";
    if(userInfo.friendAlias.length) {
        userName = userInfo.friendAlias;
    } else if(userInfo.displayName.length) {
        userName = userInfo.displayName;
    }
    
    switch(commandType) {
        case MUTE_ALL_AUDIO: {
            [self showCommandToast:@"主持人开启了全员静音"];
            break;
        }
        case MUTE_ALL_VIDEO: {
            [self showCommandToast:@"主持人关闭了所有人的摄像头"];
            break;
        }
        case CANCEL_MUTE_ALL_AUDIO: 
        case CANCEL_MUTE_ALL_VIDEO:
        {
            BOOL audio = commandType == CANCEL_MUTE_ALL_AUDIO;
            if(commandContent.boolValue && [WFAVEngineKit sharedEngineKit].currentSession.isConference) {
                if([WFAVEngineKit sharedEngineKit].currentSession.isAudience || ((audio && [WFAVEngineKit sharedEngineKit].currentSession.isAudioMuted) || (!audio && [WFAVEngineKit sharedEngineKit].currentSession.isVideoMuted))) {
                    NSString *message;
                    if(audio) {
                        message = @"管理员关闭了全员静音，是否要打开麦克风";
                    } else {
                        message = @"管理员取消了全体成员关闭摄像头，是否打开摄像头";
                    }
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"" message:message preferredStyle:UIAlertControllerStyleAlert];
                    
                    UIAlertAction *action1 = [UIAlertAction actionWithTitle:WFCString(@"Ignore") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                        
                    }];
                    [alertController addAction:action1];
                    
                    UIAlertAction *action2 = [UIAlertAction actionWithTitle:@"打开" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
                        if(audio) {
                            [[WFCUConferenceManager sharedInstance] muteAudio:NO];
                        } else {
                            [[WFCUConferenceManager sharedInstance] muteVideo:NO];
                        }
                    }];
                    [alertController addAction:action2];
                    
                    [self presentViewController:alertController animated:YES completion:nil];
                } else {
                    [self showCommandToast:audio?@"管理员关闭了全员静音":@"管理员关闭了全员关闭摄像头"];
                }
            } else {
                [self showCommandToast:audio?@"管理员关闭了全员静音":@"管理员关闭了全员关闭摄像头"];
            }
            break;
        }
        case REQUEST_MUTE_AUDIO:
        case REQUEST_MUTE_VIDEO:
        {
            BOOL audio = commandType == REQUEST_MUTE_AUDIO;
            if(commandContent.boolValue) {
                [self showCommandToast:audio?@"主持人关闭了您的":@"主持人关闭了您的摄像头"];
            } else {
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"" message:audio?@"主持人邀请您打开麦克风":@"主持人邀请您打开摄像头" preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction *action1 = [UIAlertAction actionWithTitle:WFCString(@"Reject") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                    [[WFCUConferenceManager sharedInstance] rejectUnmuteRequest];
                }];
                [alertController addAction:action1];
                
                UIAlertAction *action2 = [UIAlertAction actionWithTitle:WFCString(@"Accept") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
                    if(audio) {
                        [[WFCUConferenceManager sharedInstance] muteAudio:NO];
                    } else {
                        [[WFCUConferenceManager sharedInstance] muteVideo:NO];
                    }
                }];
                [alertController addAction:action2];
                
                [self presentViewController:alertController animated:YES completion:nil];
            }
        }
            break;
        case REJECT_UNMUTE_AUDIO_REQUEST:
        case REJECT_UNMUTE_VIDEO_REQUEST:
            [self showCommandToast:[NSString stringWithFormat:@"%@ 拒绝了您的请求", userName]];
            break;
            
        case APPLY_UNMUTE_AUDIO:
        case APPLY_UNMUTE_VIDEO:
        {
            BOOL audio = commandType == APPLY_UNMUTE_AUDIO;
            [self showCommandToast:[NSString stringWithFormat:audio?@"%@ 请求开启麦克风":@"%@ 请求开启摄像头", userName]];
        }
            break;
            
        case APPROVE_UNMUTE_AUDIO:
        case APPROVE_UNMUTE_VIDEO:
            if(!commandContent.boolValue) {
                [self showCommandToast:@"主持人拒绝了您的请求"];
            }
            break;
        case APPROVE_ALL_UNMUTE_AUDIO:
        case APPROVE_ALL_UNMUTE_VIDEO:
            [self showCommandToast:commandContent.boolValue ? @"主持人同意了所有的发言请求" :  @"主持人拒绝了所有的发言请求"];
            break;
            
            //举手，带有参数是举手还是放下举手
        case HANDUP:
            [self showCommandToast:[NSString stringWithFormat:commandContent.boolValue ? @"%@ 举手" :  @"%@ 放下举手", userName]];
            break;
            
            //主持人放下成员的举手
        case PUT_HAND_DOWN:
            [self showCommandToast:@"主持人放下您的举手"];
            break;
            //主持人放下全体成员的举手
        case PUT_ALL_HAND_DOWN:
            [self showCommandToast:@"主持人放下所有举手"];
            break;
            
        case RECORDING:
            [self showCommandToast:commandContent.boolValue ? @"主持人开始录制" : @"主持人结束录制"];
            break;
        case FOCUS:
            [self showCommandToast:@"主持人锁定焦点用户"];
            if(![self.focusUserProfile.userId isEqualToString:[WFCUConferenceManager sharedInstance].currentConferenceInfo.focus]) {
                [self rearrangeParticipants];
                [self reloadParticipantCollectionView];
            }
            break;
        case CANCEL_FOCUS:
            [self showCommandToast:@"主持人取消锁定焦点用户"];
            [self rearrangeParticipants];
            [self reloadParticipantCollectionView];
            break;
        default:
            break;
    }
}

- (void)showToast:(NSString *)text {
    [self.view makeToast:text duration:[CSToastManager defaultDuration] position:CSToastPositionCenter];
}

- (void)showCommandToast:(NSString *)text {
    [self.view makeToast:text duration:[CSToastManager defaultDuration] position:CSToastPositionCenter];
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.messages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WFCCMessage *msg = self.messages[indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell3"];
    if(!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell3"];
        cell.textLabel.font = [UIFont systemFontOfSize:12];
        cell.backgroundColor = [UIColor clearColor];
        cell.textLabel.numberOfLines = 0;
    }
    
    WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:msg.fromUser refresh:NO];
    NSString *name = userInfo.friendAlias.length ? userInfo.friendAlias : userInfo.displayName;
    
    NSMutableAttributedString *attStr = [[NSMutableAttributedString alloc] initWithString:name attributes:@{NSForegroundColorAttributeName : [UIColor orangeColor]}];
    [attStr appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@":%@", [msg.content digest:msg]] attributes:@{NSForegroundColorAttributeName : [UIColor grayColor]}]];
    
    cell.textLabel.attributedText = attStr;
    
    return cell;
}

- (void)dealloc {
    NSLog(@"dealloc");
}
@end
#endif
