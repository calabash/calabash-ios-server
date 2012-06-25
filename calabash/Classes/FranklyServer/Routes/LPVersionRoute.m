//
//  LPVersionRoute.m
//  calabash
//
//  Created by Karl Krukow on 22/06/12.
//  Copyright (c) 2012 Trifork. All rights reserved.
//

#import "LPVersionRoute.h"

#define kLPCALABASHVERSION @"0.9.71"

@implementation LPVersionRoute

- (BOOL)supportsMethod:(NSString *)method atPath:(NSString *)path 
{
    return [method isEqualToString:@"GET"];
}

- (NSDictionary *)JSONResponseForMethod:(NSString *)method URI:(NSString *)path data:(NSDictionary*)data {    
    return [NSDictionary dictionaryWithObjectsAndKeys:
                kLPCALABASHVERSION , @"version",
                @"SUCCESS",@"outcome",
                //device, os, serial?, other?
                nil];
    
}


@end
