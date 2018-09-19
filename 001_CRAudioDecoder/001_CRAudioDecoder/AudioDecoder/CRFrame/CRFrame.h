//
//  CRFrame.h
//  001_CRAudioDecoder
//
//  Created by youplus on 2018/9/18.
//  Copyright © 2018年 charly. All rights reserved.
//

/**
 CR:MAKR--
    本类用以记录解码后一帧音视频数据
 包括:
    0.帧类型
    1.解码时长
    2.显示时长
    3.包大小
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, CRTypeFrame) {
    CRAudioFrameType,
    CRVideoFrameType
};

@interface CRFrame : NSObject

@property (nonatomic, assign) CRTypeFrame type; // 帧类型
@property (nonatomic, assign) CGFloat duration;  // 解码时长
@property (nonatomic, assign) CGFloat position; // 显示时长
@property (nonatomic, assign) CGFloat size;     // 包大小

@end
