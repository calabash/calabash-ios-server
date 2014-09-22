//
//  LPDevice.m
//  calabash
//
//  Created by Karl Krukow on 1/30/14.
//  Copyright (c) 2014 Xamarin. All rights reserved.
//

#import "LPDevice.h"
#import <sys/utsname.h>


@implementation LPDevice {
  CGFloat _sample;

}
+ (LPDevice *) sharedDevice {
  static LPDevice *shared = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    shared = [[LPDevice alloc] init];
  });
  return shared;
}


- (id) init {
  self = [super init];
  if (self) {
    UIDevice *device = [UIDevice currentDevice];
    struct utsname systemInfo;
    uname(&systemInfo);
    
    NSDictionary *env = [[NSProcessInfo processInfo] environment];
    CGFloat scale = [UIScreen mainScreen].scale;
    
    CGSize IPHONE6PLUS_DISPLAY_ZOOM = CGSizeMake(375*scale, 667*scale);
    const CGFloat IPHONE6PLUS_DISPLAY_ZOOM_SAMPLE = 0.96f;
    
    CGSize IPHONE6PLUS = CGSizeMake(414*scale, 736*scale);
    const CGFloat IPHONE6PLUS_SAMPLE = 0.8695652173913f;

    
    CGSize IPHONE6_DISPLAY_ZOOM = CGSizeMake(320*scale, 568*scale);
    const CGFloat IPHONE6_DISPLAY_ZOOM_SAMPLE = 1.171875f;
    
    CGSize IPHONE6 = CGSizeMake(375*scale, 667*scale);
    const CGFloat IPHONE6_SAMPLE = 1.0f;
    
    NSString *machine = @(systemInfo.machine);
    UIScreen *s = [UIScreen mainScreen];    
    UIScreenMode *sm = [s currentMode];
    CGSize size = sm.size;

    
    if ([@"iPhone7,1" isEqualToString:machine]) {
      //iPhone6+ http://www.paintcodeapp.com/news/ultimate-guide-to-iphone-resolutions
      if (CGSizeEqualToSize(size, IPHONE6PLUS_DISPLAY_ZOOM)) {
        _sample = IPHONE6PLUS_DISPLAY_ZOOM_SAMPLE;
        
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
        
        NSPredicate *iphone6plus = [NSPredicate predicateWithFormat:@"SIMULATOR_VERSION_INFO LIKE '*iPhone*6*Plus*'"];
        NSPredicate *iphone6 = [NSPredicate predicateWithFormat:@"SIMULATOR_VERSION_INFO LIKE '*iPhone*6*'"];
        
        if ([iphone6plus evaluateWithObject:env]) {
          if (CGSizeEqualToSize(size, IPHONE6PLUS_DISPLAY_ZOOM)) {
            _sample = IPHONE6PLUS_DISPLAY_ZOOM_SAMPLE;
            
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
  }
  else {
    _sample = 1.0f;
  }
 return self;
}

-(CGFloat)sampleFactor {
  return _sample;
}


- (void) dealloc {
  [super dealloc];
}



@end
