//
//  WFCUPanDocsViewController.m
//  WFChatUIKit
//

#import "WFCUPanDocsViewController.h"
#import "WFCUPanService.h"
#import "WFCUPanFile.h"
#import "WFCUPanDocUtils.h"
#import "WFCUConfigManager.h"
#import "WFCUBrowserViewController.h"
#import "WFCUImage.h"
#import "UIFont+YH.h"
#import "UIView+Toast.h"

@interface WFCUPanDocsViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray<WFCUPanFile *> *recentDocs;
@property (nonatomic, assign) BOOL mobileEditEnabled;
@property (nonatomic, assign) BOOL loading;
@end

@implementation WFCUPanDocsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = WFCString(@"OnlineDocs");
    self.view.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
    self.recentDocs = [NSMutableArray array];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
    self.tableView.tableFooterView = [[UIView alloc] init];
    [self.view addSubview:self.tableView];
    
    [self refreshNewDocButton];
    [self loadData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadRecentDocs];
}

#pragma mark - Data

- (void)loadData {
    __weak typeof(self) ws = self;
    id<WFCUPanService> service = [WFCUConfigManager globalManager].panServiceProvider;
    [service isMobileDocEditEnabledWithSuccess:^(BOOL mobileEdit) {
        ws.mobileEditEnabled = mobileEdit;
        dispatch_async(dispatch_get_main_queue(), ^{
            [ws refreshNewDocButton];
        });
    } error:^(int errorCode, NSString *message) {
        ws.mobileEditEnabled = NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            [ws refreshNewDocButton];
        });
    }];
    [self loadRecentDocs];
}

- (void)loadRecentDocs {
    if (![WFCUConfigManager isPanConfigured]) {
        return;
    }
    __weak typeof(self) ws = self;
    self.loading = YES;
    [self.tableView reloadData];
    [[WFCUConfigManager globalManager].panServiceProvider getRecentDocsWithSuccess:^(NSArray<WFCUPanFile *> *files) {
        dispatch_async(dispatch_get_main_queue(), ^{
            ws.loading = NO;
            [ws.recentDocs removeAllObjects];
            [ws.recentDocs addObjectsFromArray:files];
            [ws.tableView reloadData];
        });
    } error:^(int errorCode, NSString *message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            ws.loading = NO;
            [ws.tableView reloadData];
        });
    }];
}

- (void)refreshNewDocButton {
    if (self.mobileEditEnabled) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(onNewDoc:)];
    } else {
        self.navigationItem.rightBarButtonItem = nil;
    }
}

#pragma mark - Actions

- (void)onNewDoc:(id)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:WFCString(@"NewDoc") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [alert addAction:[UIAlertAction actionWithTitle:WFCString(@"NewDocument") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self promptCreateDoc:@"docx" defaultName:WFCString(@"UnnamedDoc")];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:WFCString(@"NewSpreadsheet") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self promptCreateDoc:@"xlsx" defaultName:WFCString(@"UnnamedSheet")];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:WFCString(@"NewPresentation") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self promptCreateDoc:@"pptx" defaultName:WFCString(@"UnnamedSlide")];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:WFCString(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)promptCreateDoc:(NSString *)type defaultName:(NSString *)defaultName {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:WFCString(@"NewDoc") message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = defaultName;
    }];
    __weak typeof(self) ws = self;
    [alert addAction:[UIAlertAction actionWithTitle:WFCString(@"OK") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *name = alert.textFields.firstObject.text;
        if (name.length == 0) {
            return;
        }
        [[WFCUConfigManager globalManager].panServiceProvider createDoc:type name:name success:^(WFCUPanFile *file) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (file) {
                    [ws openDoc:file.fileId];
                } else {
                    [ws.view makeToast:WFCString(@"CreateFileRecordFailed") duration:1 position:CSToastPositionCenter];
                }
            });
        } error:^(int errorCode, NSString *message) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [ws.view makeToast:(message.length ? message : WFCString(@"CreateFileRecordFailed")) duration:1 position:CSToastPositionCenter];
            });
        }];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:WFCString(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)onLicenses:(id)sender {
    NSString *url = [WFCUPanDocUtils licensesUrl];
    if (url.length == 0) {
        return;
    }
    WFCUBrowserViewController *vc = [[WFCUBrowserViewController alloc] init];
    vc.url = url;
    vc.hidenOpenInBrowser = YES;
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)openDoc:(NSInteger)fileId {
    NSString *url = [WFCUPanDocUtils docOpenUrl:fileId];
    if (url.length == 0) {
        return;
    }
    WFCUBrowserViewController *vc = [[WFCUBrowserViewController alloc] init];
    vc.url = url;
    vc.hidenOpenInBrowser = YES;
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return self.recentDocs.count;
    }
    return 1; // 开源许可
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0 && self.recentDocs.count) {
        return WFCString(@"RecentDocs");
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellId = @"docCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellId];
    }
    if (indexPath.section == 0) {
        WFCUPanFile *file = self.recentDocs[indexPath.row];
        cell.textLabel.text = file.name;
        NSString *sizeText = file.sizeText;
        NSString *time = file.openedAt.length ? file.openedAt : @"";
        cell.detailTextLabel.text = time.length ? [NSString stringWithFormat:@"%@ · %@", sizeText, time] : sizeText;
        cell.detailTextLabel.textColor = [UIColor grayColor];
        cell.imageView.image = [self iconForFile:file.name];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        cell.textLabel.text = WFCString(@"OpenSourceLicense");
        cell.detailTextLabel.text = nil;
        cell.imageView.image = nil;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    return cell;
}

- (UIImage *)iconForFile:(NSString *)name {
    NSString *ext = [[name pathExtension] lowercaseString];
    if ([@[@"doc", @"docx", @"docm", @"dot", @"dotx", @"odt", @"rtf", @"txt", @"wps"] containsObject:ext]) {
        return [WFCUImage imageNamed:@"file_type_word"];
    } else if ([@[@"xls", @"xlsx", @"xlsm", @"csv", @"ods", @"et"] containsObject:ext]) {
        return [WFCUImage imageNamed:@"file_type_xls"];
    } else if ([@[@"ppt", @"pptx", @"pptm", @"odp", @"dps"] containsObject:ext]) {
        return [WFCUImage imageNamed:@"file_type_ppt"];
    } else if ([ext isEqualToString:@"pdf"]) {
        return [WFCUImage imageNamed:@"file_type_pdf"];
    }
    return [WFCUImage imageNamed:@"file_icon"];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0) {
        WFCUPanFile *file = self.recentDocs[indexPath.row];
        [self openDoc:file.fileId];
    } else {
        [self onLicenses:nil];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == 0;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle != UITableViewCellEditingStyleDelete || indexPath.section != 0) {
        return;
    }
    WFCUPanFile *file = self.recentDocs[indexPath.row];
    __weak typeof(self) ws = self;
    [[WFCUConfigManager globalManager].panServiceProvider removeRecentDoc:file.fileId success:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [ws.recentDocs removeObjectAtIndex:indexPath.row];
            [ws.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        });
    } error:^(int errorCode, NSString *message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [ws.view makeToast:(message.length ? message : WFCString(@"NetworkError")) duration:1 position:CSToastPositionCenter];
        });
    }];
}

@end
