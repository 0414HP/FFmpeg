//
//  ViewController.m
//  001_CRAudioDecoder
//
//  Created by youplus on 2018/9/12.
//  Copyright © 2018年 charly. All rights reserved.
//

#import "ViewController.h"
#import "CRAVSynchronizer.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    NSString *sourcePath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"131.aac"];
    
    CRAVSynchronizer *synchronizer = [[CRAVSynchronizer alloc] init];
    [synchronizer openFile:sourcePath withOptions:nil];
}


@end
