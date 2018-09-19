//
//  CRAudioFrame.h
//  001_CRAudioDecoder
//
//  Created by youplus on 2018/9/18.
//  Copyright © 2018年 charly. All rights reserved.
//

/**
 CR:MAKR--
    本类用以记录解码后一帧音频数据
 包括:
     0.帧类型
     1.解码时长
     2.显示时长
     3.音频数据
 */

#import "CRFrame.h"

@interface CRAudioFrame : CRFrame

@property (nonatomic, readwrite, strong) NSData *samples;

@end
