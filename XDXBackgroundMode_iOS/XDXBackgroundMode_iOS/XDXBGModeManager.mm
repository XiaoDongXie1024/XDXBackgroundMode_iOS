//
//  XDXBGModeManager.m
//  TVURouterFramework
//
//  Created by 小东邪 on 2018/6/21.
//  Copyright © 2018 小东邪. All rights reserved.
//

#import "XDXBGModeManager.h"
#import "log4cplus.h"

static const char *ModuleName = "BGMode";

@interface XDXBGModeManager()

// BG mode task array and main id.
@property (nonatomic, strong)   NSMutableArray             *bgTaskIdList;
@property (assign)              UIBackgroundTaskIdentifier masterTaskId;

// The app is support bg mode.
@property (nonatomic, assign) BOOL isSupportBGMode;

@end

@implementation XDXBGModeManager
#pragma mark - Init
- (instancetype)init {
    if (self = [super init]) {
        [self configureBaseInfo];
    }
    return self;
}

- (void)configureBaseInfo {
    if([UIApplication sharedApplication].backgroundRefreshStatus == UIBackgroundRefreshStatusDenied) {
        log4cplus_error("XDXBGModeManager", "%s - The service need get locaion always, please open it on the system setting.",ModuleName);
    }else if ([UIApplication sharedApplication].backgroundRefreshStatus == UIBackgroundRefreshStatusRestricted) {
        log4cplus_error("XDXBGModeManager", "%s - The device can't support get location !",ModuleName);
    }
    
    _bgTaskIdList      = [NSMutableArray array];
    _masterTaskId      = UIBackgroundTaskInvalid;
}

#pragma mark - Main Func
-(void)restartLocation {
    [self beginNewBackgroundTask];
}

-(UIBackgroundTaskIdentifier)beginNewBackgroundTask {
    UIApplication *application = [UIApplication sharedApplication];
    __block UIBackgroundTaskIdentifier bgTaskId = UIBackgroundTaskInvalid;
    if([application respondsToSelector:@selector(beginBackgroundTaskWithExpirationHandler:)]) {
        bgTaskId = [application beginBackgroundTaskWithExpirationHandler:^{
            log4cplus_warn("XDXBGModeManager", "%s - bg Task (%lu) expired !",ModuleName,bgTaskId);
            [self.bgTaskIdList removeObject:@(bgTaskId)];//过期任务从后台数组删除
            bgTaskId = UIBackgroundTaskInvalid;
            [application endBackgroundTask:bgTaskId];
        }];
    }
    //如果上次记录的后台任务已经失效了，就记录最新的任务为主任务
    if (_masterTaskId == UIBackgroundTaskInvalid) {
        self.masterTaskId = bgTaskId;
        log4cplus_warn("XDXBGModeManager", "%s - Start bg task : %lu",ModuleName,(unsigned long)bgTaskId);
    }else { //如果上次开启的后台任务还未结束，就提前关闭了，使用最新的后台任务
        //add this id to our list
        log4cplus_warn("XDXBGModeManager", "%s - Keep bg task %lu",ModuleName,(unsigned long)bgTaskId);
        [self.bgTaskIdList addObject:@(bgTaskId)];
        [self endInvalidBGTaskWithIsEndAll:NO];//留下最新创建的后台任务
    }
    return bgTaskId;
}

- (void)endAllBGTask {
    [self endInvalidBGTaskWithIsEndAll:YES];
}

-(void)endInvalidBGTaskWithIsEndAll:(BOOL)isEndAll
{
    UIApplication *application = [UIApplication sharedApplication];
    //如果为all 清空后台任务数组
    //不为all 留下数组最后一个后台任务,也就是最新开启的任务
    if ([application respondsToSelector:@selector(endBackGroundTask:)]) {
        for (int i = 0; i < (isEndAll ? _bgTaskIdList.count :_bgTaskIdList.count -1); i++) {
            UIBackgroundTaskIdentifier bgTaskId = [self.bgTaskIdList[0]integerValue];
            log4cplus_debug("XDXBGModeManager", "%s - Close bg task %lu",ModuleName,(unsigned long)bgTaskId);
            [application endBackgroundTask:bgTaskId];
            [self.bgTaskIdList removeObjectAtIndex:0];
        }
    }
    
    ///如果数组大于0 所有剩下最后一个后台任务正在跑
    if(self.bgTaskIdList.count > 0) {
        log4cplus_debug("XDXBGModeManager", "%s - The bg task is running %lu!",ModuleName,(long)[_bgTaskIdList[0]integerValue]);
    }
    
    if(isEndAll) {
        [application endBackgroundTask:self.masterTaskId];
        self.masterTaskId = UIBackgroundTaskInvalid;
    }else {
        log4cplus_debug("XDXBGModeManager", "%s - Kept master background task id : %lu",ModuleName,(unsigned long)self.masterTaskId);
    }
}

@end

