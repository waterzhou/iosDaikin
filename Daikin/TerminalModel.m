//
//  TerminalModel.m
//  Daikin
//
//  Created by smile.zhang on 16/10/6.
//  Copyright © 2016年 周建政. All rights reserved.
//

#import "TerminalModel.h"

@implementation TerminalModel

- (instancetype)init {
    self = [super init];
    if (self) {
        // 初始化时的默认值
        _ip = @"127.0.0.1";
        _name = @"新设备";
        _ssid = @"sdfaklsdjflkajsdlfaslkdjfl";
        _isOn = NO;
    }
    return self;
}

@end
