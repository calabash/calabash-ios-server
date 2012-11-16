//
//  LPVersionRoute.m
//  calabash
//
//  Created by Karl Krukow on 22/06/12.
//  Copyright (c) 2012 LessPainful. All rights reserved.
//

#import "LPVersionCommand.h"
#import "JSON.h"
#import <sys/utsname.h>

#define kLPCALABASHVERSION @"0.9.200"

@implementation LPVersionCommand


- (NSString *)handleCommandWithRequestBody:(NSString *)requestBody
{
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
    return TO_JSON(res);
    
    
}

@end
