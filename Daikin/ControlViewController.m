//
//  ControlViewController.m
//  Daikin
//
//  Created by smile.zhang on 16/10/6.
//  Copyright © 2016年 周建政. All rights reserved.
//

#import "ControlViewController.h"
#import "ESPSocketClient2.h"

#define SO_CONNECT_RETRY                3
#define SO_TIMEOUT                      4000
#define SO_CONNECT_TIMEOUT              2000
#define DEVICE_MESH_PORT                8899
#define SO_CONNECT_INTERVAL             500

@interface ControlViewController ()
@property (nonatomic, strong) TerminalModel *terminal;
@property (nonatomic, strong) UIButton *button1;
@property (nonatomic, strong) UIButton *button2;
@property (nonatomic, strong) UITextView *textView;
// let ESPMeshSocket be executed completely even app entered background
@property (nonatomic,assign) __block UIBackgroundTaskIdentifier _backgroundTask;
@property (nonatomic, strong) __block ESPSocketClient2 *socket;
@property (nonatomic, strong) __block NSString *targetInetAddr;
@property (nonatomic, assign) __block BOOL isClosed;

@end

NSString* recvStr;
BOOL isNeedUpdateUI = false;

@implementation ControlViewController
- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil terminal:(TerminalModel *)terminal {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        _terminal = terminal;
        _targetInetAddr = terminal.ip;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"控制中心";
    // Do any additional setup after loading the view from its nib.
    NSLog(@"Pass IP is %@", _terminal.ip);
    [self button1];
    [self button2];
    [self textView];
    [self createTcpClientTask];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    NSLog(@"didReceiveMemoryWarning.........");
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
    if ([self isConnected] && !_isClosed) {
        [_socket writeStr:@"gettemperature"];
        NSLog(@"get temperature command.......");
    }
}

- (void)click2 {
    [self addString:@"按钮2"];
}

- (void)createTcpClientTask {
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        [self loop];
    });
    /*dispatch_async(dispatch_get_main_queue(), ^{
     // Your UI code
     while (isNeedUpdateUI)
     {
         [self addString:recvStr];
         isNeedUpdateUI = false;
     }
     
     });*/
}
- (void) beginBackgroundTask
{
 
    NSLog(@"ESPMeshSocket beginBackgroundTask() entrance");
    
    self._backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            NSLog(@"ESPMeshSocket beginBackgroundTask() endBackgroundTask");
        [self endBackgroundTask];
    }];
}

- (void) endBackgroundTask
{
    NSLog(@"ESPMeshSocket endBackgroundTask() entrance");
    [[UIApplication sharedApplication] endBackgroundTask: self._backgroundTask];
    self._backgroundTask = UIBackgroundTaskInvalid;
}

- (ESPSocketClient2 *) open:(NSString *)remoteInetAddr
{
    ESPSocketClient2 *socket = nil;
    
    BOOL isConnected = NO;
    for (int retry = 0; !isConnected && retry < SO_CONNECT_RETRY; ++retry) {
        // connect to target device(root device)
        socket = [[ESPSocketClient2 alloc]init];
        [socket setSoTimeout:SO_TIMEOUT];
        [socket setConnTimeout:SO_CONNECT_TIMEOUT];
        // socket will be closed automatically
        if ([socket connect:remoteInetAddr Port:DEVICE_MESH_PORT]) {
            isConnected = YES;
            break;
        } else {
            NSLog(@"connect failed.........");
            if (retry < SO_CONNECT_RETRY-1) {
                [NSThread sleepForTimeInterval:SO_CONNECT_INTERVAL/1000.0];
            }
        }
    }
    if (!isConnected) {
        NSString *msg = [NSString stringWithFormat:@"open() fail for remoteInetAddr:%@, return null",remoteInetAddr];
        NSLog(@"%@", msg);
        if (_socket != nil) {
            [_socket close];
        }
        return nil;
    } else {
        NSLog(@"open success for remoteInetAddr:%@",remoteInetAddr);
        return socket;
    }
}

- (BOOL) isConnected
{
    return _socket != nil && [_socket isConnected];
}

- (BOOL) isClosed
{
    return (_socket != nil && [_socket isClosed]) || _isClosed;
}

- (NSString *)hexStringFromString:(NSData *)myD{
 
    Byte *bytes = (Byte *)[myD bytes];
    //下面是Byte 转换为16进制。
    NSString *hexStr=@"";
    for(int i=0;i<[myD length];i++)
        
    {
        NSString *newHexStr = [NSString stringWithFormat:@"%x",bytes[i]&0xff];///16进制数
        
        if([newHexStr length]==1)
            hexStr = [NSString stringWithFormat:@"%@0%@",hexStr,newHexStr];
        else
            hexStr = [NSString stringWithFormat:@"%@%@",hexStr,newHexStr]; 
    } 
    return hexStr; 
}

- (void) loop
{
    [self beginBackgroundTask];
    // connect to the target
    if (_socket == nil) {
        NSLog(@"Open one socket");
        _socket = [self open:_targetInetAddr];
    }
    while ([self isConnected] && !_isClosed) {
        //NSLog(@"recv.......");
        NSData * recvBuffer = [_socket readData];
        recvStr = [self hexStringFromString:recvBuffer];
        //recvStr = NSDataToHex(recvBuffer);
        if ([recvStr length] > 0) {
            NSLog(@"DATA:%@", recvStr);
            //isNeedUpdateUI = true;
            [_socket writeStr:@"ok"];
        }
     }
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
        [button setTitle:@"获取温度" forState:UIControlStateNormal];
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
        [button setTitle:@"获取camera" forState:UIControlStateNormal];
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

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    NSLog(@"navigate back.....");
    if (_socket != nil) {
        [_socket close];
    }
}
@end
