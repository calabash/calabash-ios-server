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
        sharedHeaders = [[NSDictionary alloc] initWithObjectsAndKeys:
                            @"GET, POST, PUT, DELETE, OPTIONS", @"Access-Control-Allow-Methods",
                            @"*",    @"Access-Control-Allow-Origin",
                            @"true", @"Access-Control-Allow-Credentials",
                            @"3000", @"Access-Control-Max-Age",
                         
                         nil];
    });
    return sharedHeaders;
}

@end
