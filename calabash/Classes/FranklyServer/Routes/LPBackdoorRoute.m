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

@implementation LPBackdoorRoute

- (BOOL) supportsMethod:(NSString *) method atPath:(NSString *) path {
  return [method isEqualToString:@"POST"];
}


- (NSDictionary *) JSONResponseForMethod:(NSString *) method URI:(NSString *) path data:(NSDictionary *) data {
  NSString *originalSelStr = [data objectForKey:@"selector"];
  NSString *selectorName = originalSelStr;
  if (![originalSelStr hasSuffix:@":"]) {
    selectorName = [selectorName stringByAppendingString:@":"];
  }

  SEL selector = NSSelectorFromString(selectorName);

  if ([[[UIApplication sharedApplication] delegate] respondsToSelector:selector]) {
    id argument = [data objectForKey:@"arg"];
    id result = [[[UIApplication sharedApplication] delegate]
            performSelector:selector withObject:argument];
    if (!result) {result = [NSNull null];}
    return [NSDictionary dictionaryWithObjectsAndKeys:result, @"result",
                                                      @"SUCCESS", @"outcome",
                                                      nil];
  } else {

    NSString *details = [NSString stringWithFormat:@"you must define the selector '%@' in your UIApplicationDelegate.",
                                                   selectorName];
    NSString *exDecl0 = @"// declaration";
    NSString *exDecl1 = [NSString stringWithFormat:@"-(id)%@ (id)arg;", selectorName];
    NSString *exImp0 = @"// implementation";
    NSString *exImp1 = [NSString stringWithFormat:@"-(id)%@ (id)anArg {",
                                                  selectorName];
    NSString *exImp2 = [NSString stringWithFormat:@"  // do custom stuff"];
    NSString *exImp3 = [NSString stringWithFormat:@"  // return examples"];
    NSString *exImp4 = [NSString stringWithFormat:@"  return @\"OK\";"];
    NSString *exImp5 = [NSString stringWithFormat:@"  return [NSArray arrayWithObjects:@\"a\",@\"b\",nil];"];
    NSString *exImp6 = [NSString stringWithFormat:@"  return nil;"];
    NSString *exImp7 = [NSString stringWithFormat:@"}"];
    NSString *usage0 = [NSString stringWithFormat:@"// Ruby usage"];
    NSString *usage1 = [NSString stringWithFormat:@"backdoor('%@', '<arg>')",
                                                  selectorName];

    NSArray *exArr = [NSArray arrayWithObjects:details, @"\n", exDecl0, exDecl1,
                                               @"\n", exImp0, exImp1, exImp2,
                                               exImp3, exImp4, exImp5, exImp6,
                                               exImp7, @"\n", usage0, usage1,
                                               nil];
    NSString *detailsStr = [exArr componentsJoinedByString:@"\n"];

    NSString *reasonStr = [NSString stringWithFormat:@"application delegate does not respond to selector '%@'",
                                                     selectorName];
    return [NSDictionary dictionaryWithObjectsAndKeys:detailsStr, @"details",
                                                      reasonStr, @"reason",
                                                      @"FAILURE", @"outcome",
                                                      nil];
  }
}

@end
