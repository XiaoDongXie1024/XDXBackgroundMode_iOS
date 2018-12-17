//
//  XDXLocationManager.m
//  XDXBackgroundMode_iOS
//
//  Created by 小东邪 on 2018/12/12.
//  Copyright © 2018 小东邪. All rights reserved.
//

#import "XDXLocationManager.h"
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreLocation/CLLocation.h>
#import "log4cplus.h"
#import "XDXBGModeManager.h"

static const char *ModuleName = "XDXLocationManager";

@interface XDXLocationManager ()<CLLocationManagerDelegate>

@property (nonatomic, assign) BOOL isCollectLocation;

@property (nonatomic, strong) CLLocationManager   *locationManager;
@property (nonatomic, strong) XDXBGModeManager    *bgModeManager;

@end

@implementation XDXLocationManager
SingletonM

+ (instancetype )getInstance {
    XDXLocationManager *instance = [[self alloc] init];
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [instance configureBaseInfo];
    });
    return instance;
}

- (void)configureBaseInfo {
    _isCollectLocation = NO;
    
    _bgModeManager = [[XDXBGModeManager alloc] init];
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate                           = self;
    _locationManager.desiredAccuracy                    = kCLLocationAccuracyBestForNavigation;
    _locationManager.pausesLocationUpdatesAutomatically = NO;
    self.locationManager.distanceFilter                 = kCLDistanceFilterNone; // 不移动也可以后台刷新回调
    
    if([[UIDevice currentDevice].systemVersion floatValue]>= 8.0) {
        [self.locationManager requestAlwaysAuthorization];
    }
    
    [self.locationManager startUpdatingLocation];
}

#pragma mark - Notification
-(void)applicationEnterBackground {
    [self startBGLocationService];
    [self.bgModeManager beginNewBackgroundTask];
}

#pragma mark - Main Func
- (void)openBGMode {
    self.isSupportBGMode = YES;
    // Note : You need to open background mode in the project setting, Otherwise the app will crash.
    _locationManager.allowsBackgroundLocationUpdates = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)closeBGMode {
    self.isSupportBGMode = NO;
    [self.bgModeManager endAllBGTask];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
}

+ (BOOL)isCanGetLocationInformation {
    XDXLocationManager *instance = [self getInstance];
    BOOL isSuccess = YES;
    if ([CLLocationManager locationServicesEnabled] == NO) {
        log4cplus_error("XDXBGModeManager", "%s - You currently have all location services for this device disabled", ModuleName);
        isSuccess = NO;
    }else {
        CLAuthorizationStatus authorizationStatus = [CLLocationManager authorizationStatus];
        
        if(authorizationStatus == kCLAuthorizationStatusDenied || authorizationStatus == kCLAuthorizationStatusRestricted) {
            log4cplus_error("XDXBGModeManager", "%s - AuthorizationStatus failed",ModuleName);
            isSuccess = NO;
        }else {
            if (instance.latitude == 0 && instance.longitude == 0) {
                isSuccess = NO;
                log4cplus_error("XDXBGModeManager", "%s - Current latitude and longitude is 0 !",ModuleName);
            }
        }
    }
    
    return isSuccess;
}

#pragma mark - BG Mode
- (void)startBGLocationService {
    if ([CLLocationManager locationServicesEnabled] == NO) {
        log4cplus_error("XDXBGModeManager", "%s - You currently have all location services for this device disabled", ModuleName);
    }else {
        CLAuthorizationStatus authorizationStatus = [CLLocationManager authorizationStatus];
        
        if(authorizationStatus == kCLAuthorizationStatusDenied || authorizationStatus == kCLAuthorizationStatusRestricted) {
            log4cplus_error("XDXBGModeManager", "%s - AuthorizationStatus failed",ModuleName);
        }else {
            log4cplus_info("XDXBGModeManager", "%s - Start Background Mode Location service !",ModuleName);
            self.locationManager.distanceFilter = kCLDistanceFilterNone;
            
            if([[UIDevice currentDevice].systemVersion floatValue]>= 8.0) {
                [self.locationManager requestAlwaysAuthorization];
            }
            [self.locationManager startUpdatingLocation];
        }
    }
}

-(void)restartLocation {
    self.locationManager.delegate       = self;
    self.locationManager.distanceFilter = kCLDistanceFilterNone; // 不移动也可以后台刷新回调
    if ([[UIDevice currentDevice].systemVersion floatValue]>= 8.0) {
        [self.locationManager requestAlwaysAuthorization];
    }
    [self.locationManager startUpdatingLocation];
    [self.bgModeManager beginNewBackgroundTask];
}

-(void)stopLocation {
    log4cplus_debug("XDXBGModeManager", "%s - Stop Background Mode Location service !",ModuleName);
    _isCollectLocation = NO;
    [self.locationManager stopUpdatingLocation];
}

#pragma mark --delegate
// We need to restart and close location info to release background mode.
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    CLLocation *location = [locations lastObject];    //当前位置信息
    
    self.longitude = location.coordinate.longitude;
    self.latitude  = location.coordinate.latitude;
    
    if (self.isSupportBGMode) {
        //如果正在10秒定时收集的时间，不需要执行延时开启和关闭定位
        if (_isCollectLocation) {
            return;
        }
        [self performSelector:@selector(restartLocation) withObject:nil afterDelay:120];
        [self performSelector:@selector(stopLocation)    withObject:nil afterDelay:10];
        _isCollectLocation = YES;//标记正在定位
    }
}

- (void)locationManager: (CLLocationManager *)manager didFailWithError: (NSError *)error {
    log4cplus_error("XDXBGModeManager", "%s - locationManager error:%s",ModuleName, [NSString stringWithFormat:@"%@",error].UTF8String);
    
    self.latitude  = 0;
    self.longitude = 0;
    
    switch([error code])
    {
        case kCLErrorNetwork:
            log4cplus_error("XDXBGModeManager", "%s - %s : Please check the network connection !",ModuleName, __func__);
            
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Location Warning" message:
                                            @"Please check the network connection" preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"OK" style:
                                               UIAlertActionStyleCancel handler:nil];
                [alert addAction:cancelAction];
                UIViewController *vc = [UIApplication sharedApplication].windows[0].rootViewController;
                [vc presentViewController:alert animated:YES completion:nil];
            });
            
            break;
        case kCLErrorDenied:
        {
            log4cplus_error("XDXBGModeManager", "%s - %s : Please open location authority on the setting if you want to use our service!",ModuleName, __func__);
            
            static dispatch_once_t onceToken2;
            dispatch_once(&onceToken2, ^{
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Location Warning" message:
                                            @"Please allow our app access the location always on the setting->Privacy->Location Services !" preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"OK" style:
                                               UIAlertActionStyleCancel handler:nil];
                [alert addAction:cancelAction];
                UIViewController *vc = [UIApplication sharedApplication].windows[0].rootViewController;
                [vc presentViewController:alert animated:YES completion:nil];
            });
            
        }
            break;
        default:
            break;
    }
}

@end
