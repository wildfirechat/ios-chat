//
//  WFCPrivacyFindMeViewController.h
//  WFChat UIKit
//
//  Created by WF Chat on 2017/10/6.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCPrivacyFindMeViewController.h"
#import <WFChatClient/WFCChatClient.h>
#import <WFChatUIKit/WFChatUIKit.h>

@interface WFCPrivacyFindMeViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong)UITableView *tableView;

@property (nonatomic, strong)NSMutableArray<NSMutableArray<UITableViewCell *> *> *cells;
@end

@implementation WFCPrivacyFindMeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self createCells];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStyleGrouped];
    if (@available(iOS 15, *)) {
        self.tableView.sectionHeaderTopPadding = 0;
    }
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.tableView reloadData];
    
    [self.view addSubview:self.tableView];
    
}

- (void)createCells {
    self.cells = [[NSMutableArray alloc] init];
    NSMutableArray *section2 = [[NSMutableArray alloc] init];
    [self.cells addObject:section2];
    
    int searchableValue = [[[WFCCIMService sharedWFCIMService] getUserSetting:UserSettingScope_Privacy_Searchable key:nil] intValue];
    __weak typeof(self)ws = self;
    
    WFCUGeneralSwitchTableViewCell *switchCell2 = [[WFCUGeneralSwitchTableViewCell alloc] init];
    switchCell2.textLabel.text = @"账号";
    if (searchableValue & DisableSearch_Name_Mask) {
        switchCell2.on = NO;
    } else {
        switchCell2.on = YES;
    }
    [switchCell2 setOnSwitch:^(BOOL value, int type, void (^result)(BOOL success)) {
        int intvalue = [[[WFCCIMService sharedWFCIMService] getUserSetting:UserSettingScope_Privacy_Searchable key:nil] intValue];
        if(value) {
            intvalue &= (DisableSearch_DisplayName_Mask | DisableSearch_Mobile_Mask | DisableSearch_UserId_Mask);
        } else {
            intvalue |= DisableSearch_Name_Mask;
        }
        [[WFCCIMService sharedWFCIMService] setUserSetting:UserSettingScope_Privacy_Searchable key:nil value:[NSString stringWithFormat:@"%d", intvalue] success:^{
                    result(YES);
                } error:^(int error_code) {
                    [ws.view makeToast:@"网络错误"];
                    result(NO);
                }];
    }];
    [section2 addObject:switchCell2];
    
    WFCUGeneralSwitchTableViewCell *switchCell3 = [[WFCUGeneralSwitchTableViewCell alloc] init];
    switchCell3.textLabel.text = @"电话号码";
    if (searchableValue & DisableSearch_Mobile_Mask) {
        switchCell3.on = NO;
    } else {
        switchCell3.on = YES;
    }
    [switchCell3 setOnSwitch:^(BOOL value, int type, void (^result)(BOOL success)) {
        int intvalue = [[[WFCCIMService sharedWFCIMService] getUserSetting:UserSettingScope_Privacy_Searchable key:nil] intValue];
        if(value) {
            intvalue &= (DisableSearch_DisplayName_Mask | DisableSearch_Name_Mask | DisableSearch_UserId_Mask);
        } else {
            intvalue |= DisableSearch_Mobile_Mask;
        }
        [[WFCCIMService sharedWFCIMService] setUserSetting:UserSettingScope_Privacy_Searchable key:nil value:[NSString stringWithFormat:@"%d", intvalue] success:^{
                    result(YES);
                } error:^(int error_code) {
                    [ws.view makeToast:@"网络错误"];
                    result(NO);
                }];
    }];
    [section2 addObject:switchCell3];
   
    //如果需要按照用户id搜索，可以打开下面这段，正常不用打开
//    WFCUGeneralSwitchTableViewCell *switchCell4 = [[WFCUGeneralSwitchTableViewCell alloc] init];
//    switchCell4.textLabel.text = @"用户ID";
//    if (searchableValue & DisableSearch_UserId_Mask) {
//        switchCell4.on = NO;
//    } else {
//        switchCell4.on = YES;
//    }
//    [switchCell4 setOnSwitch:^(BOOL value, int type, void (^result)(BOOL success)) {
//        int intvalue = [[[WFCCIMService sharedWFCIMService] getUserSetting:UserSettingScope_Privacy_Searchable key:nil] intValue];
//        if(value) {
//            intvalue &= (DisableSearch_DisplayName_Mask | DisableSearch_Name_Mask | DisableSearch_Mobile_Mask);
//        } else {
//            intvalue |= DisableSearch_UserId_Mask;
//        }
//        [[WFCCIMService sharedWFCIMService] setUserSetting:UserSettingScope_Privacy_Searchable key:nil value:[NSString stringWithFormat:@"%d", intvalue] success:^{
//                    result(YES);
//                } error:^(int error_code) {
//                    [ws.view makeToast:@"网络错误"];
//                    result(NO);
//                }];
//    }];
//    [section2 addObject:switchCell4];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 48;
}
-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 36;
}
-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"可以通过以下方法找到我";
}


//#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.cells.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.cells[section].count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return self.cells[indexPath.section][indexPath.row];
}

@end
