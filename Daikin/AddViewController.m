//
//  AddViewController.m
//  Daikin
//
//  Created by smile.zhang on 16/10/6.
//  Copyright © 2016年 周建政. All rights reserved.
//

#import "AddViewController.h"
#import "ESPTouchTask.h"
#import "ESPTouchResult.h"
#import "ESP_NetUtil.h"
#import <SystemConfiguration/CaptiveNetwork.h>

// the three constants are used to hide soft-keyboard when user tap Enter or Return
#define HEIGHT_KEYBOARD 216
#define HEIGHT_TEXT_FIELD 30
#define HEIGHT_SPACE (6+HEIGHT_TEXT_FIELD)

@interface AddViewController ()
// the state of the confirm/cancel button
@property (nonatomic, assign) BOOL _isConfirmState;
// without the condition, if the user tap confirm/cancel quickly enough,
// the bug will arise. the reason is follows:
// 0. task is starting created, but not finished
// 1. the task is cancel for the task hasn't been created, it do nothing
// 2. task is created
// 3. Oops, the task should be cancelled, but it is running
@property (nonatomic, strong) NSCondition *_condition;


// to cancel ESPTouchTask when
@property (atomic, strong) ESPTouchTask *_esptouchTask;
@property (strong, nonatomic) NSString *bssid;

@end

@implementation AddViewController

// enable confirm button
- (void)enableConfirmBtn
{
    self._isConfirmState = YES;
    [self.confirmButton setTitle:@"Confirm" forState:UIControlStateNormal];
}

// enable cancel button
- (void)enableCancelBtn
{
    self._isConfirmState = NO;
    [self.confirmButton setTitle:@"Cancel" forState:UIControlStateNormal];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"添加设备";
    // Do any additional setup after loading the view from its nib.
    NSDictionary *netInfo = [self fetchNetInfo];
    self.ssidLabel.text = [netInfo objectForKey:@"SSID"];
    self.bssid = [netInfo objectForKey:@"BSSID"];
    
    self._isConfirmState = NO;
    self.passwordTextField.delegate = self;
    self.passwordTextField.keyboardType = UIKeyboardTypeASCIICapable;
    self.taskCountTextField.delegate = self;
    self.taskCountTextField.keyboardType = UIKeyboardTypeNumberPad;
    self._condition = [[NSCondition alloc]init];
    [self enableConfirmBtn];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Private
- (IBAction)addterminal:(id)sender {
    [self tapConfirmForResults];
    // 组织模型
    //TerminalModel *terminal = [[TerminalModel alloc] init];
    // 给模型赋值
    //terminal.ip = @"127.0.0.10";
    //terminal.name = @"新设备";
    //terminal.ssid = @"SDKJSUIJKLJSDGXVKJLDSFJLKJGKLSDGKL";
    //terminal.isOn = NO;
    // 模型回传，直接传至上一个界面
   // if (self.delegate) {
    //    [self.delegate addTermainal:terminal];
    //}
    //[self.navigationController popViewControllerAnimated:YES];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - the example of how to use executeForResults
- (NSArray *) executeForResults
{
    [self._condition lock];
    NSString *apSsid = self.ssidLabel.text;
    NSString *apPwd = self.passwordTextField.text;
    NSString *apBssid = self.bssid;
    BOOL isSsidHidden = [self.isHiddleSsid isOn];
    int taskCount = [self.taskCountTextField.text intValue];
    self._esptouchTask =
    [[ESPTouchTask alloc]initWithApSsid:apSsid andApBssid:apBssid andApPwd:apPwd andIsSsidHiden:isSsidHidden];
    [self._condition unlock];
    NSArray * esptouchResults = [self._esptouchTask executeForResults:taskCount];
    NSLog(@"ESPViewController executeForResult() result is: %@",esptouchResults);
    return esptouchResults;
}

- (void) tapConfirmForResults
{
    // do confirm
    if (self._isConfirmState)
    {
        [self.spinner startAnimating];
        [self enableCancelBtn];
        NSLog(@"ESPViewController do confirm action...");
        dispatch_queue_t  queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_async(queue, ^{
            NSLog(@"ESPViewController do the execute work...");
            // execute the task
            NSArray *esptouchResultArray = [self executeForResults];
            // show the result to the user in UI Main Thread
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.spinner stopAnimating];
                [self enableConfirmBtn];
                
                ESPTouchResult *firstResult = [esptouchResultArray objectAtIndex:0];
                // check whether the task is cancelled and no results received
                if (!firstResult.isCancelled)
                {
                    NSMutableString *mutableStr = [[NSMutableString alloc]init];
                    NSUInteger count = 0;
                    // max results to be displayed, if it is more than maxDisplayCount,
                    // just show the count of redundant ones
                    const int maxDisplayCount = 5;
                    if ([firstResult isSuc])
                    {
                        
                        for (int i = 0; i < [esptouchResultArray count]; ++i)
                        {
                            ESPTouchResult *resultInArray = [esptouchResultArray objectAtIndex:i];
                            [mutableStr appendString:[resultInArray description]];
                            [mutableStr appendString:@"\n"];
                            count++;
                            if (count >= maxDisplayCount)
                            {
                                break;
                            }
                        }
                        //[self.navigationController popViewControllerAnimated:YES];
                        if (count < [esptouchResultArray count])
                        {
                            [mutableStr appendString:[NSString stringWithFormat:@"\nthere's %lu more result(s) without showing\n",(unsigned long)([esptouchResultArray count] - count)]];
                        }
                        [[[UIAlertView alloc]initWithTitle:@"Execute Result" message:mutableStr delegate:nil cancelButtonTitle:@"I know" otherButtonTitles:nil]show];
                    }
                    
                    else
                    {
                        [[[UIAlertView alloc]initWithTitle:@"Execute Result" message:@"Esptouch fail" delegate:nil cancelButtonTitle:@"I know" otherButtonTitles:nil]show];
                    }
                }
                
            });
        });
    }
    // do cancel
    else
    {
        [self.spinner stopAnimating];
        [self enableConfirmBtn];
        NSLog(@"ESPViewController do cancel action...");
        [self cancel];
    }
}
#pragma mark - the example of how to cancel the executing task

- (void) cancel
{
    [self._condition lock];
    if (self._esptouchTask != nil)
    {
        [self._esptouchTask interrupt];
    }
    [self._condition unlock];
}
// when out of pwd textview, resign the keyboard
- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (![self.passwordTextField isExclusiveTouch])
    {
        [self.passwordTextField resignFirstResponder];
    }
    if (![self.taskCountTextField isExclusiveTouch]) {
        [self.taskCountTextField resignFirstResponder];
    }
}

#pragma mark -  the follow three methods are used to make soft-keyboard disappear when user finishing editing

// when textField begin editing, soft-keyboard apeear, do the callback
-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    CGRect frame = textField.frame;
    int offset = frame.origin.y - (self.view.frame.size.height - (HEIGHT_KEYBOARD+HEIGHT_SPACE));
    
    NSTimeInterval animationDuration = 0.30f;
    [UIView beginAnimations:@"ResizeForKeyboard" context:nil];
    [UIView setAnimationDuration:animationDuration];
    
    if(offset > 0)
    {
        self.view.frame = CGRectMake(0.0f, -offset, self.view.frame.size.width, self.view.frame.size.height);
    }
    
    [UIView commitAnimations];
}

// when user tap Enter or Return, disappear the keyboard
-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

// when finish editing, make view restore origin state
-(void)textFieldDidEndEditing:(UITextField *)textField
{
    self.view.frame =CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
}




- (NSDictionary *)fetchNetInfo
{
    NSArray *interfaceNames = CFBridgingRelease(CNCopySupportedInterfaces());
        NSLog(@"%s: Supported interfaces: %@", __func__, interfaceNames);
    
    NSDictionary *SSIDInfo;
    for (NSString *interfaceName in interfaceNames) {
        SSIDInfo = CFBridgingRelease(
                                     CNCopyCurrentNetworkInfo((__bridge CFStringRef)interfaceName));
                NSLog(@"%s: %@ => %@", __func__, interfaceName, SSIDInfo);
        
        BOOL isNotEmpty = (SSIDInfo.count > 0);
        if (isNotEmpty) {
            break;
        }
    }
    return SSIDInfo;
}


@end
