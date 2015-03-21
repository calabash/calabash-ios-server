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
#import <sys/utsname.h>

@interface LPDevice ()

@property(strong, nonatomic) NSPredicate *iPhone6SimPredicate;
@property(strong, nonatomic) NSPredicate *iPhone6PlusSimPredicate;

- (id) init_private;

@end

@implementation LPDevice

@synthesize screenDimensions = _screenDimensions;
@synthesize sampleFactor = _sampleFactor;
@synthesize system = _system;
@synthesize model = _model;

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

    // http://www.paintcodeapp.com/news/ultimate-guide-to-iphone-resolutions
    // Thanks for the inspiration for iPhone 6 form factor sample.

    CGFloat scale = [UIScreen mainScreen].scale;

    const CGSize IPHONE6_TARGET_SPACE = CGSizeMake(375.0f, 667.0f);

    const CGSize IPHONE6PLUS_TARGET_SPACE = CGSizeMake(414.0f, 736.0f);

    const CGSize IPHONE6PLUS = CGSizeMake(IPHONE6PLUS_TARGET_SPACE.width*scale,
                                          IPHONE6PLUS_TARGET_SPACE.height*scale);


    CGSize IPHONE6 = CGSizeMake(IPHONE6_TARGET_SPACE.width*scale,
                                IPHONE6_TARGET_SPACE.height*scale);


    const CGFloat IPHONE6_SAMPLE = 1.0f;
    const CGFloat IPHONE6PLUS_SAMPLE = 1.0f;
    const CGFloat IPHONE6_DISPLAY_ZOOM_SAMPLE = 1.171875f;

    UIScreen *s = [UIScreen mainScreen];    
    UIScreenMode *sm = [s currentMode];
    CGSize size = sm.size;

    _sampleFactor = 1.0f;
    _screenDimensions = nil;

    if ([self iPhone6Plus]) {
      if (size.width < IPHONE6PLUS.width && size.height < IPHONE6PLUS.height) {
        _sampleFactor = (IPHONE6PLUS.width / size.width);
        _sampleFactor = (IPHONE6PLUS.height / size.height);
      } else {
        _sampleFactor = IPHONE6PLUS_SAMPLE;
      }
    } else if ([self iPhone6]) {
      if (CGSizeEqualToSize(size, IPHONE6)) {
        _sampleFactor = IPHONE6_SAMPLE;
      } else {
        _sampleFactor = IPHONE6_DISPLAY_ZOOM_SAMPLE;
      }
    } else {
      if ([self simulator]) {
        if ([self iPhone6Plus]) {
          if (size.width < IPHONE6PLUS.width && size.height < IPHONE6PLUS.height) {
            _sampleFactor = (IPHONE6PLUS.width / size.width);
            _sampleFactor = (IPHONE6PLUS.height / size.height);
          } else {
            _sampleFactor = IPHONE6PLUS_SAMPLE;
          }
        } else if ([self iPhone6]) {
          if (CGSizeEqualToSize(size, IPHONE6)) {
            _sampleFactor = IPHONE6_SAMPLE;
          } else {
            _sampleFactor = IPHONE6_DISPLAY_ZOOM_SAMPLE;
          }
        }
      }
    }

    _screenDimensions = @{@"height" : [NSNumber numberWithFloat:size.height],
                          @"width" : [NSNumber numberWithFloat:size.width],
                          @"scale" : [NSNumber numberWithFloat:scale],
                          @"sample" : [NSNumber numberWithFloat:_sampleFactor]};
  }
  return self;
}

- (NSString *) system {
  if (_system) { return _system; }
  struct utsname systemInfo;
  uname(&systemInfo);
  _system = @(systemInfo.machine);
  return _system;
}

- (NSString *) model {
  if (_model) { return _model; }
  UIDevice *device = [UIDevice currentDevice];
  _model = [device model];
  return _model;
}

- (BOOL) simulator {
  UIDevice *device = [UIDevice currentDevice];
  return [[device model] isEqualToString:@"iPhone Simulator"];
}

- (NSPredicate *) iPhone6SimPredicate {
  if (_iPhone6SimPredicate) { return _iPhone6SimPredicate; }
  NSString *key = @"SIMULATOR_VERSION_INFO";
  NSString *value = @"*iPhone 6*";
  NSPredicate *likePredicate = [NSPredicate predicateWithFormat:@"%K LIKE %@",
                                key, value];
  NSPredicate *iPhone6PlusPred = self.iPhone6PlusSimPredicate;
  NSPredicate *notLikePredicate;
  notLikePredicate = [NSCompoundPredicate notPredicateWithSubpredicate:iPhone6PlusPred];
  NSArray *array = @[likePredicate, notLikePredicate];
  _iPhone6SimPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:array];
  return _iPhone6SimPredicate;
}

- (NSPredicate *) iPhone6PlusSimPredicate {
  if (_iPhone6PlusSimPredicate) { return _iPhone6PlusSimPredicate; }
  NSString *key = @"SIMULATOR_VERSION_INFO";
  NSString *value = @"*iPhone 6*Plus*";
  _iPhone6PlusSimPredicate = [NSPredicate predicateWithFormat:@"%K LIKE %@",
                           key, value];
  return _iPhone6PlusSimPredicate;
}

- (BOOL) iPhone6 {
  if ([self simulator]) {
    NSDictionary *env = [[NSProcessInfo processInfo] environment];
    return [self.iPhone6SimPredicate evaluateWithObject:env];
  } else {
    return [[self system] isEqualToString:@"iPhone7,2"];
  }
}

- (BOOL) iPhone6Plus {
  if ([self simulator]) {
    NSDictionary *env = [[NSProcessInfo processInfo] environment];
    return [self.iPhone6PlusSimPredicate evaluateWithObject:env];
  } else {
    return [[self system] isEqualToString:@"iPhone7,1"];
  }
}

@end
