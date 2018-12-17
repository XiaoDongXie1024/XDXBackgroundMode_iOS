//
//  AppDelegate.m
//  XDXBackgroundMode_iOS
//
//  Created by 小东邪 on 2018/12/5.
//  Copyright © 2018 小东邪. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    NSLog(@"%s",__func__);
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    NSLog(@"%s",__func__);
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    NSLog(@"%s",__func__);
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    NSLog(@"%s",__func__);
}


- (void)applicationWillTerminate:(UIApplication *)application {
    NSLog(@"%s",__func__);
}


@end
