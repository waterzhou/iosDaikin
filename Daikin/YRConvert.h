//
//  YRConvert.h
//  YUVVIew
//
//  Created by liu nian on 2016/10/22.
//  Copyright © 2016年 thinker. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, YUV_TYPE) {
    FMT_YUYV = 0,
    FMT_YVYU,//
    FMT_UYVY,//
    FMT_VYUY,
};

@interface YRConvert : NSObject

void yuv422packed_to_rgb24(YUV_TYPE type, unsigned char *yuv422p, unsigned char *rgb, int width, int height);

void temperature_to_rgb24(unsigned char *temperature, unsigned char *rgb, int width, int height);
@end
