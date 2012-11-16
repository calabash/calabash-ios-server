//
//  LPUserPrefRoute.m
//  calabash
//
//  Created by Karl Krukow on 02/02/12.
//  Copyright (c) 2012 LessPainful. All rights reserved.
//

#import "LPUserPrefCommand.h"
#import "LPJSONUtils.h"
#import "FranklyProtocolHelper.h"
#import "JSON.h"

@implementation LPUserPrefCommand

- (NSString *)handleCommandWithRequestBody:(NSString *)requestBody
{
    NSDictionary *data = FROM_JSON(requestBody);
    
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud synchronize];
    
    NSString *key = [data valueForKey:@"key"];
    id curVal = [ud valueForKey:key];
    id val = [data valueForKey:@"value"];
    if (val)
    {
        if ([val isKindOfClass:[NSNull class]])
        {
            [ud removeObjectForKey:key];
        }
        else
        {
            [ud setValue:val forKey:key];
        }
        
        
        [ud synchronize];
        
        return [FranklyProtocolHelper generateSuccessResponseWithResults: [NSArray arrayWithObjects:val,curVal, nil]];
        
    }
    return [FranklyProtocolHelper generateSuccessResponseWithResults: [NSArray arrayWithObjects:curVal, nil]];
    
}
@end
