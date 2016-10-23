//
//  YRConvert.m
//  YUVVIew
//
//  Created by liu nian on 2016/10/22.
//  Copyright © 2016年 thinker. All rights reserved.
//

#import "YRConvert.h"

@implementation YRConvert

#ifndef MAX
#define MAX(a, b) ((a) > (b) ? (a) : (b))
#endif
#ifndef MIN
#define MIN(a, b) ((a) < (b) ? (a) : (b))
#endif

static long U[256], V[256], Y1[256], Y2[256];

void init_yuv422p_table(void)
{
    int i;
    static int init = 0;
    if (init == 1) return;
    // Initialize table
    for (i = 0; i < 256; i++)
    {
        V[i]  = 15938 * i - 2221300;
        U[i]  = 20238 * i - 2771300;
        Y1[i] = 11644 * i;
        Y2[i] = 19837 * i - 311710;
    }

    init = 1;
}

void yuv422packed_to_rgb24(YUV_TYPE type, unsigned char *yuv422p, unsigned char *rgb, int width, int height)
{
    int y, cb, cr;
    int r, g, b;
    int i = 0;
    unsigned char* p;
    unsigned char* p_rgb;

    p = yuv422p;

    p_rgb = rgb;

    init_yuv422p_table();

    for (i = 0; i < width * height / 2; i++)
    {
        switch(type)
        {
            case FMT_YUYV:
                y  = p[0];
                cb = p[1];
                cr = p[3];
                break;
            case FMT_YVYU:
                y  = p[0];
                cr = p[1];
                cb = p[3];
                break;
            case FMT_UYVY:
                cb = p[0];
                y  = p[1];
                cr = p[2];
                break;
            case FMT_VYUY:
                cr = p[0];
                y  = p[1];
                cb = p[2];
                break;
            default:
                break;
        }

        r = MAX (0, MIN (255, (V[cr] + Y1[y])/10000));   //R value
        b = MAX (0, MIN (255, (U[cb] + Y1[y])/10000));   //B value
        g = MAX (0, MIN (255, (Y2[y] - 5094*(r) - 1942*(b))/10000)); //G value

        // 此处可调整RGB排序，BMP图片排序为BGR
        // 默认排序为：RGB
        p_rgb[0] = r;
        p_rgb[1] = g;
        p_rgb[2] = b;

        switch(type)
        {
            case FMT_YUYV:
            case FMT_YVYU:
                y = p[2];
                break;
            case FMT_UYVY:
            case FMT_VYUY:
                y = p[3];
                break;
            default:
                break;
        }

        r = MAX (0, MIN (255, (V[cr] + Y1[y])/10000));   //R value
        b = MAX (0, MIN (255, (U[cb] + Y1[y])/10000));   //B value
        g = MAX (0, MIN (255, (Y2[y] - 5094*(r) - 1942*(b))/10000)); //G value

        p_rgb[3] = r;
        p_rgb[4] = g;
        p_rgb[5] = b;

        p += 4;
        p_rgb += 6;
    }
}

// value是个0-255的值，minDegree是起始温度：绿色，maxDegree最大温度：红色
int convert_temperature_to_rgb_pixel(int value) {
    unsigned int pixel32 = 0;
    unsigned char *pixel = (unsigned char *)&pixel32;
    int r, g, b;
    r = value;
    g = 255 - value;
    b = 0;
    if (g < 0) {
        g = 0;
    }
    pixel[0] = r;
    pixel[1] = g;
    pixel[2] = b;
    return pixel32;
}

// 默认起始温度20摄氏度，真实温度是20+value*0.25
void temperature_to_rgb24(unsigned char *temperature, unsigned char *rgb, int width, int height) {

    int i = 0, j = 0;
    unsigned char* t;
    unsigned char* t_rgb;
    int r, g, b;
    int min_temp = 24.0;
    int max_temp = 30.0;
    t = temperature;
    t_rgb = rgb;

    init_yuv422p_table();
    NSMutableString *mstr = [NSMutableString string];
    // i列，j行
    for (i = 0; i < height; i++) {
        for (j = 0; j < width; j++) {
            int rgb_index = i * width + j;
            int temp_index = j * height + i;
            int value = t[temp_index];
            float t_f = 20 + value * 0.25;
            if (j == 0) {
                [mstr appendString:@"\n"];
            }
            [mstr appendString:[NSString stringWithFormat:@" %02.2f",t_f]];
            if (t_f < min_temp) {
                t_f = min_temp;
            }
            if (t_f > max_temp) {
                t_f = max_temp;
            }
            r = ((t_f - min_temp) / (max_temp - min_temp)) * 255;
            g = 255 - r;
            b = 0;
            if (g < 0) {
                g = 0;
            }
            int start_index = rgb_index * 3;
            t_rgb[start_index] = r;
            t_rgb[start_index + 1] = g;
            t_rgb[start_index + 2] = b;
        }
    }
    NSLog(@"%@",mstr);
}

@end
