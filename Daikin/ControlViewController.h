//
//  ControlViewController.h
//  Daikin
//
//  Created by smile.zhang on 16/10/6.
//  Copyright © 2016年 周建政. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TerminalModel.h"

@interface ControlViewController : UIViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil terminal:(TerminalModel *)terminal;

@end
