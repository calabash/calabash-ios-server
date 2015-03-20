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

@property(assign, nonatomic) CGFloat sample;
@property(strong, nonatomic) NSDictionary *screenDimensions;

- (id) init_private;

@end

@implementation LPDevice

@synthesize sample = _sample;
@synthesize screenDimensions = _screenDimensions;

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
    UIDevice *device = [UIDevice currentDevice];
    struct utsname systemInfo;
    uname(&systemInfo);
    
    NSDictionary *env = [[NSProcessInfo processInfo] environment];
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

    

    NSString *machine = @(systemInfo.machine);
    UIScreen *s = [UIScreen mainScreen];    
    UIScreenMode *sm = [s currentMode];
    CGSize size = sm.size;

    _sample = 1.0f;
    _screenDimensions = nil;

    if ([@"iPhone7,1" isEqualToString:machine]) {
      //iPhone6+ http://www.paintcodeapp.com/news/ultimate-guide-to-iphone-resolutions
      if (size.width < IPHONE6PLUS.width && size.height < IPHONE6PLUS.height) {
        _sample = (IPHONE6PLUS.width / size.width);
        _sample = (IPHONE6PLUS.height / size.height);
      }
      else {
        _sample = IPHONE6PLUS_SAMPLE;
      }

    } else if ([@"iPhone7,2" isEqualToString:machine]) {
      //iPhone6
      if (CGSizeEqualToSize(size, IPHONE6)) {
        _sample = IPHONE6_SAMPLE;
      }
      else {
        _sample = IPHONE6_DISPLAY_ZOOM_SAMPLE;
      }
    } else {
      if ([@"iPhone Simulator" isEqualToString:[device model]]) {
        
        NSPredicate *iphone6plus = [NSPredicate predicateWithFormat:@"SIMULATOR_VERSION_INFO LIKE '*iPhone 6*Plus*'"];
        NSPredicate *iphone6 = [NSPredicate predicateWithFormat:@"SIMULATOR_VERSION_INFO LIKE '*iPhone 6*'"];
        
        if ([iphone6plus evaluateWithObject:env]) {
          if (size.width < IPHONE6PLUS.width && size.height < IPHONE6PLUS.height) {
            _sample = (IPHONE6PLUS.width / size.width);
            _sample = (IPHONE6PLUS.height / size.height);
          }
          else {
            _sample = IPHONE6PLUS_SAMPLE;
          }
          
        }
        else if ([iphone6 evaluateWithObject:env]) {
          if (CGSizeEqualToSize(size, IPHONE6)) {
            _sample = IPHONE6_SAMPLE;
          }
          else {
            _sample = IPHONE6_DISPLAY_ZOOM_SAMPLE;
          }
        }
      }
    }
    _screenDimensions = [[NSDictionary alloc] initWithObjectsAndKeys:
                         [NSNumber numberWithFloat:size.height], @"height",
                         [NSNumber numberWithFloat:size.width],  @"width",
                         [NSNumber numberWithFloat:scale],       @"scale",
                         [NSNumber numberWithFloat:_sample],      @"sample",
                         nil];
  }
  return self;
}

- (CGFloat) sampleFactor {
  return _sample;
}

- (NSDictionary *) screenDimensions {
  return _screenDimensions;
}

@end
