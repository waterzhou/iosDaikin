//
//  TerminalModel.h
//  Daikin
//
//  Created by smile.zhang on 16/10/6.
//  Copyright © 2016年 周建政. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TerminalModel : NSObject

@property (nonatomic, strong) NSString *ip;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *ssid;
@property (nonatomic, assign) BOOL isOn;

@end
