//
//  AddViewController.m
//  Daikin
//
//  Created by smile.zhang on 16/10/6.
//  Copyright © 2016年 周建政. All rights reserved.
//

#import "AddViewController.h"

@interface AddViewController ()
@end

@implementation AddViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"添加设备";
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Private
- (IBAction)addterminal:(id)sender {
    // 组织模型
    TerminalModel *terminal = [[TerminalModel alloc] init];
    // 给模型赋值
    terminal.ip = @"127.0.0.10";
    terminal.name = @"新设备";
    terminal.ssid = @"SDKJSUIJKLJSDGXVKJLDSFJLKJGKLSDGKL";
    terminal.isOn = NO;
    // 模型回传，直接传至上一个界面
    if (self.delegate) {
        [self.delegate addTermainal:terminal];
    }
    [self.navigationController popViewControllerAnimated:YES];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
