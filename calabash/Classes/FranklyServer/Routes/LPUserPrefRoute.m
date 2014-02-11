//
//  LPUserPrefRoute.m
//  calabash
//
//  Created by Karl Krukow on 02/02/12.
//  Copyright (c) 2012 LessPainful. All rights reserved.
//

#import "LPUserPrefRoute.h"

@implementation LPUserPrefRoute
- (BOOL) supportsMethod:(NSString *) method atPath:(NSString *) path {
  return [method isEqualToString:@"POST"] || [method isEqualToString:@"GET"];
}


- (NSDictionary *) JSONResponseForMethod:(NSString *) method URI:(NSString *) path data:(NSDictionary *) data {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  [ud synchronize];

  NSString *key = [data valueForKey:@"key"];
  id curVal = [ud valueForKey:key];

  if ([method isEqualToString:@"POST"]) {

    id val = [data valueForKey:@"value"];

    if ([val isKindOfClass:[NSNull class]]) {
      [ud removeObjectForKey:key];
    } else {
      [ud setValue:val forKey:key];
    }


    [ud synchronize];

    return [NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObjects:val,
                                                                                curVal,
                                                                                nil], @"results",
                                                      @"SUCCESS", @"outcome",
                                                      nil];
  }
  return [NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObjects:curVal,
                                                                              nil], @"results",
                                                    @"SUCCESS", @"outcome",
                                                    nil];
}
@end
