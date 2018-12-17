//
//  XDXLocationManager.h
//  XDXBackgroundMode_iOS
//
//  Created by 小东邪 on 2018/12/12.
//  Copyright © 2018 小东邪. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XDXSingleton.h"

NS_ASSUME_NONNULL_BEGIN

@interface XDXLocationManager : NSObject

SingletonH

@property (nonatomic, assign) double longitude;
@property (nonatomic, assign) double latitude;

@property (nonatomic, assign) BOOL isSupportBGMode;


/**
 * 获取单例对象
 */
+ (instancetype )getInstance;


/**
 * 打开/关闭后台模式
 */
- (void)openBGMode;
- (void)closeBGMode;

@end

NS_ASSUME_NONNULL_END
