//
//  CRAVSynchronizer.m
//  001_CRAudioDecoder
//
//  Created by youplus on 2018/9/18.
//  Copyright © 2018年 charly. All rights reserved.
//

#import "CRAVSynchronizer.h"
#import "CRAudioDecoder.h"
#include <pthread.h>

@interface CRAVSynchronizer ()

@property (nonatomic, strong) CRAudioDecoder *decoder;
@property (nonatomic, strong) NSMutableArray <CRAudioFrame *>*audioFrames;

@end

@implementation CRAVSynchronizer {
    int _packetSize;    // 音频包, 每次的解码大小
    BOOL _isOnDecoder;  // 是否开启解码
    
    pthread_t decoderTheard;
}

- (BOOL)openFile:(NSString *)filePath withOptions:(NSDictionary *)option
{
    NSError *error;
    _decoder        = [[CRAudioDecoder alloc] init];
    _audioFrames    = @[].mutableCopy;
    _isOnDecoder  = [_decoder openFile:filePath error:&error];
    [self startFrameDecoder];
    return _isOnDecoder;
}

- (void)startFrameDecoder
{
    // 创建一个子线程, 解码数据
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while (![self.decoder isEOF]) {
            NSArray *frames = [self.decoder decodeAudioFrame:0];
            NSLog(@"%@", frames);
            for (CRFrame *frame in frames) {
                NSLog(@"...size:%.f", frame.size);
                if (frame.type == CRAudioFrameType) {
                    [self.audioFrames addObject:(CRAudioFrame *)frame];
                }
            }
        }
        NSLog(@"End Over！");
    });
}

@end
