//
//  LPBackdoorRoute.m
//  calabash
//
//  Created by Karl Krukow on 08/04/12.
//  Copyright (c) 2012 LessPainful. All rights reserved.
//
#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import <UIKit/UIKit.h>
#import "LPBackdoorRoute.h"
#import "LPCocoaLumberjack.h"
#import "LPInvoker.h"
#import "LPInvocationResult.h"
#import "LPInvocationError.h"

static NSString *const ARG_KEY = @"arg";  /* for backwards compatibility */
static NSString *const ARGUMENTS_KEY = @"arguments";

@interface LPBackdoorRoute ()

- (NSDictionary *) failureWithReason:(NSString *) reason
                             details:(NSString *) details;
@end

@implementation LPBackdoorRoute

- (NSDictionary *) failureWithReason:(NSString *) reason
                             details:(NSString *) details {
  return @{ @"details" : details, @"reason" : reason, @"outcome" : @"FAILURE" };
}

- (BOOL) supportsMethod:(NSString *) method atPath:(NSString *) path {
  return [method isEqualToString:@"POST"];
}

- (NSDictionary *) JSONResponseForMethod:(NSString *) method
                                     URI:(NSString *) path
                                    data:(NSDictionary *) data {
  NSString *selectorName = data[@"selector"];
  if (!selectorName) {
    LPLogError(@"Expected data dictionary to contain a 'selector' key.\nData = %@",
               data);
    NSString *details;
    details = [NSString stringWithFormat:@"No selector key found in route arguments: '%@'",
               data];
    return [self failureWithReason:@"Missing selector name."
                           details:details];
  }

  if (data[ARG_KEY] && data[ARGUMENTS_KEY]) {
    LPLogError(@"Expected data dictionary to contain '%@' XOR '%@'.\nData = %@",
               ARG_KEY, ARGUMENTS_KEY, data);

    NSString *details;
    details = [NSString stringWithFormat:@"Expected '%@' OR '%@' key in data, not both. Data: '%@'",
               ARG_KEY, ARGUMENTS_KEY, data];
    return [self failureWithReason:@"Missing selector name."
                           details:details];

  } else if (!(data[ARG_KEY] || data[ARGUMENTS_KEY])) {
    LPLogError(@"Expected data dictionary to contain an '%@' or '%@' key.\nData = %@",
               ARG_KEY, ARGUMENTS_KEY, data);
    NSString *reason, *details;
    reason = [NSString stringWithFormat:@"Missing argument(s) for selector: '%@'",
              selectorName];
    details = [NSString stringWithFormat:@"Expected backdoor selector '%@' to have an argument(s), but found no '%@' or '%@' key in data '%@'",
               ARG_KEY, ARGUMENTS_KEY, selectorName, data];
    return [self failureWithReason:reason
                           details:details];
  }

  id arguments = data[ARG_KEY] ? @[data[ARG_KEY]] : data[ARGUMENTS_KEY];

  SEL selector = NSSelectorFromString(selectorName);
  id<UIApplicationDelegate> delegate = [[UIApplication sharedApplication] delegate];
  if ([delegate respondsToSelector:selector]) {
    LPInvocationResult *invocationResult;
    invocationResult = [LPInvoker invokeSelector:selector
                                      withTarget:delegate
                                       arguments:arguments];
    if ([invocationResult isError]) {
      NSString *reason, *details;
      reason = [NSString stringWithFormat:@"Invoking backdoor resulted in error: %@",
                [invocationResult description]];
      details = [NSString stringWithFormat:@"Invoking backdoor selector '%@' with arguments '%@' could not be completed because '%@'",
                 selectorName, arguments, [invocationResult description]];
      return [self failureWithReason:reason
                             details:details];

    } else {
      return
      @{
        @"results": invocationResult.value,
        // Legacy API:  Starting in Calabash 2.0 and Calabash 0.15.0, the 'result'
        // key will be dropped.
        @"result" : invocationResult.value,
        @"outcome" : @"SUCCESS"
        };
    }
  } else {

    NSArray *lines =
    @[
      @"",
      [NSString stringWithFormat:@"You must define '%@' in your UIApplicationDelegate.",
       selectorName],
      @"",
      [NSString stringWithFormat:@"// Example"],
      [NSString stringWithFormat:@"-(NSString *)%@(NSString *)argument {", selectorName],
      [NSString stringWithFormat:@"  // do stuff here"],
      [NSString stringWithFormat:@"  return @\"a result\";"],
      [NSString stringWithFormat:@"}"],
      @"",
      @"// Documentation",
      @"http://developer.xamarin.com/guides/testcloud/calabash/working-with/backdoors/#backdoor_in_iOS",
      @"",
      @""
      ];

    NSString *details = [lines componentsJoinedByString:@"\n"];

    NSString *reason = [NSString stringWithFormat:@"The backdoor: '%@' is undefined.",
                        selectorName];
    return  @{ @"details" : details, @"reason" : reason, @"outcome" : @"FAILURE" };
  }
}

@end
