#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import <UIKit/UIKit.h>
#import "LPSuspendAppRoute.h"
#import "LPCocoaLumberjack.h"
#import "LPInfoPlist.h"
#import "LPInvoker.h"

@interface UIApplication (LP_SUSPEND_APP_CATEGORY)

- (void) suspend;

@end

@interface LPSuspendAppRoute ()

- (CGFloat) durationWithDictionary:(NSDictionary *) arguments;
- (NSString *) stringForApplicationState:(UIApplicationState) state;

@end

@implementation LPSuspendAppRoute

- (BOOL) supportsMethod:(NSString *) method atPath:(NSString *) path {
  return [method isEqualToString:@"POST"] || [method isEqualToString:@"GET"];
}

- (CGFloat) durationWithDictionary:(NSDictionary *) arguments {
  NSNumber *durationNumber = [arguments objectForKey:@"duration"];
  if (durationNumber) {
    return [durationNumber doubleValue];
  } else {
    return 2.0;
  }
}

- (NSString *) stringForApplicationState:(UIApplicationState) state {
  if (UIApplicationStateActive == state) {
    return @"active";
  } else if (UIApplicationStateInactive == state) {
    return @"inactive";
  } else if (UIApplicationStateBackground == state) {
    return @"background";
  } else {
    return @"unknown";
  }
}

- (NSDictionary *) JSONResponseForMethod:(NSString *) method
                                     URI:(NSString *) path
                                    data:(NSDictionary *) data {

  NSDictionary *result = @{};
  if ([method isEqualToString:@"GET"]) {
    UIApplicationState state = [[UIApplication sharedApplication] applicationState];
    result =
    @{
      @"outcome" : @"SUCCESS",
      @"results" : [self stringForApplicationState:state]
      };
  } else {
    CGFloat duration = [self durationWithDictionary:data];

    UIBackgroundTaskIdentifier __block task;

    // I am not sure why this is necessary.  It does not appear to be called.
    // I don't see the log message and I tried to force an app exit by inserting
    // an `abort()` call.
    task = [[UIApplication sharedApplication] beginBackgroundTaskWithName:@"Resume"
                                                        expirationHandler:^{
                                                          LPLogDebug(@"%@ background task expired.",
                                                                     NSStringFromClass([LPSuspendAppRoute class]));
                                                          [[UIApplication sharedApplication] endBackgroundTask:task];
                                                          task = UIBackgroundTaskInvalid;
                                                        }];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

      LPLogDebug(@"%@ is starting a background task to relaunch the app in %@ seconds",
                 NSStringFromClass([LPSuspendAppRoute class]),
                 @(duration));

      dispatch_time_t when = dispatch_time(DISPATCH_TIME_NOW,
                                           (int64_t)(duration * NSEC_PER_SEC));
      dispatch_queue_t queue = dispatch_get_main_queue();
      dispatch_after(when, queue, ^{

        NSString *bundleIdentifier = [[LPInfoPlist new] stringForIdentifier];

        LPLogDebug(@"%@ is bringing %@ to the foreground",
                   NSStringFromClass([LPSuspendAppRoute class]),
                   bundleIdentifier);

        // Private class and method
        id workspace = [NSClassFromString(@"LSApplicationWorkspace") new];
        SEL selector = NSSelectorFromString(@"openApplicationWithBundleID:");

        [LPInvoker invokeSelector:selector
                       withTarget:workspace
                        arguments:@[bundleIdentifier]];

        [[UIApplication sharedApplication] endBackgroundTask:task];
        task = UIBackgroundTaskInvalid;
      });
    });

    // Send the app to the background.
    LPLogDebug(@"%@ is send the app to the background for %@ seconds",
               NSStringFromClass([LPSuspendAppRoute class]),
               @(duration));
    [[UIApplication sharedApplication] suspend];

    result =
    @{
      @"outcome" : @"SUCCESS",
      @"results" : @{ @"duration" : @(duration)}
      };
  }
  return result;
}

@end
