//
//  CRAudioDecoder.m
//  001_CRAudioDecoder
//
//  Created by youplus on 2018/9/12.
//  Copyright © 2018年 charly. All rights reserved.
//

#import "CRAudioDecoder.h"
#import "libavformat/avformat.h"
#import "libavcodec/avcodec.h"
#import "libswresample/swresample.h"

#define OUTPUT_LAYOUT_NUM 2

@implementation CRAudioDecoder
{
    AVFormatContext *_avFmtCtx;
    AVCodecContext *_avCodecCtx;
    
    int     _audioIndex;
    double  _audioTimeBase;
    SwrContext *_swrCtx;
}

- (BOOL)openFile:(NSString *)path error:(NSError **)error
{
    BOOL ret    = NO;
    _audioIndex = -1;
    if ((ret = [self openFile:path error:error])) {
        ret = [self openAudioStream];
    }
    return ret;
}

- (BOOL)openInput:(const char *)fileName error:(NSError **)error
{
    AVFormatContext *avFormatCtx = avformat_alloc_context();
    if (avformat_open_input(&avFormatCtx, fileName, NULL, NULL) < 0) {
        NSLog(@"文件打开失败!");
        return NO;
    }
    if (avformat_find_stream_info(avFormatCtx, NULL) < 0) {
        NSLog(@"文件流信息获取失败!");
        return NO;
    }
    _avFmtCtx = avFormatCtx;
    return YES;
}

- (BOOL)openAudioStream
{
    int streamIndex = av_find_best_stream(_avFmtCtx, AVMEDIA_TYPE_AUDIO, -1, -1, NULL, 0);
    if (streamIndex == -1) {
        NSLog(@"音频流不存在");
        return NO;
    }
    AVStream *avStream = _avFmtCtx->streams[_audioIndex];
    AVCodecContext *avCodecCtx = avStream->codec;
    AVCodec *avCodec = avcodec_find_decoder(avCodecCtx->codec_id);
    if (!avCodec) {
        NSLog(@"获取编码器失败!");
        return NO;
    }
    if (avcodec_open2(avCodecCtx, avCodec, NULL) < 0) {
        NSLog(@"打开编码器失败！");
        return NO;
    }
    if (![self audioCodecIsSupported:avCodecCtx]) {
        int64_t out_ch_layout               = av_get_default_channel_layout(OUTPUT_LAYOUT_NUM);
        enum AVSampleFormat out_sample_fmt  = AV_SAMPLE_FMT_S16;
        int out_sample_rate                 = avCodecCtx->sample_rate;
        int64_t in_ch_layout               = av_get_default_channel_layout(avCodecCtx->channels);
        enum AVSampleFormat in_sample_fmt  = avCodecCtx->sample_fmt;
        int in_sample_rate                 = avCodecCtx->sample_rate;
        _swrCtx = swr_alloc_set_opts(NULL,
                                     out_ch_layout, out_sample_fmt, out_sample_rate,
                                     in_ch_layout, in_sample_fmt, in_sample_rate,
                                     0, NULL);
    }
    _audioIndex = streamIndex;
    _avCodecCtx = avCodecCtx;
    if (avStream->time_base.den && avStream->time_base.num) {
        _audioTimeBase = av_q2d(avStream->time_base);
    }
    else if (avCodecCtx->time_base.den && avCodecCtx->time_base.num) {
        _audioTimeBase = av_q2d(avCodecCtx->time_base);
    }
    else {
        _audioTimeBase = 0.025;
    }
    return YES;
}

- (BOOL)audioCodecIsSupported:(AVCodecContext *)avCodecCtx
{
    if (avCodecCtx->sample_fmt == AV_SAMPLE_FMT_S16) {
        return YES;
    }
    return NO;
}

- (void)decodeAudioFrame
{
    
    
}

@end
