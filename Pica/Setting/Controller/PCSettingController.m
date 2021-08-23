//
//  PCSettingController.m
//  Pica
//
//  Created by YueCheng on 2021/5/28.
//  Copyright © 2021 fancy. All rights reserved.
//

#import "PCSettingController.h"
#import "PCPasswordSetRequest.h"
#import "AppDelegate.h"
#import <SafariServices/SafariServices.h>
#import "PCTabBarViewController.h"
#import "PCColorPickerViewController.h"
#import "PCChatMessage.h"
#import "PCAvatarDecorateController.h"

@interface PCSettingController ()

@property (nonatomic, copy)   NSArray <NSArray *>*dataSource;
@property (nonatomic, strong) PCPasswordSetRequest *passwordSetRequest;
@property (nonatomic, strong) QMUIButton *logoutButton;

@end

@implementation PCSettingController

- (void)viewDidLoad {
    [super viewDidLoad];
     
}

- (void)setupNavigationItems {
    [super setupNavigationItems];
    
    self.title = @"设置";
}

- (void)initTableView {
    [super initTableView];
    
    self.tableView.tableFooterView = [self tableFooterView];
}

#pragma mark - Table
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.dataSource.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource[section].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"cell";
    QMUITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[QMUITableViewCell alloc] initForTableView:tableView withStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];
    }
    
    cell.textLabel.text = self.dataSource[indexPath.section][indexPath.row];
    if (indexPath.section == 0 && indexPath.row == 0) {
        __block long long fileSize = 0;
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            fileSize += [[SDImageCache sharedImageCache] totalDiskSize];
            fileSize += [[[[NSFileManager defaultManager] attributesOfItemAtPath:[PCChatMessage dbPath] error:nil] objectForKey:NSFileSize] integerValue];
            fileSize += [[[[NSFileManager defaultManager] attributesOfItemAtPath:[self networkCachePath] error:nil] objectForKey:NSFileSize] integerValue];
            dispatch_async(dispatch_get_main_queue(), ^{
                cell.detailTextLabel.text = [NSByteCountFormatter stringFromByteCount:fileSize countStyle:NSByteCountFormatterCountStyleFile];
            });
        }); 
    } else {
        cell.detailTextLabel.text = nil;
    }
    
    if (indexPath.section == 0 && (indexPath.row == 2 || indexPath.row == 3 || indexPath.row == 4 || indexPath.row == 5)) {
        if (![cell.accessoryView isKindOfClass:[UISwitch class]]) {
            UISwitch *switchView = [[UISwitch alloc] init];
            NSString *key = nil;
            
            switch (indexPath.row) {
                case 2:
                    key = PC_DATA_TO_SIMPLIFIED_CHINESE;
                    break;
                case 3:
                    key = PC_TAB_GAME_HIDDEN;
                    break;
                case 4:
                    key = PC_CHAT_EVENT_COLOR_ON;
                    break;
                case 5:
                    key = PC_CHAT_AVATAR_CHARACTER_ON;
                    break;
                default:
                    break;
            }
            switchView.on = [kPCUserDefaults integerForKey:key];
            [switchView addTarget:self action:@selector(switchAction:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = switchView;
        }
    } else {
        cell.accessoryView = nil;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0) {
        switch (indexPath.row) {
            case 0:
                [self showClearCacheAlert];
                break;
            case 1:
                [self showUpdatePasswordAlert];
                break;
            case 4:
                [self selectColor];
                break;
            case 5:
                [self selectAvatarDecorate];
                break;
            default:
                break;
        }
    } else {
        SFSafariViewController *safari = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:@"https://github.com/fanyuecheng/Pica"]];
        [self presentViewController:safari animated:YES completion:nil];
    }
}

#pragma mark - Method
- (UIView *)tableFooterView {
    UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_HEIGHT, 200)];
    [footer addSubview:self.logoutButton];
    
    QMUILabel *versionLabel = [[QMUILabel alloc] qmui_initWithFont:UIFontMake(10) textColor:UIColorGray];
    versionLabel.text = [NSString stringWithFormat:@"Pica 版本号 %@", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    versionLabel.textAlignment = NSTextAlignmentCenter;
    versionLabel.frame = CGRectMake(10, self.logoutButton.qmui_bottom + 50, SCREEN_WIDTH - 20, QMUIViewSelfSizingHeight);
    [footer addSubview:versionLabel];
    return footer;
}

- (void)showClearCacheAlert {
    QMUIAlertAction *action1 = [QMUIAlertAction actionWithTitle:@"确定" style:QMUIAlertActionStyleDefault handler:^(__kindof QMUIAlertController *aAlertController, QMUIAlertAction *action) {
        [[SDImageCache sharedImageCache] clearDiskOnCompletion:^{
            [PCChatMessage deleteObjectsWhere:nil arguments:nil];
            [[NSFileManager defaultManager] removeItemAtPath:[self networkCachePath] error:nil];
//            [kPCUserDefaults removeObjectForKey:PC_LOCAL_ACCOUNT];
            [self.tableView reloadData];
        }];
    }];
    
    QMUIAlertAction *action2 = [QMUIAlertAction actionWithTitle:@"取消" style:QMUIAlertActionStyleCancel handler:nil];
    
    QMUIAlertController *alertController = [QMUIAlertController alertControllerWithTitle:@"确认清除缓存?" message:nil preferredStyle:QMUIAlertControllerStyleAlert];
    
    [alertController addAction:action1];
    [alertController addAction:action2];
    [alertController showWithAnimated:YES];
}
 
- (void)showUpdatePasswordAlert {
    QMUIAlertAction *action1 = [QMUIAlertAction actionWithTitle:@"确定" style:QMUIAlertActionStyleDefault handler:^(__kindof QMUIAlertController *aAlertController, QMUIAlertAction *action) {
        self.passwordSetRequest.passwordOld = aAlertController.textFields.firstObject.text;
        self.passwordSetRequest.passwordNew = aAlertController.textFields.lastObject.text;
        [self updatePassword];
    }];
    
    QMUIAlertAction *action2 = [QMUIAlertAction actionWithTitle:@"取消" style:QMUIAlertActionStyleCancel handler:nil];
    
    QMUIAlertController *alertController = [QMUIAlertController alertControllerWithTitle:@"修改密码" message:@"请输入旧密码和新密码" preferredStyle:QMUIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(QMUITextField * _Nonnull textField) {
        textField.placeholder = @"旧密码";
    }];
    [alertController addTextFieldWithConfigurationHandler:^(QMUITextField * _Nonnull textField) {
        textField.placeholder = @"新密码";
    }];
    
    [alertController addAction:action1];
    [alertController addAction:action2];
    [alertController showWithAnimated:YES];
}

- (void)showLogoutAlert {
    QMUIAlertAction *action1 = [QMUIAlertAction actionWithTitle:@"确定" style:QMUIAlertActionStyleDefault handler:^(__kindof QMUIAlertController *aAlertController, QMUIAlertAction *action) {
        [kPCUserDefaults removeObjectForKey:PC_AUTHORIZATION_TOKEN];
        AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        [delegate setRootViewControllerToLogin];
    }];
    
    QMUIAlertAction *action2 = [QMUIAlertAction actionWithTitle:@"取消" style:QMUIAlertActionStyleCancel handler:nil];
    
    QMUIAlertController *alertController = [QMUIAlertController alertControllerWithTitle:@"确认退出登录?" message:nil preferredStyle:QMUIAlertControllerStyleAlert];
    
    [alertController addAction:action1];
    [alertController addAction:action2];
    [alertController showWithAnimated:YES];
}

- (void)selectColor {
    PCColorPickerViewController *color = [[PCColorPickerViewController alloc] init];
    
    [self.navigationController pushViewController:color animated:YES];
}

- (void)selectAvatarDecorate {
    PCAvatarDecorateController *decorate = [[PCAvatarDecorateController alloc] init];
    [self.navigationController pushViewController:decorate animated:YES];
}

- (NSString *)networkCachePath {
    NSString *pathOfLibrary = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *path = [pathOfLibrary stringByAppendingPathComponent:@"LazyRequestCache"];
    
    return path;
}

#pragma mark - Action
- (void)logoutAction:(QMUIButton *)sender {
    [self showLogoutAlert];
}

- (void)switchAction:(UISwitch *)sender {
    NSIndexPath *indexPath = [self.tableView qmui_indexPathForRowAtView:sender];
    
    if (indexPath.row == 2) {
        [kPCUserDefaults setBool:sender.isOn forKey:PC_DATA_TO_SIMPLIFIED_CHINESE];
    } else if (indexPath.row == 3) {
        [kPCUserDefaults setBool:sender.isOn forKey:PC_TAB_GAME_HIDDEN];
        
        PCTabBarViewController *tabBarViewController = (PCTabBarViewController *)[UIApplication sharedApplication].keyWindow.rootViewController;
        [tabBarViewController reloadViewControllers];
    } else if (indexPath.row == 4) {
        [kPCUserDefaults setBool:sender.isOn forKey:PC_CHAT_EVENT_COLOR_ON];
    } else if (indexPath.row == 5) {
        [kPCUserDefaults setBool:sender.isOn forKey:PC_CHAT_AVATAR_CHARACTER_ON];
    }
}

#pragma mark - Net
- (void)updatePassword {
    if (self.passwordSetRequest.passwordOld.length &&
        self.passwordSetRequest.passwordNew.length) {
        QMUITips *loading = [QMUITips showLoadingInView:DefaultTipsParentView];
        [self.passwordSetRequest sendRequest:^(id  _Nonnull response) {
            [loading hideAnimated:YES];
            [QMUITips showSucceed:@"修改密码成功"];
        } failure:^(NSError * _Nonnull error) {
            [loading hideAnimated:YES];
        }];
    }
}

#pragma mark - Get
- (NSArray *)dataSource {
    if (!_dataSource) {
        _dataSource = @[@[@"清除缓存", @"修改密码", @"简体中文", @"隐藏游戏区", @"聊天文字颜色", @"聊天室头像装饰"], @[@"关于Pica"]];
    }
    return _dataSource;
}

- (PCPasswordSetRequest *)passwordSetRequest {
    if (!_passwordSetRequest) {
        _passwordSetRequest = [[PCPasswordSetRequest alloc] init];
    }
    return _passwordSetRequest;
}

- (QMUIButton *)logoutButton {
    if (!_logoutButton) {
        _logoutButton = [[QMUIButton alloc] initWithFrame:CGRectMake(15, 50, SCREEN_WIDTH - 30, 44)];
        _logoutButton.layer.cornerRadius = 4;
        _logoutButton.layer.masksToBounds = YES;
        _logoutButton.backgroundColor = UIColorRed;
        [_logoutButton setTitle:@"退出登录" forState:UIControlStateNormal];
        _logoutButton.titleLabel.font = UIFontBoldMake(18);
        [_logoutButton setTitleColor:UIColorWhite forState:UIControlStateNormal];
        [_logoutButton addTarget:self action:@selector(logoutAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _logoutButton;
}

@end
