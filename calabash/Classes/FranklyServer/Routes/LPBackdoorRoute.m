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

#import "LPBackdoorRoute.h"
#import "LPCocoaLumberjack.h"

@implementation LPBackdoorRoute

- (BOOL) supportsMethod:(NSString *) method atPath:(NSString *) path {
  return [method isEqualToString:@"POST"];
}


- (NSDictionary *) JSONResponseForMethod:(NSString *) method URI:(NSString *) path data:(NSDictionary *) data {
  NSString *originalSelStr = [data objectForKey:@"selector"];
  NSString *selectorName = originalSelStr;
  if (![originalSelStr hasSuffix:@":"]) {
    LPLogWarn(@"Selector name is missing a ':'");
    LPLogWarn(@"All backdoor methods must take at least one argument.");
    LPLogWarn(@"Appending a ':' to the selector name.");
    LPLogWarn(@"This will be an error in the future.");
    selectorName = [selectorName stringByAppendingString:@":"];
  }

  SEL selector = NSSelectorFromString(selectorName);
  id<UIApplicationDelegate> delegate = [[UIApplication sharedApplication] delegate];
  if ([delegate respondsToSelector:selector]) {
    id argument = [data objectForKey:@"arg"];
    id result = nil;

    NSMethodSignature *methodSignature;
    methodSignature = [[delegate class] instanceMethodSignatureForSelector:selector];

    NSInvocation *invocation;
    invocation = [NSInvocation invocationWithMethodSignature:methodSignature];

    [invocation setTarget:delegate];
    [invocation setSelector:selector];
    [invocation setArgument:&argument atIndex:2];

    [invocation retainArguments];

    void *buffer;
    [invocation invoke];
    [invocation getReturnValue:&buffer];
    result = (__bridge id)buffer;

    if (!result) {result = [NSNull null];}
    return  @{ @"result" : result, @"outcome" : @"SUCCESS" };
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
