//
//  LPVersionRoute.m
//  calabash
//
//  Created by Karl Krukow on 22/06/12.
//  Copyright (c) 2012 Xamarin. All rights reserved.
//

#import "LPVersionCommand.h"
#import "JSON.h"
#import <sys/utsname.h>

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
    
    NSString *system = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    
    UIDevice *device = [UIDevice currentDevice];
    NSDictionary *env = [[NSProcessInfo processInfo]environment];

    BOOL iphone5Like = NO;
    if([@"iPhone Simulator" isEqualToString: [device model]])
    {
        
        NSPredicate *inch5PhonePred = [NSPredicate predicateWithFormat:@"IPHONE_SIMULATOR_VERSIONS LIKE '*iPhone (Retina 4-inch)*'"];
        iphone5Like = [inch5PhonePred evaluateWithObject:env];
    }
    else if ([[device model] hasPrefix:@"iPhone"])
    {
        iphone5Like = [system hasPrefix:@"iPhone5"];
    }
    else if ([[device model] hasPrefix:@"iPod"])
    {
        iphone5Like = [system hasPrefix:@"iPod5"];
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
                         [[UIDevice currentDevice] systemVersion], @"iOS_version",
                         nameString,@"app_name",
                         system, @"system",
                         [NSNumber numberWithBool:iphone5Like], @"4inch",
                         dev, @"simulator_device",
                         sim, @"simulator",
                         versionString,@"app_version",
                         @"SUCCESS",@"outcome",
                         //device, os, serial?, other?
                         nil];
    return TO_JSON(res);
    
}

@end
