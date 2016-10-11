//
//  ControlViewController.m
//  Daikin
//
//  Created by smile.zhang on 16/10/6.
//  Copyright © 2016年 周建政. All rights reserved.
//

#import "ControlViewController.h"

@interface ControlViewController ()
@property (nonatomic, strong) TerminalModel *terminal;
@property (nonatomic, strong) UIButton *button1;
@property (nonatomic, strong) UIButton *button2;
@property (nonatomic, strong) UITextView *textView;
@end

@implementation ControlViewController
- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil terminal:(TerminalModel *)terminal {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        _terminal = terminal;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"控制中心";
    // Do any additional setup after loading the view from its nib.

    [self button1];
    [self button2];
    [self textView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - Private
- (void)click1 {
    [self addString:@"按钮1"];
}

- (void)click2 {
    [self addString:@"按钮2"];
}

- (CGFloat)viewWidth {
    return [UIScreen mainScreen].bounds.size.width;
}

- (void)addString:(NSString *)string {
    // 如果添加字符串为空，或nil等不合法字符串，直接终止该方法
    if (!string || string.length == 0) {
        return;
    }
    self.textView.text = [self.textView.text stringByAppendingString:[NSString stringWithFormat:@"\n %@",string]];
    NSRange range = [self.textView.text rangeOfString:string options:NSBackwardsSearch]; // 从后往前搜索
    [self.textView scrollRangeToVisible:range]; // 滚动到指定位置
}

#pragma mark - Getter
- (UIButton *)button1 {
    if (!_button1) {
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(50, 120, self.viewWidth - 100, 44)];
        [button setTitle:@"按钮1" forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont systemFontOfSize:15];
        [button setBackgroundColor:[UIColor whiteColor]];
        [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        button.layer.cornerRadius = 3.0;
        button.layer.borderColor = [UIColor blueColor].CGColor;
        button.layer.borderWidth = 1.0;
        [button addTarget:self action:@selector(click1) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:button];
        _button1 = button;
    }
    return _button1;
}

- (UIButton *)button2 {
    if (!_button2) {
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(50, 200, self.viewWidth - 100, 44)];
        [button setTitle:@"按钮2" forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont systemFontOfSize:14];
        [button setBackgroundColor:[UIColor whiteColor]];
        [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        button.layer.cornerRadius = 3.0;
        button.layer.borderColor = [UIColor blueColor].CGColor;
        button.layer.borderWidth = 1.0;
        [button addTarget:self action:@selector(click2) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:button];
        _button2 = button;
    }
    return _button2;
}

- (UITextView *)textView {
    if (!_textView) {
        UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(30, 280, self.viewWidth - 60, 150)];
        textView.backgroundColor = [UIColor whiteColor];
        textView.font = [UIFont systemFontOfSize:14];
        textView.layer.cornerRadius = 3.0;
        textView.layer.borderColor = [UIColor blueColor].CGColor;
        textView.layer.borderWidth = 1.0;
        [self.view addSubview:textView];
        _textView = textView;
    }
    return _textView;
}

@end
