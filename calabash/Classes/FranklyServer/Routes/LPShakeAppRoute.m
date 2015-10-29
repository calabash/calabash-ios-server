#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import <UIKit/UIKit.h>
#import "LPShakeAppRoute.h"
#import "LPCocoaLumberjack.h"

@interface UIApplication (LP_SUSPEND_APP_CATEGORY)

- (void) shake;

@end

@interface LPShakeAppRoute ()

- (CGFloat) durationWithDictionary:(NSDictionary *) arguments;

@end

@implementation LPShakeAppRoute

- (BOOL) supportsMethod:(NSString *) method atPath:(NSString *) path {
  return [method isEqualToString:@"GET"];
}

- (CGFloat) durationWithDictionary:(NSDictionary *) arguments {
  NSNumber *durationNumber = [arguments objectForKey:@"duration"];
  if (durationNumber) {
    return [durationNumber doubleValue];
  } else {
    return 0.1;
  }
}

- (NSDictionary *) JSONResponseForMethod:(NSString *) method
                                     URI:(NSString *) path
                                     data:(NSDictionary *) data {

  CGFloat duration = [self durationWithDictionary:data];

  LPLogDebug(@"Shaking device for %d seconds.", duration);

  UIEvent *m = [[NSClassFromString(@"UIMotionEvent") alloc] init];
  [m setValue:[NSNumber numberWithInt:UIEventSubtypeMotionShake] forKey:@"_subtype"];

  [[UIApplication sharedApplication] sendEvent:m];
  [[UIApplication sharedApplication].keyWindow motionBegan:UIEventSubtypeMotionShake withEvent:m];

  dispatch_time_t when = dispatch_time(DISPATCH_TIME_NOW,
                                       (int64_t)(duration * NSEC_PER_SEC));
  dispatch_queue_t queue = dispatch_get_main_queue();

  dispatch_after(when, queue, ^{
    [[UIApplication sharedApplication].keyWindow motionEnded:UIEventSubtypeMotionShake withEvent:m];
  });

  return @{@"outcome" : @"SUCCESS", @"duration": @(duration)};
}

@end
