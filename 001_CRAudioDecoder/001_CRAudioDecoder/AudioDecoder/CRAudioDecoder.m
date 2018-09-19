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
    AVFrame *_audioFrame;
    
    BOOL _isEOF; // 是否结束读取
}

- (BOOL)openFile:(NSString *)path error:(NSError **)error
{
    BOOL ret    = NO;
    _audioIndex = -1;
    av_register_all();
    if ((ret = [self openInput:path.UTF8String error:error])) {
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
    AVStream *avStream = _avFmtCtx->streams[streamIndex];
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
        int64_t out_ch_layout               = av_get_channel_layout_nb_channels(OUTPUT_LAYOUT_NUM);
        enum AVSampleFormat out_sample_fmt  = AV_SAMPLE_FMT_S16;
        int out_sample_rate                 = avCodecCtx->sample_rate;
        int64_t in_ch_layout               = av_get_channel_layout_nb_channels(avCodecCtx->channels);
        enum AVSampleFormat in_sample_fmt  = avCodecCtx->sample_fmt;
        int in_sample_rate                 = avCodecCtx->sample_rate;
        _swrCtx = swr_alloc_set_opts(NULL,
                                     out_ch_layout, out_sample_fmt, out_sample_rate,
                                     in_ch_layout, in_sample_fmt, in_sample_rate,
                                     0, NULL);
        if (!_swrCtx || swr_init(_swrCtx)) {
            if (_swrCtx) {
                swr_free(&_swrCtx);
            }
            avcodec_close(avCodecCtx);
            NSLog(@"重采样对象创建失败");
            return NO;
        }
    }
    AVFrame *audioFrame = avcodec_alloc_frame();
    if (!audioFrame) {
        NSLog(@"音频帧对象创建失败!");
        return NO;
    }
    _audioFrame = audioFrame;
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

- (NSArray <CRFrame *>*)decodeAudioFrame:(int)packetSize
{
    /**
     CR:MAKE
        解码逻辑, 解码一帧
     */
    NSMutableArray *frames = [[NSMutableArray alloc] init];
    AVPacket pkt;
    int dePktSize  = 0;
    BOOL _isFinish = NO;
    while (!_isFinish) {
        int len = av_read_frame(_avFmtCtx, &pkt);
        if (len < 0) {
            // 读取出错或文件读取完毕, 退出文件读取流程
            _isEOF = YES;
            break;
        }
        // 读取到包的大小
        int pktSize = pkt.size;
        // 判断包是否为音频包
        if (pkt.stream_index == _audioIndex) {
            while (pktSize > 0) {
                /**
                 CR:MARK
                 音频解码, 返回解码成功后的长度
                 gotFrame: 表示解码是否成功
                 len:      表示解码后音频帧的长度, 0 表示包为空包, < 0 表示无效的包
                 */
                int gotFrame = 0;
                int len      = avcodec_decode_audio4(_avCodecCtx, _audioFrame, &gotFrame, &pkt);
                if (len < 0) {
                    NSLog(@"音频解码失败, 跳过这个包！");
                    break;
                }
                if (gotFrame) {
                    CRFrame *audioFrame = [self handleAudioFrame];
                    if (audioFrame) {
                        [frames addObject:audioFrame];
                        audioFrame.size = len;
                        dePktSize += len;
                        if (dePktSize >= packetSize) {
                            _isFinish = YES;
                        }
                    }
                }
                if (len == 0) {
                    break;
                }
                pktSize -= len;
            }
        }
    }
    return frames;
}

- (CRFrame *)handleAudioFrame
{
    if (!_audioFrame->data[0]) {
        return nil;
    }
    CRAudioFrame *audioFrame = [[CRAudioFrame alloc] init];
    /**
     CR:MARK 这里需要定义两个变量参数
     1. 音频数据
     2. 音频数据长度
     3. 声道数量
     */
    int numChannel = _avCodecCtx->channels;
    int ratio = 2;
    int audio_out_buffer_size = _audioFrame->nb_samples * ratio;
    int numFrames;
    void *sampleData;
    if (_swrCtx) {
        int buffersize = av_samples_get_buffer_size(NULL, (int)numChannel, audio_out_buffer_size, AV_SAMPLE_FMT_S16, 1);
        uint8_t *outbuffer  = (uint8_t *)malloc(buffersize);
        uint8_t *outData[2] = {outbuffer, NULL};
        numFrames = swr_convert(_swrCtx, outData, audio_out_buffer_size, (const uint8_t **)_audioFrame->data, _audioFrame->nb_samples);
        if (numFrames < 0) {
            NSLog(@"重采样失败!");
            return nil;
        }
        sampleData = outbuffer;
    }
    else {
        if (_avCodecCtx->sample_fmt != AV_SAMPLE_FMT_S16) {
            return nil;
        }
        sampleData = _audioFrame->data[0];
        numFrames  = _audioFrame->nb_samples;
    }
    const NSUInteger numElements = numFrames * numChannel;
    NSMutableData *audioData = [NSMutableData dataWithLength:numElements * sizeof(SInt16)];
    memcpy(audioData.mutableBytes, sampleData, numElements * sizeof(SInt16));
    audioFrame.samples     = audioData;
    audioFrame.position    = av_frame_get_best_effort_timestamp(_audioFrame) * _audioTimeBase;
    audioFrame.duration    = av_frame_get_pkt_duration(_audioFrame) * _audioTimeBase;
    return audioFrame;
}

- (BOOL)isEOF
{
    return _isEOF;
}

- (void)destoryDecoder
{
    _isEOF = NO;
    
    if (_audioFrame) {
        av_frame_free(&_audioFrame);
        _audioFrame = NULL;
    }
    if (_swrCtx) {
        swr_free(&_swrCtx);
        _swrCtx = NULL;
    }
    if (_avCodecCtx) {
        avcodec_close(_avCodecCtx);
        _avCodecCtx = NULL;
    }
    if (_avFmtCtx) {
        avformat_free_context(_avFmtCtx);
        _avFmtCtx = NULL;
    }
}

@end
