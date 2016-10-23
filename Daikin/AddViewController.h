//
//  AddViewController.h
//  Daikin
//
//  Created by smile.zhang on 16/10/6.
//  Copyright © 2016年 周建政. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TerminalModel.h"

@protocol AddTerminalDelegate <NSObject>

- (void)addTermainal:(TerminalModel *)terminal;

@end

@interface AddViewController : UIViewController

@property (nonatomic, assign) id<AddTerminalDelegate> delegate;

@property (weak, nonatomic) IBOutlet UILabel *ssidLabel;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet UISwitch *isHiddleSsid;
@property (weak, nonatomic) IBOutlet UITextField *taskCountTextField;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activity;
@property (weak, nonatomic) IBOutlet UIButton *confirmButton;


@end
