//
//  LPVersionRoute.m
//  calabash
//
//  Created by Karl Krukow on 22/06/12.
//  Copyright (c) 2012 LessPainful. All rights reserved.
//

#import "LPVersionRoute.h"
#import <sys/utsname.h>

#define kLPCALABASHVERSION @"0.9.123"

@implementation LPVersionRoute

- (BOOL)supportsMethod:(NSString *)method atPath:(NSString *)path 
{
    return [method isEqualToString:@"GET"];
}

- (NSDictionary *)JSONResponseForMethod:(NSString *)method URI:(NSString *)path data:(NSDictionary*)data {    
    NSString *versionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];//
    if (!versionString)
    {
        versionString = @"Unknown";
    }
    NSString *idString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];//
    if (!idString)
    {
        idString = @"Unknown";
    }
    NSString *nameString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];//
    if (!nameString)
    {
        nameString = @"Unknown";
    }
    struct utsname systemInfo;
    uname(&systemInfo);
    
    NSDictionary* res = [NSDictionary dictionaryWithObjectsAndKeys:
                         kLPCALABASHVERSION , @"version",
                         idString,@"app_id",
                         [UIDevice currentDevice].systemVersion, @"iOS_version",
                         nameString,@"app_name",
                         [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding], @"system",
                         versionString,@"app_version",
                         @"SUCCESS",@"outcome",
                         //device, os, serial?, other?
                         nil];
    return res;
    
}


@end
