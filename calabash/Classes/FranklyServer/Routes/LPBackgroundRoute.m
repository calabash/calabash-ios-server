//
//  LPBackgroundRoute.m
//  calabash
//
//  Created by Karl Krukow on 02/02/12.
//  Copyright (c) 2012 Trifork. All rights reserved.
//

#import "LPBackgroundRoute.h"

@implementation LPBackgroundRoute
- (BOOL)supportsMethod:(NSString *)method atPath:(NSString *)path {
    return [method isEqualToString:@"POST"];
}
- (NSDictionary *)JSONResponseForMethod:(NSString *)method URI:(NSString *)path data:(NSDictionary*)data {
    NSNumber *num = [data valueForKey:@"duration"];
    UIAlertView *alert = 
        [[UIAlertView alloc]
            initWithTitle:[NSString stringWithFormat:@"_Calababash_background_%@", num]
                                                    message:@""
                                                    delegate:nil 
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
    return [NSDictionary dictionaryWithObjectsAndKeys:
            [NSArray array], @"results",
            @"SUCCESS",@"outcome",
            nil];
}
@end
