//
//  LPUIARoute.m
//  calabash
//
//  Created by Karl Krukow on 08/04/12.
//  Copyright (c) 2012 LessPainful. All rights reserved.
//

#import "LPUIARoute.h"
#import "UIAutomation.h"

@implementation LPUIARoute

- (BOOL)supportsMethod:(NSString *)method atPath:(NSString *)path {
    return [method isEqualToString:@"POST"];
}
- (NSDictionary *)JSONResponseForMethod:(NSString *)method URI:(NSString *)path data:(NSDictionary*)data 
{
    NSString *action = [data objectForKey:@"action"];
    if ([action isEqualToString:@"change_location"])
    {
        NSNumber *lat = [data objectForKey:@"latitude"];
        if (!lat)
        {
            return [NSDictionary dictionaryWithObjectsAndKeys:
                    @"FAILURE",@"outcome",
                    @"latitude must be specified",@"reason",
                    @"",@"details",
                    nil];
        }
        NSNumber *lon = [data objectForKey:@"longitude"];
        if (!lon)
        {
            return [NSDictionary dictionaryWithObjectsAndKeys:
                    @"FAILURE",@"outcome",
                    @"longitude must be specified",@"reason",
                    @"",@"details",
                    nil];
        }
        
        id tgt = [NSClassFromString(@"UIATarget") localTarget];
        if (tgt && [tgt respondsToSelector:@selector(setLocation:)])
        {
            [tgt setLocation:[NSDictionary dictionaryWithObjectsAndKeys:
                              lat,@"latitude", 
                              lon,@"longitude", 
                              nil]];
            return [NSDictionary dictionaryWithObjectsAndKeys:
                    [NSArray array], @"results",
                    @"SUCCESS",@"outcome",
                    nil];            
        }
        else 
        {
            NSString *message = nil;
            if (!tgt)
            {
               message = @"UIAutomation is not linked for some reason."; 
            }
            else
            {
                message = @"setLocation is unsupported in this iOS version.";
            }
            return [NSDictionary dictionaryWithObjectsAndKeys:
                    @"FAILURE",@"outcome",
                    message,@"reason",
                    @"",@"details",
                    nil];
            
        }
        
    }
    return [NSDictionary dictionaryWithObjectsAndKeys:
            @"FAILURE",@"outcome",
            [NSString stringWithFormat:@"action %@ not recognized",action],@"reason",
            @"",@"details",
            nil];

}

@end
