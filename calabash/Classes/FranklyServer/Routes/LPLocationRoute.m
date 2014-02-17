//
//  LPLocationRoute.h
//  calabash
//
//  Created by Karl Krukow on Nov 2013.
//  Copyright (c) 2013 Xamarin. All rights reserved.
//
//

#import "LPLocationRoute.h"

// todo missing import of UIAutomation.h in LPLocationRoute.m
@implementation LPLocationRoute

- (BOOL) supportsMethod:(NSString *) method atPath:(NSString *) path {
  return [method isEqualToString:@"POST"];
}


- (NSDictionary *) JSONResponseForMethod:(NSString *) method URI:(NSString *) path data:(NSDictionary *) data {
  NSString *action = [data objectForKey:@"action"];
  if ([action isEqualToString:@"change_location"]) {
    NSNumber *lat = [data objectForKey:@"latitude"];
    if (!lat) {
      return [NSDictionary dictionaryWithObjectsAndKeys:@"FAILURE", @"outcome",
                                                        @"latitude must be specified", @"reason",
                                                        @"", @"details", nil];
    }
    NSNumber *lon = [data objectForKey:@"longitude"];
    if (!lon) {
      return [NSDictionary dictionaryWithObjectsAndKeys:@"FAILURE", @"outcome",
                                                        @"longitude must be specified", @"reason",
                                                        @"", @"details", nil];
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-method-access"
#pragma clang diagnostic ignored "-Wundeclared-selector"
    id tgt = [NSClassFromString(@"UIATarget") localTarget];
    if (tgt && [tgt respondsToSelector:@selector(setLocation:)]) {
      [tgt setLocation:[NSDictionary dictionaryWithObjectsAndKeys:lat, @"latitude",
                                                                  lon, @"longitude",
                                                                  nil]];
      return [NSDictionary dictionaryWithObjectsAndKeys:[NSArray array], @"results",
                                                        @"SUCCESS", @"outcome",
                                                        nil];
    } else {
      NSString *message = nil;
      if (!tgt) {
        message = @"UIAutomation is not linked for some reason.";
      } else {
        message = @"setLocation is unsupported in this iOS version.";
      }
      return [NSDictionary dictionaryWithObjectsAndKeys:@"FAILURE", @"outcome",
                                                        message, @"reason",
                                                        @"", @"details", nil];
    }
  }

#pragma clang diagnostic pop

  return [NSDictionary dictionaryWithObjectsAndKeys:@"FAILURE", @"outcome",
                                                    [NSString stringWithFormat:@"action %@ not recognized",
                                                                               action], @"reason",
                                                    @"", @"details", nil];
}

@end
