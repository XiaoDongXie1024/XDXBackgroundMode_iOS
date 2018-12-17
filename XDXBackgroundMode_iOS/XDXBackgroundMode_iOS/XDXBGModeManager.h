//
//  XDXBGModeManager.h
//  Created by 小东邪 on 2018/6/21.
//  Copyright © 2018 小东邪. All rights reserved.
//


#import <UIKit/UIKit.h>

@interface XDXBGModeManager : NSObject

/**
 Begin a new background task
 */
-(UIBackgroundTaskIdentifier)beginNewBackgroundTask;

/**
 End last background task then begin a new background task
 */
-(void)restartLocation;

/**
 End all back group task
 */
-(void)endAllBGTask;

@end
