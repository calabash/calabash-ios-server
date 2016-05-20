#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

//
//  LPCORSResponse.m
//  LPSimpleExample
//
//  Created by Karl Krukow on 3/3/14.
//  Copyright (c) 2014 Xamarin. All rights reserved.
//

#import "LPCORSResponse.h"

@implementation LPCORSResponse

/**
 * If you want to add any extra LPHTTP headers to the response,
 * simply return them in a dictionary in this method.
 **/
- (NSDictionary *)httpHeaders {
    static NSDictionary *sharedHeaders = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      sharedHeaders =
      @{
        @"Access-Control-Allow-Methods" : @"GET, POST, PUT, DELETE, OPTIONS",
        @"Access-Control-Allow-Origin" : @"*",
        @"Access-Control-Allow-Credentials" : @"true",
        @"Access-Control-Max-Age" : @"3000",
        @"Content-Type" : @"application/json; charset=utf-8"
        };
    });
    return sharedHeaders;
}

@end
