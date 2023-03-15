#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif
//
//  LPQueryLogRoute.m
//  calabash
//
//  Created by Jim McBeath on 12/26/12.
//  Copyright (c) 2012 LessPainful.
//

#import "LPQueryLogRoute.h"

@implementation LPQueryLogRoute

- (BOOL) supportsMethod:(NSString *) method atPath:(NSString *) path {
  return [method isEqualToString:@"POST"];
}

- (NSDictionary *) JSONResponseForMethod:(NSString *) method URI:(NSString *) path data:(NSDictionary *) data {
  return
  @{
    @"results" : @"Querying logs are deprecated now.",
    @"outcome" : @"SUCCESS",
    };
}

@end
