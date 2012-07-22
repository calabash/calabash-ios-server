//
//  LPBackdoorRoute.m
//  calabash
//
//  Created by Karl Krukow on 08/04/12.
//  Copyright (c) 2012 LessPainful. All rights reserved.
//

#import "LPBackdoorRoute.h"

@implementation LPBackdoorRoute

- (BOOL)supportsMethod:(NSString *)method atPath:(NSString *)path {
    return [method isEqualToString:@"POST"];
}
- (NSDictionary *)JSONResponseForMethod:(NSString *)method URI:(NSString *)path data:(NSDictionary*)data 
{
    NSString *selStr = [data objectForKey:@"selector"];
    SEL sel = NSSelectorFromString(selStr);
    id arg = [data objectForKey:@"arg"];
    NSString* res = [[[UIApplication sharedApplication] delegate] performSelector:sel withObject:arg];
    if (!res) { res = @""; }
    return [NSDictionary dictionaryWithObjectsAndKeys:
                res , @"result",
                @"SUCCESS",@"outcome",
                nil];        
}

@end
