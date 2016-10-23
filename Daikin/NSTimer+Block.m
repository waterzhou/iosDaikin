//
//  NSTimer+Block.m
//  NoWait
//
//  Created by liu nian on 15/9/14.
//  Copyright (c) 2015年 Shanghai Puscene Information Technology Co.,Ltd. All rights reserved.
//

#import "NSTimer+Block.h"

@implementation NSTimer (Block)

- (instancetype)initWithFireDate:(NSDate *)date interval:(NSTimeInterval)seconds repeats:(BOOL)repeats block:(void (^)(void))block
{
    return [self initWithFireDate:date interval:seconds target:self.class selector:@selector(runBlock:) userInfo:block repeats:repeats];
}

+ (NSTimer *)xw_scheduledTimerWithTimeInterval:(NSTimeInterval)seconds repeats:(BOOL)repeats block:(void (^)(void))block
{
    return [self scheduledTimerWithTimeInterval:seconds target:self selector:@selector(runBlock:) userInfo:block repeats:repeats];
}

+ (NSTimer *)xw_timerWithTimeInterval:(NSTimeInterval)seconds repeats:(BOOL)repeats block:(void (^)(void))block
{
    return [self timerWithTimeInterval:seconds target:self selector:@selector(runBlock:) userInfo:block repeats:repeats];
}

#pragma mark - Private methods

+ (void)runBlock:(NSTimer *)timer
{
    if ([timer.userInfo isKindOfClass:NSClassFromString(@"NSBlock")])
    {
        void (^block)(void) = timer.userInfo;
        block();
    }
}
@end
