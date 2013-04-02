//
//  LPVersionRoute.m
//  calabash
//
//  Created by Karl Krukow on 22/06/12.
//  Copyright (c) 2012 LessPainful. All rights reserved.
//

#import "LPVersionRoute.h"
#import <sys/utsname.h>

#define kLPCALABASHVERSION @"0.9.139"

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
    
    NSString *system = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    
    UIDevice *device = [UIDevice currentDevice];
    NSDictionary *env = [[NSProcessInfo processInfo]environment];

    BOOL inch5Phone = NO;
    if([@"iPhone Simulator" isEqualToString: [device model]])
    {
        
        NSPredicate *inch5PhonePred = [NSPredicate predicateWithFormat:@"IPHONE_SIMULATOR_VERSIONS LIKE '*iPhone (Retina 4-inch)*'"];
        inch5Phone = [inch5PhonePred evaluateWithObject:env];
    }
    else if ([[device model] hasPrefix:@"iPhone"])
    {
        inch5Phone = [system isEqualToString:@"iPhone5,2"];
    }

    NSString *dev = [env objectForKey:@"IPHONE_SIMULATOR_DEVICE"];
    if (!dev) {
        dev = @"";
    }
    
    NSString *sim = [env objectForKey:@"IPHONE_SIMULATOR_VERSIONS"];
    if (!sim) {
        sim = @"";
    }
    
    
    NSDictionary* res = [NSDictionary dictionaryWithObjectsAndKeys:
                         kLPCALABASHVERSION , @"version",
                         idString,@"app_id",
                         [UIDevice currentDevice].systemVersion, @"iOS_version",
                         nameString,@"app_name",
                         system, @"system",
                         dev, @"simulator_device",
                         sim, @"simulator",
                         versionString,@"app_version",
                         @"SUCCESS",@"outcome",
                         //device, os, serial?, other?
                         nil];
    return res;
    
}


@end
