#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif
//
//  LPDevice.m
//  calabash
//
//  Created by Karl Krukow on 1/30/14.
//  Copyright (c) 2014 Xamarin. All rights reserved.
//

#import "LPDevice.h"
#import "LPTouchUtils.h"
#import "LPCocoaLumberjack.h"
#import <sys/utsname.h>
#include <ifaddrs.h>
#include <arpa/inet.h>
#include <net/if.h>

#define IOS_CELLULAR    @"pdp_ip0"
#define IOS_WIFI        @"en0"
#define IOS_VPN         @"utun0"
#define IP_ADDR_IPv4    @"ipv4"
#define IP_ADDR_IPv6    @"ipv6"

NSString *const LPDeviceSimKeyModelIdentifier = @"SIMULATOR_MODEL_IDENTIFIER";
NSString *const LPDeviceSimKeyVersionInfo = @"SIMULATOR_VERSION_INFO";
NSString *const LPDeviceSimKeyIphoneSimulatorDevice_LEGACY = @"IPHONE_SIMULATOR_DEVICE";

@interface LPDevice ()

@property(strong, nonatomic) NSDictionary *processEnvironment;
@property(strong, nonatomic) NSDictionary *formFactorMap;

- (id) init_private;

- (UIScreen *) mainScreen;
- (UIScreenMode *) currentScreenMode;
- (CGSize) sizeForCurrentScreenMode;
- (CGFloat) scaleForMainScreen;
- (CGFloat) heightForMainScreenBounds;

- (NSString *) physicalDeviceModelIdentifier;
- (NSString *) simulatorModelIdentfier;
- (NSDictionary *) getIPAddresses;

@end

@implementation LPDevice

@synthesize screenDimensions = _screenDimensions;
@synthesize sampleFactor = _sampleFactor;
@synthesize modelIdentifier = _modelIdentifier;
@synthesize formFactor = _formFactor;
@synthesize processEnvironment = _processEnvironment;
@synthesize formFactorMap = _formFactorMap;
@synthesize deviceFamily = _deviceFamily;
@synthesize name = _name;
@synthesize iOSVersion = _iOSVersion;
@synthesize physicalDeviceModelIdentifier = _physicalDeviceModelIdentifier;


- (id) init {
  @throw [NSException exceptionWithName:@"Cannot call init"
                                 reason:@"This is a singleton class"
                                 userInfo:nil];
}

+ (LPDevice *) sharedDevice {
  static LPDevice *shared = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    shared = [[LPDevice alloc] init_private];
  });
  return shared;
}

- (id) init_private {
  self = [super init];
  if (self) {
    // For memoizing.
    _sampleFactor = CGFLOAT_MAX;
  }
  return self;
}

#pragma mark - Convenience Methods for Testing

- (UIScreen *) mainScreen {
  return [UIScreen mainScreen];
}

- (UIScreenMode *) currentScreenMode {
  return [[self mainScreen] currentMode];
}

- (CGSize) sizeForCurrentScreenMode {
  return [self currentScreenMode].size;
}

- (CGFloat) scaleForMainScreen {
  return [[self mainScreen] scale];
}

- (CGFloat) heightForMainScreenBounds {
  return [[self mainScreen] bounds].size.height;
}

#pragma mark - iPhone 6 and 6 Plus Support

// http://www.paintcodeapp.com/news/ultimate-guide-to-iphone-resolutions
// Thanks for the inspiration for iPhone 6 form factor sample.
- (CGFloat) sampleFactor {
  if (_sampleFactor != CGFLOAT_MAX) { return _sampleFactor; }

  _sampleFactor = 1.0f;

  UIScreen *screen = [UIScreen mainScreen];
  CGSize screenSize = screen.bounds.size;
  CGFloat screenHeight = MAX(screenSize.height, screenSize.width);
  CGFloat scale = screen.scale;

  CGFloat nativeScale = scale;
  if ([screen respondsToSelector:@selector(nativeScale)]) {
    nativeScale = screen.nativeScale;
  }


  //CGSize iphone6_size = CGSizeMake(375.0 * scale, 667.0 * scale);
  //CGSize iphone6p_size = CGSizeMake(414.0 * scale, 736.0 * scale);

  CGFloat iphone6_zoom_sample = 1.171875f;
  CGFloat iphone6p_zoom_sample = 0.96f;

  UIScreenMode *screenMode = [screen currentMode];
  CGSize screenSizeForMode = screenMode.size;
  CGFloat pixelAspectRatio = screenMode.pixelAspectRatio;

  LPLogDebug(@"         Form factor: %@", [self formFactor]);
  LPLogDebug(@" Current screen mode: %@", screenMode);
  LPLogDebug(@"Screen size for mode: %@", NSStringFromCGSize(screenSizeForMode));
  LPLogDebug(@"       Screen height: %@", @(screenHeight));
  LPLogDebug(@"        Screen scale: %@", @(scale));
  LPLogDebug(@" Screen native scale: %@", @(nativeScale));
  LPLogDebug(@"Pixel Aspect Ratio: %@", @(pixelAspectRatio));

  if ([self isIPhone6PlusLike]) {
    if (screenHeight == 568.0 && nativeScale > scale) {
      LPLogDebug(@"iPhone 6 Plus: application is not optimized for screen size - adjusting sampleFactor");
      _sampleFactor = iphone6p_zoom_sample;
    } else if (screenHeight == 667.0 && nativeScale <= scale) {
      LPLogDebug(@"iPhone 6 Plus: Zoomed display mode - sampleFactor remains the same");
    }
  } else if ([self isIPhone6Like]) {
    if (screenHeight == 568.0 && nativeScale <= scale) {
      LPLogDebug(@"iPhone 6: application not optimized for screen size - adjusting sampleFactor");
      _sampleFactor = iphone6_zoom_sample;
    } else if (screenHeight == 568.0 && nativeScale > scale) {
      LPLogDebug(@"iPhone 6: Zoomed display mode - sampleFactor remains the same");
    }
  }

  return _sampleFactor;
}

- (NSDictionary *) screenDimensions {
  if (_screenDimensions) { return _screenDimensions; }

  UIScreen *screen = [UIScreen mainScreen];
  UIScreenMode *screenMode = [screen currentMode];
  CGSize size = screenMode.size;
  CGFloat scale = screen.scale;

  CGFloat nativeScale = scale;
  if ([screen respondsToSelector:@selector(nativeScale)]) {
    nativeScale = screen.nativeScale;
  }

  _screenDimensions = @{
                        @"height" : @(size.height),
                        @"width" : @(size.width),
                        @"scale" : @(scale),
                        @"sample" : @([self sampleFactor]),
                        @"native_scale" : @(nativeScale)
                        };

  return _screenDimensions;
}

// http://www.everyi.com/by-identifier/ipod-iphone-ipad-specs-by-model-identifier.html
- (NSDictionary *) formFactorMap {
  if (_formFactorMap) { return _formFactorMap; }

  _formFactorMap =

  @{

    // iPhone 4/4s and iPod 4th
    @"iPhone3,1" : @"iphone 3.5in",
    @"iPhone3,3" : @"iphone 3.5in",
    @"iPhone4,1" : @"iphone 3.5in",
    @"iPod4,1"   : @"iphone 3.5in",

    // iPhone 5/5c/5s and iPod 5th + 6th
    @"iPhone5,1" : @"iphone 4in",
    @"iPhone5,2" : @"iphone 4in",
    @"iPhone5,3" : @"iphone 4in",
    @"iPhone5,4" : @"iphone 4in",
    @"iPhone6,1" : @"iphone 4in",
    @"iPhone6,2" : @"iphone 4in",
    @"iPhone6,3" : @"iphone 4in",
    @"iPhone6,4" : @"iphone 4in",
    @"iPod5,1"   : @"iphone 4in",
    @"iPod6,1"   : @"iphone 4in",

    // iPhone 6/6s
    @"iPhone7,2" : @"iphone 6",
    @"iPhone8,1" : @"iphone 6",

    // iPhone 6+
    @"iPhone7,1" : @"iphone 6+",
    @"iPhone8,2" : @"iphone 6+",

    // iPad Pro
    @"iPad6,7" : @"ipad pro",
    @"iPad6,8" : @"ipad pro"

    };

  return _formFactorMap;
}

- (NSDictionary *) processEnvironment {
  if (_processEnvironment) { return _processEnvironment; }
  _processEnvironment = [[NSProcessInfo processInfo] environment];
  return _processEnvironment;
}

- (NSString *) simulatorModelIdentfier {
  return [self.processEnvironment objectForKey:LPDeviceSimKeyModelIdentifier];
}

- (NSString *) simulatorVersionInfo {
  return [self.processEnvironment objectForKey:LPDeviceSimKeyVersionInfo];
}

- (NSString *) physicalDeviceModelIdentifier {
  if (_physicalDeviceModelIdentifier) { return _physicalDeviceModelIdentifier; }
  struct utsname systemInfo;
  uname(&systemInfo);
  _physicalDeviceModelIdentifier = @(systemInfo.machine);
  return _physicalDeviceModelIdentifier;
}

- (NSString *) deviceFamily {
  if (_deviceFamily) { return _deviceFamily; }
  _deviceFamily = [[UIDevice currentDevice] model];
  return _deviceFamily;
}

- (NSString *) name {
  if (_name) { return _name; }
  _name = [[UIDevice currentDevice] name];
  return _name;
}

- (NSString *) iOSVersion {
  if (_iOSVersion) { return _iOSVersion; }
  _iOSVersion = [[UIDevice currentDevice] systemVersion];
  return _iOSVersion;
}

// Required for clients < 0.16.2 - @see LPVersionRoute
- (NSString *) LEGACY_iPhoneSimulatorDevice {
  return [self.processEnvironment objectForKey:LPDeviceSimKeyIphoneSimulatorDevice_LEGACY];
}

// Required for clients < 0.16.2 - @see LPVersionRoute
- (NSString *) LEGACY_systemFromUname {
  return [self physicalDeviceModelIdentifier];
}

// The hardware name of the device.
- (NSString *) modelIdentifier {
  if (_modelIdentifier) { return _modelIdentifier; }
  if ([self isSimulator]) {
    _modelIdentifier = [self simulatorModelIdentfier];
  } else {
    _modelIdentifier = [self physicalDeviceModelIdentifier];
  }
  return _modelIdentifier;
}

- (NSString *) formFactor {
  if (_formFactor) { return _formFactor; }

  NSString *modelIdentifier = [self modelIdentifier];
  NSString *value = [self.formFactorMap objectForKey:modelIdentifier];

  if (value) {
    _formFactor = value;
  } else {
    if ([self isIPad]) {
      _formFactor = @"ipad";
    } else {
      _formFactor = modelIdentifier;
    }
  }
  return _formFactor;
}

- (BOOL) isSimulator {
  return [self simulatorModelIdentfier] != nil;
}

- (BOOL) isPhysicalDevice {
  return ![self isSimulator];
}

- (BOOL) isIPhone6Like {
  return [[self formFactor] isEqualToString:@"iphone 6"];
}

- (BOOL) isIPhone6PlusLike {
  return [[self formFactor] isEqualToString:@"iphone 6+"];
}

- (BOOL) isIPad {
  return [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
}

- (BOOL) isIPadPro {
  return [[self formFactor] isEqualToString:@"ipad pro"];
}

- (BOOL) isIPhone4Like {
  return [[self formFactor] isEqualToString:@"iphone 3.5in"];
}

- (BOOL) isIPhone5Like {
  return [[self formFactor] isEqualToString:@"iphone 4in"];
}

- (BOOL) isLetterBox {
  CGFloat scale = [self scaleForMainScreen];
  if ([self isIPad] || [self isIPhone4Like] || scale != 2.0) {
    return NO;
  } else {
    return [self heightForMainScreenBounds] * scale == 960;
  }
}

#pragma mark - IP Address

// http://stackoverflow.com/questions/7072989/iphone-ipad-osx-how-to-get-my-ip-address-programmatically

- (NSString *) getIPAddress:(BOOL) preferIPv4 {
  NSArray *searchArray = preferIPv4 ?
  @[ IOS_VPN @"/" IP_ADDR_IPv4, IOS_VPN @"/" IP_ADDR_IPv6, IOS_WIFI @"/" IP_ADDR_IPv4, IOS_WIFI @"/" IP_ADDR_IPv6, IOS_CELLULAR @"/" IP_ADDR_IPv4, IOS_CELLULAR @"/" IP_ADDR_IPv6 ] :
  @[ IOS_VPN @"/" IP_ADDR_IPv6, IOS_VPN @"/" IP_ADDR_IPv4, IOS_WIFI @"/" IP_ADDR_IPv6, IOS_WIFI @"/" IP_ADDR_IPv4, IOS_CELLULAR @"/" IP_ADDR_IPv6, IOS_CELLULAR @"/" IP_ADDR_IPv4 ] ;

  NSDictionary *addresses = [self getIPAddresses];

  __block NSString *address;
  [searchArray enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop)
   {
     address = addresses[key];
     if(address) *stop = YES;
   } ];
  return address ? address : @"0.0.0.0";
}

- (NSDictionary *) getIPAddresses {
  NSMutableDictionary *addresses = [NSMutableDictionary dictionaryWithCapacity:8];

  // retrieve the current interfaces - returns 0 on success
  struct ifaddrs *interfaces;
  if(!getifaddrs(&interfaces)) {
    // Loop through linked list of interfaces
    struct ifaddrs *interface;
    for(interface=interfaces; interface; interface=interface->ifa_next) {
      if(!(interface->ifa_flags & IFF_UP) /* || (interface->ifa_flags & IFF_LOOPBACK) */ ) {
        continue; // deeply nested code harder to read
      }
      const struct sockaddr_in *addr = (const struct sockaddr_in*)interface->ifa_addr;
      char addrBuf[ MAX(INET_ADDRSTRLEN, INET6_ADDRSTRLEN) ];
      if(addr && (addr->sin_family==AF_INET || addr->sin_family==AF_INET6)) {
        NSString *name = [NSString stringWithUTF8String:interface->ifa_name];
        NSString *type;
        if(addr->sin_family == AF_INET) {
          if(inet_ntop(AF_INET, &addr->sin_addr, addrBuf, INET_ADDRSTRLEN)) {
            type = IP_ADDR_IPv4;
          }
        } else {
          const struct sockaddr_in6 *addr6 = (const struct sockaddr_in6*)interface->ifa_addr;
          if(inet_ntop(AF_INET6, &addr6->sin6_addr, addrBuf, INET6_ADDRSTRLEN)) {
            type = IP_ADDR_IPv6;
          }
        }
        if(type) {
          NSString *key = [NSString stringWithFormat:@"%@/%@", name, type];
          addresses[key] = [NSString stringWithUTF8String:addrBuf];
        }
      }
    }
    // Free memory
    freeifaddrs(interfaces);
  }
  return [addresses count] ? addresses : nil;
}

@end
