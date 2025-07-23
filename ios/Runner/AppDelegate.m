#import "AppDelegate.h"
#import "GeneratedPluginRegistrant.h"
#import <SystemConfiguration/CaptiveNetwork.h>
#import <NetworkExtension/NetworkExtension.h>
#import <CoreLocation/CoreLocation.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  
  // 获取Flutter视图控制器
  FlutterViewController* controller = (FlutterViewController*)self.window.rootViewController;
  
  // 创建WiFi Method Channel
  FlutterMethodChannel* wifiChannel = [FlutterMethodChannel
                                      methodChannelWithName:@"com.prms.wifi"
                                      binaryMessenger:controller.binaryMessenger];
  
  // 设置方法调用处理器
  __weak typeof(self) weakSelf = self;
  [wifiChannel setMethodCallHandler:^(FlutterMethodCall* call, FlutterResult result) {
    if ([@"getWifiSSID" isEqualToString:call.method]) {
      [weakSelf getWifiSSID:result];
    } else {
      result(FlutterMethodNotImplemented);
    }
  }];
  
  [GeneratedPluginRegistrant registerWithRegistry:self];
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

- (void)getWifiSSID:(FlutterResult)result {
  self.pendingResult = result;
  
  // 初始化位置管理器
  if (!self.locationManager) {
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
  }
  
  // 检查权限状态
  CLAuthorizationStatus authorizationStatus = [self.locationManager authorizationStatus];
  
  switch (authorizationStatus) {
    case kCLAuthorizationStatusAuthorizedWhenInUse:
    case kCLAuthorizationStatusAuthorizedAlways:
      // 已有权限，直接获取WiFi信息
      [self fetchWifiInfo];
      break;
    case kCLAuthorizationStatusNotDetermined:
      // 请求权限
      [self.locationManager requestWhenInUseAuthorization];
      break;
    case kCLAuthorizationStatusDenied:
    case kCLAuthorizationStatusRestricted:
      // 权限被拒绝
      result([FlutterError errorWithCode:@"PERMISSION_DENIED"
                                 message:@"Location permission is required to get WiFi SSID"
                                 details:nil]);
      self.pendingResult = nil;
      break;
  }
}

- (void)fetchWifiInfo {
  NSArray *interfaceNames = CFBridgingRelease(CNCopySupportedInterfaces());
  
  if (!interfaceNames || interfaceNames.count == 0) {
    if (self.pendingResult) {
      self.pendingResult([FlutterError errorWithCode:@"NO_INTERFACES"
                                             message:@"No network interfaces found"
                                             details:nil]);
      self.pendingResult = nil;
    }
    return;
  }
  
  for (NSString *interfaceName in interfaceNames) {
    NSDictionary *info = CFBridgingRelease(CNCopyCurrentNetworkInfo((__bridge CFStringRef)interfaceName));
    
    if (info) {
      NSString *ssid = info[(NSString *)kCNNetworkInfoKeySSID] ?: @"";
      NSString *bssid = info[(NSString *)kCNNetworkInfoKeyBSSID] ?: @"";
      
      NSDictionary *result = @{
        @"ssid": ssid,
        @"bssid": bssid,
        @"success": @(YES)
      };
      
      if (self.pendingResult) {
        self.pendingResult(result);
        self.pendingResult = nil;
      }
      return;
    }
  }
  
  // 如果没有找到WiFi信息
  NSDictionary *result = @{
    @"ssid": @"",
    @"bssid": @"",
    @"success": @(NO),
    @"error": @"No WiFi connection detected"
  };
  
  if (self.pendingResult) {
    self.pendingResult(result);
    self.pendingResult = nil;
  }
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
  if (!self.pendingResult) {
    return;
  }
  
  switch (status) {
    case kCLAuthorizationStatusAuthorizedWhenInUse:
    case kCLAuthorizationStatusAuthorizedAlways:
      [self fetchWifiInfo];
      break;
    case kCLAuthorizationStatusDenied:
    case kCLAuthorizationStatusRestricted:
      self.pendingResult([FlutterError errorWithCode:@"PERMISSION_DENIED"
                                             message:@"Location permission was denied"
                                             details:nil]);
      self.pendingResult = nil;
      break;
    default:
      break;
  }
}

@end
