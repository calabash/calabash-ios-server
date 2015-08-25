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

const static NSString *ARG_KEY = @"arg";  /* for backwards compatibility */
const static NSString *ARGUMENTS_KEY = @"arguments";

@implementation LPBackdoorRoute

- (NSDictionary *)failureWithReason:(NSString *)reason details:(NSString *)details {
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
    LPLogError(@"Expected data dictionary to contain a 'selector' key.\nData = %@", data);
    return [self failureWithReason:@"Missing selector name."
                           details:[NSString stringWithFormat:@"Expected selector name to be provided for backdoor, but no 'selector' key in data '%@'", data]];
  }

  if (data[ARG_KEY] && data[ARGUMENTS_KEY]) {
    LPLogError(@"Expected data dictionary to contain '%@' XOR '%@'.\nData = %@", ARG_KEY, ARGUMENTS_KEY, data);
    return [self failureWithReason:@"Missing selector name."
                           details:[NSString stringWithFormat:@"Expected '%@' OR '%@' key in data, not both. Data: '%@'", ARG_KEY, ARGUMENTS_KEY, data]];
  } else if (!(data[ARG_KEY] || data[ARGUMENTS_KEY])) {
    LPLogError(@"Expected data dictionary to contain an '%@' or '%@' key.\nData = %@", ARG_KEY, ARGUMENTS_KEY, data);
    return [self failureWithReason:[NSString stringWithFormat:@"Missing argument(s) for selector: '%@'",
                                    selectorName]
                           details:[NSString stringWithFormat:@"Expected backdoor selector '%@' to have an argument(s), but found no '%@' or '%@' key in data '%@'", ARG_KEY, ARGUMENTS_KEY, selectorName, data]];
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
      return [self failureWithReason:[NSString stringWithFormat:@"Invoking backdoor resulted in error: %@",
                                      [invocationResult description]]
                             details:[NSString stringWithFormat:@"Invoking backdoor selector '%@' with arguments '%@' could not be completed because '%@'",
                                      selectorName, arguments, [invocationResult description]]];
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
