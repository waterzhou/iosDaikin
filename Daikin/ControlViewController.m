//
//  ControlViewController.m
//  Daikin
//
//  Created by smile.zhang on 16/10/6.
//  Copyright © 2016年 周建政. All rights reserved.
//

#import "ControlViewController.h"
#import "UIViewController+HUD.h"
#import "NSTimer+Block.h"
#import "NSTimer+Addition.h"
#import "ESPSocketClient2.h"
#import "YRConvert.h"

#define SO_CONNECT_RETRY                3
#define SO_TIMEOUT                      4000
#define SO_CONNECT_TIMEOUT              2000
#define DEVICE_MESH_PORT                8899
#define SO_CONNECT_INTERVAL             500

#define TimeStep 1
#define MaxTime 5  //* 60

static float kc_width  = 176;
static float kc_height = 144;
static float kt_width = 96;
static float kt_height = 46;
static int kc_size = 25344;
static int kt_size = 4416;

@interface ControlViewController (){
    NSMutableString *_cameraString; // 相机字符串
    NSMutableData *_cameraData; // 相机二进制
    NSMutableString *_temperatureString; // 温度字符串
    NSMutableData *_temperatureData; // 温度二进制
}

@property (nonatomic, strong) TerminalModel *terminal;
@property (nonatomic, strong) UIButton *button1;
@property (nonatomic, strong) UIButton *button2;
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) UIImageView *imageView;
// let ESPMeshSocket be executed completely even app entered background
@property (nonatomic,assign) __block UIBackgroundTaskIdentifier _backgroundTask;
@property (nonatomic, strong) __block ESPSocketClient2 *socket;
@property (nonatomic, strong) __block NSString *targetInetAddr;
@property (nonatomic, assign) __block BOOL isClosed;
@property (nonatomic, strong) NSTimer *timer; // 定时器
@property (nonatomic, assign) NSUInteger times; // 次数
@property (nonatomic, assign) NSInteger type; // 0表示温度，1表示camera
@property (nonatomic, assign) NSUInteger second; // 时长(秒钟)

@end

//NSString* recvStr;
//BOOL isNeedUpdateUI = false;

@implementation ControlViewController
- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil terminal:(TerminalModel *)terminal {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        _terminal = terminal;
        _targetInetAddr = terminal.ip;
        _type = -1;
        _times = 0;
        [self clearData];
        [self.timer pauseTimer];
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
//    [self textView];
    [self imageView];
    [self createTcpClientTask];

    // 测试文件格式Camera数据转成RGB图片
//    [self showTestCameraToRGB];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    NSLog(@"didReceiveMemoryWarning.........");
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    NSLog(@"navigate back.....");
    if (_socket != nil) {
        [_socket close];
    }

    [self.timer pauseTimer];
    _timer = nil;
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
    _type = 0;
    _times = 0;
    _second = 0;
    [self.timer resumeTimer];
    [self clearData];
    __weak typeof(self) ws = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [ws showHudWithTitle:@"正在接收温度数据……"];
    });
    if ([self isConnected] && !_isClosed) {
        [_socket writeStr:@"gettemperature"];
        NSLog(@"get temperature command.......");
    }
}

- (void)click2 {
    _type = 1;
    _times = 0;
    _second = 0;
    [self.timer resumeTimer];
    [self clearData];
    [self showHudWithTitle:@"正在接收Camera数据……"];
    if ([self isConnected] && !_isClosed) {
        [_socket writeStr:@"getpicture"];
        NSLog(@"get picture command.......");
    }
//    [self showTestYUV422UYVYToRGB];
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

- (void) beginBackgroundTask {
    NSLog(@"ESPMeshSocket beginBackgroundTask() entrance");
    self._backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            NSLog(@"ESPMeshSocket beginBackgroundTask() endBackgroundTask");
        [self endBackgroundTask];
    }];
}

- (void) endBackgroundTask {
    NSLog(@"ESPMeshSocket endBackgroundTask() entrance");
    [[UIApplication sharedApplication] endBackgroundTask: self._backgroundTask];
    self._backgroundTask = UIBackgroundTaskInvalid;
}

- (ESPSocketClient2 *) open:(NSString *)remoteInetAddr {
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

- (BOOL) isConnected {
    return _socket != nil && [_socket isConnected];
}

- (BOOL) isClosed {
    return (_socket != nil && [_socket isClosed]) || _isClosed;
}

- (NSString *)hexStringFromString:(NSData *)myD{
 
    Byte *bytes = (Byte *)[myD bytes];
    //下面是Byte 转换为16进制。
    NSString *hexStr = @"";
    for (int i = 0; i < [myD length]; i++) {
        NSString *newHexStr = [NSString stringWithFormat:@"%x",bytes[i]&0xff];///16进制数
        
        if([newHexStr length]==1)
            hexStr = [NSString stringWithFormat:@"%@0%@",hexStr,newHexStr];
        else
            hexStr = [NSString stringWithFormat:@"%@%@",hexStr,newHexStr]; 
    } 
    return hexStr; 
}

- (void) loop {
    [self beginBackgroundTask];
    // connect to the target
    if (_socket == nil) {
        NSLog(@"Open one socket");
        _socket = [self open:_targetInetAddr];
    }

    while ([self isConnected] && !_isClosed) {
        //NSLog(@"recv.......");
        NSData * recvBuffer = [_socket readData];
        NSString *recvStr = [self hexStringFromString:recvBuffer];
        //recvStr = NSDataToHex(recvBuffer);
        if ([recvStr length] > 0) {
            if (self.times == 0) {
                [self clearData];
            }
            _times += 1;
            //NSLog(@"DATA:%@  times = %ld", recvStr, (unsigned long)self.times);
            //isNeedUpdateUI = true;
            
            if (_type == 0) {
                [_socket writeStr:@"ok"];
                [_temperatureData appendData:recvBuffer];
                [_temperatureString appendString:recvStr];
                if (self.times == 37) {
                    // 接收完成
                    [self stopReceiveData];
                    // 存储，展示
                    NSError *error;
                    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES)firstObject];
                    NSString *temperaturePath = [documentsPath stringByAppendingPathComponent:@"temperature.txt"];
                    BOOL isSucceed = [_temperatureString writeToFile:temperaturePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
                    [_temperatureData writeToFile:[documentsPath stringByAppendingString:@"t_data"] atomically:YES];
                    if (isSucceed) {
                        NSLog(@"写入温度数据成功");
                        __weak typeof(self) ws = self;
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [ws showTemperatureImage];
                        });
                    } else {
                        if (error) {
                            NSLog(@"写入温度数据失败：%@",error);
                        }
                    }
                }
            } else if (_type == 1) {
                // 4*1024=2920+1176
                //NSLog(@"len =%d", [recvStr length]);
                NSLog(@"times=%lu", (unsigned long)self.times);
                //int count=[[NSString stringWithFormat:@"%u",self.times]intValue];
                //NSLog(@"count=%d", count);

                if (self.times % 2 == 0) {
                    NSLog(@"will send back ACK");
                    [_socket writeStr:@"cameraok"];
                }

                [_cameraData appendData:recvBuffer];
                [_cameraString appendString:recvStr];
                //camera total is 150 times here should *2
                if (self.times == 150 * 2) {
                    NSLog(@"already complete one picture");
                    // 接收完成
                    [self stopReceiveData];
                    // 存储，展示
                    NSError *error;
                    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES)firstObject];
                    NSString *cameraPath = [documentsPath stringByAppendingPathComponent:@"camera.txt"];
                    BOOL isSucceed = [_cameraString writeToFile:cameraPath atomically:YES encoding:NSUTF8StringEncoding error:&error];
                    [_cameraData writeToFile:[documentsPath stringByAppendingPathComponent:@"c_data"] atomically:YES];
                    if (isSucceed) {
                        NSLog(@"写入YUV数据成功");
                        __weak typeof(self) ws = self;
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [ws showCameraImage];
                        });
                    } else {
                        if (error) {
                            NSLog(@"写入YUV数据失败：%@",error);
                        }
                    }
                }
            }
            if (self.second == MaxTime) {
                // 停止获取数据
                [self stopReceiveData];
                [self clearData];
            }
        }
     }
}

- (void)clearData {
    _temperatureString = [NSMutableString string];
    _temperatureData = [NSMutableData data];
    _cameraString = [NSMutableString string];
    _cameraData = [NSMutableData data];
}

- (void)stopReceiveData {
    __weak typeof(self) ws = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [ws hideHud];
    });
    [self.timer pauseTimer];
    self.times = 0;
    self.second = 0;
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

- (NSTimer *)timer {
    if (!_timer) {
        __weak typeof(self) ws = self;
        _timer = [NSTimer xw_scheduledTimerWithTimeInterval:TimeStep repeats:YES block:^{
            ws.second += TimeStep;
            NSLog(@"第%lu秒钟",(unsigned long)ws.second);
            if (ws.second == MaxTime) {
                [ws stopReceiveData];
                [ws clearData];
            }
        }];
        [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSDefaultRunLoopMode];
    }
    return _timer;
}

- (UIImageView *)imageView {
    if (!_imageView) {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.button2.frame) + 50, CGRectGetWidth(self.view.bounds), kc_height)];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.layer.cornerRadius = 3.0;
        imageView.layer.borderColor = [UIColor blueColor].CGColor;
        imageView.layer.borderWidth = 1.0;
        [self.view addSubview:imageView];
        _imageView = imageView;
    }
    return _imageView;
}


#pragma mark - Conver
// 真正YUV422的文件转成RGB，且是UYVY
- (void)showTestYUV422UYVYToRGB {
    __weak typeof(self) ws = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [ws showHudWithTitle:@"图片获取中……"];
    });
    NSString *fileName = @"tulips_uyvy422_prog_packed_qcif.yuv";
    NSString *file = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:fileName];
    NSData *reader = [NSData dataWithContentsOfFile:file];
    unsigned char *yuvBuf = (unsigned char *)[reader bytes];
    unsigned char rgbbuf[101376] = {0};
    yuv422packed_to_rgb24(FMT_UYVY, yuvBuf, rgbbuf, kc_width, kc_height);
    UIImage *img = [[self class] convertBitmapRGBA8ToUIImage:rgbbuf withWidth:kc_width withHeight:kc_height];
    self.imageView.image = img;
    CGFloat s_width = self.view.bounds.size.width;
    self.imageView.frame = CGRectMake((s_width - kc_width) / 2, CGRectGetMaxY(self.button2.frame) + 50, kc_width, kc_height);
    dispatch_async(dispatch_get_main_queue(), ^{
        [ws hideHud];
    });
}

// 文本温度文件转RGB图片并显示
- (void)showTestTemperatureToRGB {
    NSString *fileName = @"temp13.txt";
    NSString *file = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:fileName];
    NSData *reader = [NSData dataWithContentsOfFile:file];

    NSString *string = [[NSString alloc] initWithData:reader encoding:NSUTF8StringEncoding];
    reader = [self convertHexStrToData:string];
    unsigned char *yuvBuf = (unsigned char *)[reader bytes];
    unsigned char rgbbuf[13248] = {0}; // 17664
    temperature_to_rgb24(yuvBuf, rgbbuf, kt_width, kt_height);
    UIImage *img = [[self class] convertBitmapRGBA8ToUIImage:rgbbuf withWidth:kt_width withHeight:kt_height];
    self.imageView.image = img;
}

// 文本Camera文件转RGB图片并显示
- (void)showTestCameraToRGB {
    // 测试使用Picture.txt文件转换成RGB显示，原理如下：
    /**
     * 1. 读取字符串，剔除回车和换行符
     * 2. 字符串转成buffer
     * 3. YUV422转成RGB24，可以设置YUV422的格式的
     * 4. 显示图片
     */
    NSString *fileName = @"Picture.txt";
    NSString *file = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:fileName];
    NSData *reader = [NSData dataWithContentsOfFile:file];

    NSString *string = [[NSString alloc] initWithData:reader encoding:NSUTF8StringEncoding];
    string = [string stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    string = [string stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    reader = [self convertHexStrToData:string];
    unsigned char *yuvBuf = (unsigned char *)[reader bytes];
    unsigned char rgbbuf[101376] = {0};
    
#warning 重要的类型设置，高宽设置
    //==============================================================================
    // 第一个参数可以设置YUV422参数，高宽可以修改常量值
    yuv422packed_to_rgb24(FMT_UYVY, yuvBuf, rgbbuf, kc_width, kc_height);
    //==============================================================================


    UIImage *img = [[self class] convertBitmapRGBA8ToUIImage:rgbbuf withWidth:kc_width withHeight:kc_height];
    self.imageView.image = img;
//    CGRect frame = self.imageView.frame;
    self.imageView.frame = CGRectMake(0, CGRectGetMaxY(self.button2.frame) + 50, CGRectGetWidth(self.view.bounds), kc_height);
}

// 根据接收的温度数据显示图片
- (void)showTemperatureImage {
    if (self.imageView.image) {
        self.imageView.image = nil;
    }
    if (_temperatureData.length > kt_size) {
        [self showHudWithTitle:@"正在显示……"];
        unsigned char *yuvBuf = (unsigned char *)[_temperatureData bytes];
        unsigned char rgbbuf[13248] = {0}; // 17664
        temperature_to_rgb24(yuvBuf, rgbbuf, kt_width, kt_height);
        UIImage *img = [[self class] convertBitmapRGBA8ToUIImage:rgbbuf withWidth:kt_width withHeight:kt_height];
        self.imageView.image = img;
        CGRect frame = self.imageView.frame;
        self.imageView.frame = CGRectMake((CGRectGetWidth(self.view.bounds) - kt_width)/2, frame.origin.y, kt_width, kt_height);
        [self hideHud];
    } else {
        NSLog(@"显示温度图像错误：越界");
    }

}

// 根据接收的Camera数据显示图片
- (void)showCameraImage {
    if (self.imageView.image) {
        self.imageView.image = nil;
    }
    if (_cameraData.length >= kc_size * 2) {
        [self showHudWithTitle:@"正在显示……"];
//        NSData *reader = [_cameraData subdataWithRange:NSMakeRange(0, kc_size * 2)];
        unsigned char *yuvBuf = (unsigned char *)[_cameraData bytes];
        unsigned char rgbbuf[101376] = {0};
        yuv422packed_to_rgb24(FMT_UYVY, yuvBuf, rgbbuf, kc_width, kc_height);
        UIImage *img = [[self class] convertBitmapRGBA8ToUIImage:rgbbuf withWidth:kc_width withHeight:kc_height];
        self.imageView.image = img;
        CGRect frame = self.imageView.frame;
        self.imageView.frame = CGRectMake((CGRectGetWidth(self.view.bounds) - kc_width)/2, frame.origin.y, kc_width, kc_height);
        [self hideHud];
    } else {
        NSLog(@"显示Camera图像错误：越界");
    }
}

//十六进制字符串转换成NSData
- (NSData *)convertHexStrToData:(NSString *)str {
    if (!str || [str length] == 0) {
        return nil;
    }

    NSMutableData *hexData = [[NSMutableData alloc] initWithCapacity:8];
    NSRange range;
    if ([str length] % 2 == 0) {
        range = NSMakeRange(0, 2);
    } else {
        range = NSMakeRange(0, 1);
    }
    for (NSInteger i = range.location; i < [str length]; i += 2) {
        unsigned int anInt;
        NSString *hexCharStr = [str substringWithRange:range];
        NSScanner *scanner = [[NSScanner alloc] initWithString:hexCharStr];

        [scanner scanHexInt:&anInt];
        NSData *entity = [[NSData alloc] initWithBytes:&anInt length:1];
        [hexData appendData:entity];

        range.location += range.length;
        range.length = 2;
    }
    return hexData;
}

- (void)setImageViewSize:(CGSize)size {
    CGRect frame = self.imageView.frame;
    self.imageView.frame = CGRectMake(frame.origin.x, frame.origin.y, size.width, size.height);
}

+ (UIImage *) convertBitmapRGBA8ToUIImage:(unsigned char *) buffer
                                withWidth:(int) width
                               withHeight:(int) height {

    // added code
    char* rgba = (char*)malloc(width*height*4);
    for(int i=0; i < width*height; ++i) {
        rgba[4*i] = buffer[3*i];
        rgba[4*i+1] = buffer[3*i+1];
        rgba[4*i+2] = buffer[3*i+2];
        rgba[4*i+3] = 255;
    }
    //

    size_t bufferLength = width * height * 4;
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, rgba, bufferLength, NULL);
    size_t bitsPerComponent = 8;
    size_t bitsPerPixel = 32;
    size_t bytesPerRow = 4 * width;

    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    if(colorSpaceRef == NULL) {
        NSLog(@"Error allocating color space");
        CGDataProviderRelease(provider);
        return nil;
    }

    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;

    CGImageRef iref = CGImageCreate(width,
                                    height,
                                    bitsPerComponent,
                                    bitsPerPixel,
                                    bytesPerRow,
                                    colorSpaceRef,
                                    bitmapInfo,
                                    provider,   // data provider
                                    NULL,       // decode
                                    YES,            // should interpolate
                                    renderingIntent);

    uint32_t* pixels = (uint32_t*)malloc(bufferLength);

    if(pixels == NULL) {
        NSLog(@"Error: Memory not allocated for bitmap");
        CGDataProviderRelease(provider);
        CGColorSpaceRelease(colorSpaceRef);
        CGImageRelease(iref);
        return nil;
    }

    CGContextRef context = CGBitmapContextCreate(pixels,
                                                 width,
                                                 height,
                                                 bitsPerComponent,
                                                 bytesPerRow,
                                                 colorSpaceRef,
                                                 bitmapInfo);

    if(context == NULL) {
        NSLog(@"Error context not created");
        free(pixels);
    }

    UIImage *image = nil;
    if(context) {

        CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, width, height), iref);

        CGImageRef imageRef = CGBitmapContextCreateImage(context);

        // Support both iPad 3.2 and iPhone 4 Retina displays with the correct scale
        if([UIImage respondsToSelector:@selector(imageWithCGImage:scale:orientation:)]) {
            float scale = [[UIScreen mainScreen] scale];
            image = [UIImage imageWithCGImage:imageRef scale:scale orientation:UIImageOrientationUp];
        } else {
            image = [UIImage imageWithCGImage:imageRef];
        }

        CGImageRelease(imageRef);
        CGContextRelease(context);
    }

    CGColorSpaceRelease(colorSpaceRef);
    CGImageRelease(iref);
    CGDataProviderRelease(provider);
    
    if(pixels) {
        free(pixels);
    }
    return image;
}



@end
