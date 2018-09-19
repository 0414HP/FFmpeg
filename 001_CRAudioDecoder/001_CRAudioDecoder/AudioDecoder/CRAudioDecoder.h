//
//  CRAudioDecoder.h
//  001_CRAudioDecoder
//
//  Created by youplus on 2018/9/12.
//  Copyright © 2018年 charly. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CRAudioFrame.h"

NS_ASSUME_NONNULL_BEGIN

@interface CRAudioDecoder : NSObject

- (BOOL)openFile:(NSString *)path error:(NSError **)error;
- (NSArray <CRFrame *>*)decodeAudioFrame:(int)packetSize;

- (BOOL)isEOF; // 文件读取失败或者结束

- (void)destoryDecoder;

@end

NS_ASSUME_NONNULL_END
