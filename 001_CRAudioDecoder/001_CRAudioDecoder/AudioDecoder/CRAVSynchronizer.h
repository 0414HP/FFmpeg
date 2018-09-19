//
//  CRAVSynchronizer.h
//  001_CRAudioDecoder
//
//  Created by youplus on 2018/9/18.
//  Copyright © 2018年 charly. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CRAVSynchronizer : NSObject

- (BOOL)openFile:(NSString *)filePath withOptions:(NSDictionary *)option;
- (void)startFrameDecoder;

@end
