//
//  WFCUPanDocsViewController.m
//  WFChatUIKit
//

#import "WFCUPanDocsViewController.h"
#import "WFCUPanService.h"
#import "WFCUPanFile.h"
#import "WFCUPanSharedDoc.h"
#import "WFCUPanDocUtils.h"
#import "WFCUConfigManager.h"
#import "WFCUBrowserViewController.h"
#import "WFCUImage.h"
#import "UIFont+YH.h"
#import "UIView+Toast.h"

@interface WFCUPanDocsViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UISegmentedControl *segmentedControl;
@property (nonatomic, strong) NSMutableArray<WFCUPanFile *> *recentDocs;
@property (nonatomic, strong) NSMutableArray<WFCUPanSharedDoc *> *sharedDocs;
@property (nonatomic, assign) BOOL mobileEditEnabled;
@property (nonatomic, assign) BOOL loading;
@end

@implementation WFCUPanDocsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = WFCString(@"OnlineDocs");
    self.view.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
    self.recentDocs = [NSMutableArray array];
    self.sharedDocs = [NSMutableArray array];

    self.segmentedControl = [[UISegmentedControl alloc] initWithItems:@[WFCString(@"RecentDocs"), WFCString(@"SharedWithMe")]];
    self.segmentedControl.selectedSegmentIndex = 0;
    [self.segmentedControl addTarget:self action:@selector(onTabChanged:) forControlEvents:UIControlEventValueChanged];
    self.navigationItem.titleView = self.segmentedControl;

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
    [self loadActiveTab];
}

#pragma mark - Data

- (BOOL)isSharedTab {
    return self.segmentedControl.selectedSegmentIndex == 1;
}

- (void)onTabChanged:(UISegmentedControl *)sender {
    [self.tableView reloadData];
    [self loadActiveTab];
}

- (void)loadActiveTab {
    if ([self isSharedTab]) {
        [self loadSharedDocs];
    } else {
        [self loadRecentDocs];
    }
}

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
    [self loadActiveTab];
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

- (void)loadSharedDocs {
    if (![WFCUConfigManager isPanConfigured]) {
        return;
    }
    __weak typeof(self) ws = self;
    self.loading = YES;
    [self.tableView reloadData];
    [[WFCUConfigManager globalManager].panServiceProvider getSharedDocsWithSuccess:^(NSArray<WFCUPanSharedDoc *> *docs) {
        dispatch_async(dispatch_get_main_queue(), ^{
            ws.loading = NO;
            [ws.sharedDocs removeAllObjects];
            [ws.sharedDocs addObjectsFromArray:docs];
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self isSharedTab] ? self.sharedDocs.count : self.recentDocs.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellId = @"docCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellId];
    }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    if ([self isSharedTab]) {
        WFCUPanSharedDoc *doc = self.sharedDocs[indexPath.row];
        cell.textLabel.text = doc.file.name;
        NSString *who = [self sourceTextForSharedDoc:doc];
        NSString *time = doc.sharedAt.length ? doc.sharedAt : @"";
        NSString *perm = doc.canEdit ? WFCString(@"DocCanEdit") : WFCString(@"DocCanView");
        NSMutableArray<NSString *> *parts = [NSMutableArray array];
        if (who.length) {
            [parts addObject:who];
        }
        if (time.length) {
            [parts addObject:time];
        }
        [parts addObject:perm];
        cell.detailTextLabel.text = [parts componentsJoinedByString:@" · "];
        cell.detailTextLabel.textColor = [UIColor grayColor];
        cell.imageView.image = [self iconForFile:doc.file.name];
    } else {
        WFCUPanFile *file = self.recentDocs[indexPath.row];
        cell.textLabel.text = file.name;
        NSString *sizeText = file.sizeText;
        NSString *time = file.openedAt.length ? file.openedAt : @"";
        cell.detailTextLabel.text = time.length ? [NSString stringWithFormat:@"%@ · %@", sizeText, time] : sizeText;
        cell.detailTextLabel.textColor = [UIColor grayColor];
        cell.imageView.image = [self iconForFile:file.name];
    }
    return cell;
}

- (NSString *)sourceTextForSharedDoc:(WFCUPanSharedDoc *)doc {
    NSMutableArray<NSString *> *names = [NSMutableArray array];
    for (WFCUPanShareSource *source in doc.sources) {
        NSString *name = nil;
        if ([source.targetType isEqualToString:@"GROUP"]) {
            if (source.targetName.length) {
                name = [NSString stringWithFormat:WFCString(@"ShareFromGroup"), source.targetName];
            }
        } else {
            name = source.createdByName;
        }
        if (name.length && ![names containsObject:name]) {
            [names addObject:name];
        }
    }
    return [names componentsJoinedByString:@"、"];
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
    if ([self isSharedTab]) {
        WFCUPanSharedDoc *doc = self.sharedDocs[indexPath.row];
        [self openDoc:doc.file.fileId];
    } else {
        WFCUPanFile *file = self.recentDocs[indexPath.row];
        [self openDoc:file.fileId];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return ![self isSharedTab];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle != UITableViewCellEditingStyleDelete || [self isSharedTab]) {
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
