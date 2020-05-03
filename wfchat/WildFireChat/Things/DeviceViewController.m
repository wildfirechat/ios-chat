//
//  ThingsViewController.m
//  WildFireChat
//
//  Created by Tom Lee on 2020/4/26.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "DeviceViewController.h"
#import <WFChatClient/WFCChatClient.h>
#import "DeviceInfoViewController.h"

@interface DeviceViewController ()
@property(nonatomic, assign)BOOL ledOn;
@property(nonatomic, strong)UILabel *dthLabel;
@property(nonatomic, strong)UIButton *ledBtn;
@end

#define kIs_iPhoneX ([UIScreen mainScreen].bounds.size.height == 812.0f ||[UIScreen mainScreen].bounds.size.height == 896.0f )

#define kStatusBarAndNavigationBarHeight (kIs_iPhoneX ? 88.f : 64.f)

@implementation DeviceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    CGRect bounds = self.view.bounds;

    self.ledBtn = [[UIButton alloc] initWithFrame:CGRectMake((bounds.size.width - 100 - 100 - 20)/2, (bounds.size.height - 20)/2, 100, 40)];
    [self.ledBtn addTarget:self action:@selector(onLedBtn:) forControlEvents:UIControlEventTouchDown];
    [self.ledBtn setTitle:@"打开LED" forState:UIControlStateNormal];
    [self.ledBtn setBackgroundColor:[UIColor redColor]];
    self.ledBtn.layer.masksToBounds = YES;
    self.ledBtn.layer.cornerRadius = 5.f;
    self.ledBtn.tag = 0;
    
    UIButton *btnDHT = [[UIButton alloc] initWithFrame:CGRectMake((bounds.size.width - 100 - 100 - 20)/2 + 100 + 20, (bounds.size.height - 20)/2, 100, 40)];
    [btnDHT addTarget:self action:@selector(onLedBtn:) forControlEvents:UIControlEventTouchDown];
    [btnDHT setTitle:@"手动更新数据" forState:UIControlStateNormal];
    [btnDHT setBackgroundColor:[UIColor greenColor]];
    btnDHT.layer.masksToBounds = YES;
    btnDHT.layer.cornerRadius = 5.f;
    btnDHT.tag = 1;
    
    [self.view addSubview:self.ledBtn];
    [self.view addSubview:btnDHT];
    
    self.dthLabel = [[UILabel alloc] initWithFrame:CGRectMake(8, kStatusBarAndNavigationBarHeight + 16.f, bounds.size.width - 16, 100)];
    self.dthLabel.textAlignment = NSTextAlignmentCenter;
    self.dthLabel.backgroundColor = [UIColor grayColor];
    self.dthLabel.textColor = [UIColor greenColor];
    [self.view addSubview:self.dthLabel];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onReceiveMessages:) name:kReceiveMessages object:nil];
    
    [self sendCmd:@"GET_DHT"];
    [self sendCmd:@"GET_LED"];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Info" style:UIBarButtonItemStyleDone target:self action:@selector(onRightBtn:)];
}

- (NSString *)deviceId {
    return self.device.deviceId;
}

- (void)onRightBtn:(id)sender {
    DeviceInfoViewController *vc = [[DeviceInfoViewController alloc] init];
    vc.device = self.device;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onLedBtn:(UIButton *)sender {
    if (sender.tag == 0) {
        if (!self.ledOn) {
            [self sendCmd:@"LED_ON"];
        } else {
            [self sendCmd:@"LED_OFF"];
        }
    } else if(sender.tag == 1) {
        [self sendCmd:@"GET_DHT"];
    }
}
- (void)setLedOn:(BOOL)ledOn {
    _ledOn = ledOn;
    if (self.ledOn) {
        [self.ledBtn setTitle:@"关闭LED" forState:UIControlStateNormal];
        self.ledBtn.backgroundColor = [UIColor redColor];
    } else {
        [self.ledBtn setTitle:@"打开LED" forState:UIControlStateNormal];
        self.ledBtn.backgroundColor = [UIColor grayColor];
    }
}
- (void)sendCmd:(NSString *)cmdStr {
    WFCCThingsDataContent *cmdMsg = [[WFCCThingsDataContent alloc] init];
    cmdMsg.data = [cmdStr dataUsingEncoding:NSUTF8StringEncoding];
    
    [[WFCCIMService sharedWFCIMService] send:[WFCCConversation conversationWithType:Things_Type target:self.deviceId line:0] content:cmdMsg success:^(long long messageUid, long long timestamp) {
        NSLog(@"send msg success");
    } error:^(int error_code) {
        NSLog(@"send msg error");
    }];
}

- (void)onReceiveMessages:(NSNotification *)notification {
    NSArray<WFCCMessage *> *messages = notification.object;
    for (WFCCMessage *msg in messages) {
        if (msg.conversation.type == Things_Type) {
            if (![msg.conversation.target isEqualToString:self.deviceId]) {
                NSLog(@"Unknown things.....");
            } else {
                if ([msg.content isKindOfClass:[WFCCThingsDataContent class]]) {
                    WFCCThingsDataContent *thingsData = (WFCCThingsDataContent *)msg.content;
                    if (thingsData.data.length > 0) {
                        unsigned char* bytes = (unsigned char*)thingsData.data.bytes;
                        if (bytes[0] == 0) {
                            if (thingsData.data.length == 7) {
                                int thHi = bytes[1];
                                int thLo = bytes[2];
                                
                                int dHi = bytes[3];
                                int dLo = bytes[4];
                                NSString *str = [NSString stringWithFormat:@"湿度:%d.%d%% 温度:%d.%dC", thHi, thLo, dHi, dLo];
                                self.dthLabel.text = str;
                            }
                        } else if(bytes[0] == 1) {
                            if (thingsData.data.length == 2) {
                                int led_status = bytes[1];
                                self.ledOn = led_status > 0;
                            }
                        }
                    }
                } else if ([msg.content isKindOfClass:[WFCCThingsLostEventContent class]]) {
                    WFCCThingsLostEventContent *thingsLostEvent = (WFCCThingsLostEventContent *)msg.content;
                }
            }
        }
    }
}
@end
