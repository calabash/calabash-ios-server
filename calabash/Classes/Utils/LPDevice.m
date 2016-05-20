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

/*
https://github.com/facebook/WebDriverAgent/blob/master/LICENSE

UIDevice + Wifi Address
 BSD License

 For WebDriverAgent software

 Copyright (c) 2015-present, Facebook, Inc. All rights reserved.

 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:

 * Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.

 * Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.

 * Neither the name Facebook nor the names of its contributors may be used to
 endorse or promote products derived from this software without specific
 prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
 ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

*/

#import "LPDevice.h"
#import "LPTouchUtils.h"
#import "LPCocoaLumberjack.h"
#import <sys/utsname.h>
#import <arpa/inet.h>
#import <ifaddrs.h>

#pragma mark - IP Address

@interface UIDevice (LPDEVICE_WIFI)

- (NSString *) LPWifiIPAddress;

@end

@implementation UIDevice (LPDEVICE_WIFI)

- (NSString *) LPWifiIPAddress {
  struct ifaddrs *interfaces = NULL;
  struct ifaddrs *temp_addr = NULL;
  int success = getifaddrs(&interfaces);
  if (success != 0) {
    freeifaddrs(interfaces);
    return nil;
  }

  NSString *address;
  temp_addr = interfaces;
  while(temp_addr != NULL) {
    if(temp_addr->ifa_addr->sa_family != AF_INET) {
      temp_addr = temp_addr->ifa_next;
      continue;
    }
    NSString *interfaceName = [NSString stringWithUTF8String:temp_addr->ifa_name];
    if([interfaceName rangeOfString:@"en"].location == NSNotFound) {
      temp_addr = temp_addr->ifa_next;
      continue;
    }
    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
    break;
  }
  freeifaddrs(interfaces);
  return address;
}

@end

NSString *const LPDeviceSimKeyModelIdentifier = @"SIMULATOR_MODEL_IDENTIFIER";
NSString *const LPDeviceSimKeyVersionInfo = @"SIMULATOR_VERSION_INFO";
NSString *const LPDeviceSimKeyIphoneSimulatorDevice_LEGACY = @"IPHONE_SIMULATOR_DEVICE";

@interface LPDevice ()

@property(strong, nonatomic) NSDictionary *processEnvironment;
@property(strong, nonatomic) NSDictionary *formFactorMap;
@property(copy, nonatomic) NSString *ipAddress;

- (id) init_private;

- (UIScreen *) mainScreen;
- (UIScreenMode *) currentScreenMode;
- (CGSize) sizeForCurrentScreenMode;
- (CGFloat) scaleForMainScreen;
- (CGFloat) heightForMainScreenBounds;

- (NSString *) physicalDeviceModelIdentifier;
- (NSString *) simulatorModelIdentfier;

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
@synthesize ipAddress = _ipAddress;


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

  _sampleFactor = 1.0;

  UIScreen *screen = [UIScreen mainScreen];
  CGSize screenSize = screen.bounds.size;
  CGFloat screenHeight = MAX(screenSize.height, screenSize.width);
  CGFloat scale = screen.scale;

  CGFloat nativeScale = scale;
  if ([screen respondsToSelector:@selector(nativeScale)]) {
    nativeScale = screen.nativeScale;
  }

  CGFloat iphone6_zoom_sample = 1.171875;
  CGFloat iphone6p_zoom_sample = 0.96;

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
    if (screenHeight == 568.0 && nativeScale > scale) { // native => 2.88
      LPLogDebug(@"iPhone 6 Plus: Zoom display mode and app is not optimized for screen size - adjusting sampleFactor");
      _sampleFactor = iphone6p_zoom_sample;
    } else if (screenHeight == 667.0 && nativeScale <= scale) { // native => ???
      LPLogDebug(@"iPhone 6 Plus: Zoomed display mode - sampleFactor remains the same");
    } else if (screenHeight == 736 && nativeScale < scale) { // native => 2.61
      LPLogDebug(@"iPhone 6 Plus: Standard Display and app is not optimized for screen size - sampleFactor remains the same");
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

    // iPhone 5/5c/5s, iPod 5th + 6th, and 6se
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
    @"iPhone8,4" : @"iphone 4in",

    // iPhone 6/6s
    @"iPhone7,2" : @"iphone 6",
    @"iPhone8,1" : @"iphone 6",

    // iPhone 6+
    @"iPhone7,1" : @"iphone 6+",
    @"iPhone8,2" : @"iphone 6+",

    // iPad Pro 13in
    @"iPad6,7" : @"ipad pro",
    @"iPad6,8" : @"ipad pro",

    // iPad Pro 9in
    @"iPad6,3" : @"ipad pro",
    @"iPad6,4" : @"ipad pro"

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

- (NSString *) getIPAddress {
  if (_ipAddress) { return _ipAddress; }

  _ipAddress = [[UIDevice currentDevice] LPWifiIPAddress];
  return _ipAddress;
}

@end

