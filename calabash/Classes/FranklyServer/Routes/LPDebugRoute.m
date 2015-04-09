//
//  LPDebugRoute.m
//  calabash
//
//  Created by Karl Krukow on 30/01/14.
//  Copyright (c) 2014 Xamarin. All rights reserved.
//

#import "LPDebugRoute.h"
#import "LPLog.h"

@implementation LPDebugRoute

- (BOOL) supportsMethod:(NSString *) method atPath:(NSString *) path {
  return [method isEqualToString:@"GET"] || [method isEqualToString:@"POST"];
}


- (NSDictionary *) JSONResponseForMethod:(NSString *) method URI:(NSString *) path data:(NSDictionary *) data {
  if ([method isEqualToString:@"POST"]) {
    NSString *requiredLogLevel = [data valueForKey:@"level"];
    [LPLog setLevelFromString:requiredLogLevel];
  }

  NSString *currentLogLevel = [LPLog currentLevelString];
  NSArray *resultsArray;
  if (!currentLogLevel) {
    resultsArray = @[];
  } else {
    resultsArray = @[currentLogLevel];
  }

  return
  @{
    @"results" : resultsArray,
    @"outcome" : @"SUCCESS"
    };
}

@end
