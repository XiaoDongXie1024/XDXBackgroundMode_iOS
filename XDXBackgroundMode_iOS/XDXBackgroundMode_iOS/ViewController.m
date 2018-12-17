//
//  ViewController.m
//  XDXBackgroundMode_iOS
//
//  Created by 小东邪 on 2018/12/5.
//  Copyright © 2018 小东邪. All rights reserved.
//

#import "ViewController.h"
#import "XDXLocationManager.h"

/**
 Note : 实现本Demo功能需要开启Project后台刷新的设置以及info.plist文件中加入必须的权限，具体教程请查阅博客。
 */

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UISwitch *enableBGModeSwitcher;

@property (nonatomic, strong) XDXLocationManager *locationManager;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.locationManager = [XDXLocationManager getInstance];

    /**
     Note
     1. 如果开启后台模式，即将开关打开，所有线程在后台会处于活跃状态，则当应用进入后台后打印会继续,如果没有开启，则程序中所有线程在进入后台处于挂起状态，打印会停止，iOS中默认进入后台为挂起状态.
     
     2. 如果要使用后台模式，必须在申请位置权限时提供始终允许，否则进入后台后无法通过获取地理位置实现持久后台模式
     
     3. 后台模式在特定情况下会被系统自动杀死，例如：息屏后放置较长时间
     
     You could judge the background mode is whether open by console's result.
     */
    [NSTimer scheduledTimerWithTimeInterval:3 repeats:YES block:^(NSTimer * _Nonnull timer) {
       NSLog(@"XDX - 我是小东邪啊 !");
    }];
}

- (IBAction)enbleBGModeSwitcherHasChanged:(UISwitch *)sender {
    if (sender.isOn) {      // Open BG mode
        [self.locationManager openBGMode];
    }else {                 // Close BG mode
        [self.locationManager closeBGMode];
    }
}

@end
