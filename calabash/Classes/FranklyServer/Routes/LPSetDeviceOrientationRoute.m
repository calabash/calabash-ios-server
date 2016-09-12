#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import <UIKit/UIKit.h>
#import "LPSetDeviceOrientationRoute.h"
#import "LPOrientationOperation.h"
#import "LPCocoaLumberjack.h"

@interface UIDevice (LP_DEVICE_ORIENTATION_CATEGORY)

-(void)setOrientation:(NSInteger)orientation animated:(BOOL)animated;
-(void)setOrientation:(NSInteger)orientation;

@end

@interface LPSetDeviceOrientationRoute ()

- (NSInteger)orientationWithDictionary:(NSDictionary *)arguments;
- (NSInteger)orientationForString:(NSString *)string;
- (BOOL)isValidUIDeviceOrientation:(NSInteger)orientation;

@end

@implementation LPSetDeviceOrientationRoute

- (BOOL) supportsMethod:(NSString *) method atPath:(NSString *) path {
  return [method isEqualToString:@"POST"];
}

- (NSInteger)orientationForString:(NSString *)string {
  NSInteger value;

  if ([string isEqualToString:@"up"] ||
      [string isEqualToString:@"top"] ||
      [string isEqualToString:@"upside down"]) {
    value = (NSInteger)UIDeviceOrientationPortraitUpsideDown;
  } else if ([string isEqualToString:@"bottom"] ||
             [string isEqualToString:@"down"] ||
             [string isEqualToString:@"portrait"]) {
    value = (NSInteger)UIDeviceOrientationPortrait;
  } else if ([string isEqualToString:@"left"] ||
             [string isEqualToString:@"landscape right"]) {
      value = (NSInteger)UIDeviceOrientationLandscapeRight;
  } else if ([string isEqualToString:@"right"] ||
             [string isEqualToString:@"landscape left"]) {
    value = (NSInteger)UIDeviceOrientationLandscapeLeft;
  } else {
    LPLogDebug(@"Cannot map orientation '%@' to a portrait, landscape right, \
               landscape left, or upside down.", string);
    LPLogDebug(@"Defaulting to portrait");
    value = (NSInteger)UIDeviceOrientationPortrait;

  }
  return value;
}

- (BOOL)isValidUIDeviceOrientation:(NSInteger)orientation {
  return (orientation >= UIDeviceOrientationPortrait &&
          orientation <= UIDeviceOrientationLandscapeRight);
}

- (NSInteger)orientationWithDictionary:(NSDictionary *)arguments {
  id value = arguments[@"orientation"];

  NSInteger orientation;

  if (!value) {
    LPLogDebug(@"Expected key 'orientation' to have a value in arguments: %@",
               arguments);
    LPLogDebug(@"Setting orientation to portrait");
    orientation = (NSInteger)UIDeviceOrientationPortrait;
  } else if ([value isKindOfClass:[NSString class]]) {
    NSString *string = (NSString *)value;
    orientation = [self orientationForString:string];
  } else if ([value isKindOfClass:[NSNumber class]]) {
    NSNumber *number = (NSNumber *)value;
    orientation = [number integerValue];
  } else {
    LPLogDebug(@"Expected an NSNumber or NSString for key 'orienation' in arguments:\
               %@, but found %@", arguments, [value class]);
    LPLogDebug(@"Setting orientation to portrait");
    orientation = (NSInteger)UIDeviceOrientationPortrait;
  }

  if (![self isValidUIDeviceOrientation:orientation]) {
    LPLogDebug(@"Normalized orientation %@ to UIDeviceOrientation '%@' which is\
               an invalid orientation.", value, @(orientation));
    LPLogDebug(@"Setting orientation to portrait");
    orientation = (NSInteger)UIDeviceOrientationPortrait;
  }

  return orientation;
}

- (NSDictionary *) JSONResponseForMethod:(NSString *) method
                                     URI:(NSString *) path
                                    data:(NSDictionary *) data {

  NSInteger targetOrientation = [self orientationWithDictionary:data];

  [[UIDevice currentDevice] setOrientation:targetOrientation
                                  animated:YES];

  NSString *statusBarOrientation = [LPOrientationOperation statusBarOrientation];
  NSString *deviceOrientation = [LPOrientationOperation deviceOrientation];
  NSDictionary *result =
  @{
    @"outcome" : @"SUCCESS",
    @"results" : @{
        @"status_bar_orientation" : statusBarOrientation,
        @"device_orientation" : deviceOrientation
        }
    };
  return result;
}

@end
