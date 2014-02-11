//
//  LPAppPropertyRoute.m
//  calabash
//
//  Created by Jim McBeath on 01/03/13.
//  Copyright (c) 2012 LessPainful.
//

#import "LPAppPropertyRoute.h"

@implementation LPAppPropertyRoute
- (BOOL) supportsMethod:(NSString *) method atPath:(NSString *) path {
  return [method isEqualToString:@"POST"] || [method isEqualToString:@"GET"];
}


- (NSDictionary *) JSONResponseForMethod:(NSString *) method URI:(NSString *) path data:(NSDictionary *) data {
  NSObject <UIApplicationDelegate> *delegate = [UIApplication sharedApplication].delegate;

  NSString *key = [data valueForKey:@"key"];

  @try {
    id curVal = [delegate valueForKeyPath:key];
    if ([method isEqualToString:@"POST"]) {
      id val = [data valueForKey:@"value"];
      id kval = val;
      if ([val isKindOfClass:[NSNull class]]) {
        kval = nil;
      }
      NSError *kerror;
      if (!([delegate validateValue:&kval forKeyPath:key error:&kerror])) {
        return [NSDictionary dictionaryWithObjectsAndKeys:@"FAILURE", @"outcome",
                                                          @"value is invalid", @"reason",
                                                          [kerror description], @"description",
                                                          nil];
      }
      [delegate setValue:kval forKeyPath:key];

      return [NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObjects:val,
                                                                                  curVal,
                                                                                  nil], @"results",
                                                        @"SUCCESS", @"outcome",
                                                        nil];
    } else {
      return [NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObjects:curVal,
                                                                                  nil], @"results",
                                                        @"SUCCESS", @"outcome",
                                                        nil];
    }
  }
  @catch (NSException *exception) {
    return [NSDictionary dictionaryWithObjectsAndKeys:@"FAILURE", @"outcome",
                                                      [exception reason], @"reason",
                                                      @"", @"description", nil];
  }
}

@end
