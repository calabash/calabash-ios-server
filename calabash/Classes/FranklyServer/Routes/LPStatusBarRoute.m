#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPStatusBarRoute.h"
#import "LPOrientationOperation.h"

@implementation LPStatusBarRoute

- (BOOL) supportsMethod:(NSString *) method atPath:(NSString *) path {
  return [method isEqualToString:@"GET"];
}

- (NSDictionary *) JSONResponseForMethod:(NSString *) method
                                     URI:(NSString *) path
                                    data:(NSDictionary *) data {

  CGRect frame = [[UIApplication sharedApplication] statusBarFrame];
  BOOL hidden = [[UIApplication sharedApplication] isStatusBarHidden];
  NSString *statusBarOrientation = [LPOrientationOperation statusBarOrientation];

  NSDictionary *result =
  @{
    @"outcome" : @"SUCCESS",
    @"results" : @{
        @"orientation" : statusBarOrientation,
        @"frame" : @{
            @"height" : @(frame.size.height),
            @"width" : @(frame.size.width),
            @"x" : @(frame.origin.x),
            @"y" : @(frame.origin.y),
            },
        @"hidden" : @(hidden)
        }
    };
  return result;
}

@end
