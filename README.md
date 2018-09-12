# OpenGL ES + CAEAGLLayer 视频渲染

- FFmpeg 视频解码
- YUV 图片渲染
- AudioUnit 音频播放
- 异步线程解码和安全&同步音视频播放
- 添加播放器功能:首屏图片、播放、快进、暂停、循环、停止、截屏

FFmpeg是一套可以用来记录、转换数字音频、视频，并能将其转化为流的开源计算机程序。采用LGPL或GPL许可证。它提供了录制、转换以及流化音视频的完整解决方案。它包含了非常先进的音频/视频编解码库libavcodec，为了保证高可移植性和编解码质量，libavcodec里很多code都是从头开发的。

FFmpeg在Linux平台下开发，但它同样也可以在其它操作系统环境中编译运行，包括Windows、Mac OS X等。这个项目最早由Fabrice Bellard发起，2004年至2015年间由Michael Niedermayer主要负责维护。许多FFmpeg的开发人员都来自MPlayer项目，而且当前FFmpeg也是放在MPlayer项目组的服务器上。项目的名称来自MPEG视频编码标准，前面的"FF"代表"Fast Forward"。

[--来自百度百科]()

##任务安排
- [x] 安排任务计划  2018/9/11 
- [ ] FFMpeg 结构详解&解码重要函数讲解

### FFMpeg 音频&视频解码重要函数详解
FFMpeg 结构介绍:

- `libavcodec`  编解码库
- `libavdevice` 设备信息库
- `libavfilter` 过滤器库
- `libavformat` 封装格式库
- `libavutil`   工具库
- `libswresample` 音频转换库
- `libswscale`    视频转换库

音视频解码过程中使用到的重要结构体详解：

- `AVFormatContext` 对容器和多媒体文件层次的抽象, 封装结构上下文, 其包含音频流、视频流、字幕流。
- `AVStream` 对流的抽象, 流结构体, 每一路流都有编码格式。
- `AVCodecContext` 对编码格式和解码器的抽象, 编解码器上下文。
- `AVCodec` 对编码格式和解码器的抽象, 编解码器。
- `AVPacket` 对编码器或者解码器的输入输出部分抽象, 一个音视频流包数据, 其中一个视频`AVPacket`包包含一个`AVFrame`帧数据;一个音频`AVPacket`包包含一个或多个`AVFrame`帧数据。
- `AVFrame`  对编码器或者解码器的输入输出部分抽象, 表示一帧音频&视频数据。
- `AVPicture`  视频转换是用于存储一帧数据。
- `SwrContext` 音频格式转换结构体, 可以转换不同格式音频流数据。
- `struct SwsContext` 视频格式转换结构体, 可以转换不同格式的视频流数据。

音视频解码流程详解:

1. 注册
2. 打开音视频流文件
3. 寻找音视频文件流信息
4. 获取音视频文件的解码上下文和解码器
5. 获取音频流索引和视频流索引
6. 判断音频流是否需要转码
7. 创建音频&视频帧结构体
8. 读取流数据
9. 解码音频&视频流

```
// 注册音视频环境、编解码器、过滤器等
void av_register_all(void);

// 创建封装格式上下文
AVFormatContext *avformat_alloc_context(void);

// 打开音视频文件
// @pram AVFormatContext **ps 传入一个AVFormatContext*地址
// @pram const char *filename 文件名
// @pram AVInputFormat *fmt 输入文件的格式, 可以为 NULL
// @pram AVDictionary **options 可选项, 可以为 NULL
// @return int >=0 表示成功 <0 表示失败
int avformat_open_input(AVFormatContext **ps, const char *filename, AVInputFormat *fmt, AVDictionary **options);

// 寻找音视频文件流信息
// @pram AVFormatContext *ic 同上
// @pram AVDictionary **options 可选项, 可以为 NULL
// @return int >=0 表示成功 <0 表示失败
int avformat_find_stream_info(AVFormatContext *ic, AVDictionary **options);

// 获取解码器
// @pram enum AVCodecID id 解码器的编号
AVCodec *avcodec_find_decoder(enum AVCodecID id);

// 打开解码器
// @pram AVCodecContext *avctx 同上
// @pram const AVCodec *codec 获取到的解码器
// @pram AVDictionary **options 同上
// @return int >=0 表示成功 <0 表示失败
int avcodec_open2(AVCodecContext *avctx, const AVCodec *codec, AVDictionary **options);

// 获取音视频帧结构体
AVFrame *avcodec_alloc_frame(void);

// 创建音频转码上下文
// @pram struct SwrContext *s 此处为NULL
// @pram int64_t out_ch_layout 输出的声道立体布局
// @pram enum AVSampleFormat out_sample_fmt 输出音频格式
// @pram int out_sample_rate 输出采样率
// @pram int64_t in_ch_layout 输入的声道立体布局
// @pram enum AVSampleFormat in_sample_fmt 输入音频格式
// @pram int in_sample_rate 输入采样率
// @pram int log_offset 日志级别   默认 0
// @pram void *log_ctx  日志上下文 默认 NULL
struct SwrContext *swr_alloc_set_opts(struct SwrContext *s,
                                      int64_t out_ch_layout, enum AVSampleFormat out_sample_fmt, int out_sample_rate,
                                      int64_t  in_ch_layout, enum AVSampleFormat  in_sample_fmt, int  in_sample_rate,
                                      int log_offset, void *log_ctx);
                                      
// 获取最佳的声道立体布局
int av_get_channel_layout_nb_channels(uint64_t channel_layout);

// 读取帧数据, 放进一个AVPacket包中
// @pram AVFormatContext *s 同上
// @pram AVPacket *pkt 用以操作的媒体包
// @return int ==0 表示包没有数据 >0 表示一个有数据的包 <0 表示文件读取失败&读取完毕
int av_read_frame(AVFormatContext *s, AVPacket *pkt);

// 解码视频数据包
// @pram AVCodecContext *avctx 文件编解码上到下文
// @pram AVFrame *picture 视频帧结构体
// @pram int *got_picture_ptr 用以判断是否有图片 >0 表示有 <=0 表示没有
// @pram const AVPacket *avpkt 携带音频数据的包
// @return int 解码后的长度, >0 表示解码成功且有数据 ==0 表示解码成功没有数据 <0 表示解码失败
int avcodec_decode_video2(AVCodecContext *avctx, AVFrame *picture,
                         int *got_picture_ptr,
                         const AVPacket *avpkt);
                         
// 解码音频数据包
// @pram AVCodecContext *avctx 文件编解码上到下文
// @pram AVFrame *frame 音频帧结构体
// @pram int *got_frame_ptr 用以判断是否有音频 >0 表示有 <=0 表示没有
// @pram const AVPacket *avpkt 携带音频数据的包
// @return int 解码后的长度, >0 表示解码成功且有数据 ==0 表示解码成功没有数据 <0 表示解码失败
int avcodec_decode_audio4(AVCodecContext *avctx, AVFrame *frame,
                          int *got_frame_ptr, const AVPacket *avpkt);
                          
// 格式转换流程: 1. 获取流数据的长度 2. 分配一个流数据空间 3. 将数据转换到刚才分配的空间 4. 将读取到的数据写入包中。
// av_samples_get_buffer_size 方法可以帮助我们获取流数据的长度
// 参数分析:
// 1、 int *linesize   用来计算的管道尺寸, 一般为NULL
// 2、 int nb_channels 管道个数
// 3、 int nb_samples  每个管道的抽样数
// 4、 enum AVSampleFormat sample_fmt 抽样格式
// 5、 int align 排列, 0 为默认
// @return int buffersize >0 表示有数据
int av_samples_get_buffer_size(int *linesize, int nb_channels, int nb_samples,
                               enum AVSampleFormat sample_fmt, int align);

// 音频数据格式转换
// @pram struct SwrContext *s 音频数据格式转换上下文
// @pram uint8_t **out 输出数据
// @pram int out_count 输出数据的长度
// @pram const uint8_t **in 输入数据
// @pram int in_count 输入数据的长度
int swr_convert(struct SwrContext *s, uint8_t **out, int out_count,
                                const uint8_t **in , int in_count);

// 创建视频图片帧结构体
// @pram AVPicture *picture 图片帧结构体
// @pram enum AVPixelFormat pix_fmt 像素格式
// @pram int width 图片的宽度
// @pram int height 图片的高度
int avpicture_alloc(AVPicture *picture, enum AVPixelFormat pix_fmt, int width, int height);

// 创建视频格式转换上线文
// @pram struct SwsContext *context 视频格式转换上线文, 默认为NULL
// @pram int srcW 原图片的宽度
// @pram int srcH 原图片的高度
// @pram enum AVPixelFormat srcFormat 原图片像素格式
// @pram int dstW 目标图片的宽度
// @pram int dstH 目标图片的高度
// @pram enum AVPixelFormat dstFormat 目标图片像素格式
// @pram int flags 算法标签（性能差异 效果差异 针对尺寸变化） 
// @pram SwsFilter *srcFilter 原图片过滤器 
// @pram SwsFilter *dstFilter 目标图片过滤器 
// @pram const double *param 算法中默认值的设定 可以默认
struct SwsContext *sws_getCachedContext(struct SwsContext *context,
                                        int srcW, int srcH, enum AVPixelFormat srcFormat,
                                        int dstW, int dstH, enum AVPixelFormat dstFormat,
                                        int flags, SwsFilter *srcFilter,
                                        SwsFilter *dstFilter, const double *param);
                                        
// 视频像素格式和尺寸转换中每一帧数据的处理 
// @pram struct SwsContext *c 视频格式转换上线文
// @pram const uint8_t *const srcSlice[] 具体数据的数组 
// @pram const int srcStride[] 一行数据的大小 
// @pram int srcSliceY 传0 
// @pram int srcSliceH, 图形高度 
// @pram uint8_t *const dst[], 目标的地址（指针数组） 
// @pram const int dstStride[]) 输出的一行数据的大小;
int sws_scale(struct SwsContext *c, const uint8_t *const srcSlice[],
              const int srcStride[], int srcSliceY, int srcSliceH,
              uint8_t *const dst[], const int dstStride[]);

// 获取一帧数据的位置
int64_t av_frame_get_best_effort_timestamp(const AVFrame *frame);

// 获取一帧数据的时长
int64_t av_frame_get_pkt_duration         (const AVFrame *frame);

```

#### 实例1、解码音频文件为 PCM 文件
#### 实例2、解码视频文件为 YUV 文件
#### 实例3、硬解码 音频&视频

### OpenGL ES 2.0 基本流程详解

#### 实例1、附带颜色的背景板
#### 实例2、绘制三角形
#### 实例3、PNG、JPEG 图片纹理
#### 实例4、RGB 图片纹理
#### 实例5、YUV 图片纹理

### FFmpeg + OpenGL ES + AudioUnit 视频播放器流程详解

#### 阶段1、动态视频播放器
#### 阶段2、动态音频播放器
#### 阶段3、动态音视频同步播放器
#### 阶段4、复杂功能音视频播放器
#### 阶段5、添加硬解码逻辑
#### 阶段6、网络版音视频播放器
#### 阶段7、直播播放端音视频播放器


