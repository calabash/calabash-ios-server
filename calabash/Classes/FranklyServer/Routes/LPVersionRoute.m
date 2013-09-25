//
//  LPVersionRoute.m
//  calabash
//
//  Created by Karl Krukow on 22/06/12.
//  Copyright (c) 2012 LessPainful. All rights reserved.
//

#import "LPVersionRoute.h"
#import "LPTouchUtils.h"
#import <sys/utsname.h>
@class UIDevice;


/*** UNEXPECTED ***
 adds git version and branch information to the server_version route
 
 helps developers know exactly which server framework is installed in an ipa
 
 the two defines:
 
 #define LP_GIT_SHORT_REVISION <rev>  // ex. @"4fdb203"
 #define LP_GIT_BRANCH <branch>       // ex. @"0.9.x"
 
 are generated before compilation and erased after to avoid git conflicts in
 LPGitVersionDefines.h
 
 to see how LPGitVersionDefines.h is managed see:
 
 1. Run Script - git versioning 1 of 2
 2. Run Script - git versioning 2 of 2
 
 ******************/
#import "LPGitVersionDefines.h"

#ifdef LP_GIT_SHORT_REVISION
static NSString *const kLPGitShortRevision = LP_GIT_SHORT_REVISION;
#else
static NSString *const kLPGitShortRevision = @"Unknown";
#endif

#ifdef LP_GIT_BRANCH
static NSString *const kLPGitBranch = LP_GIT_BRANCH;
#else
static NSString *const kLPGitBranch = @"Unknown";
#endif

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
    

    NSDictionary *env = [[NSProcessInfo processInfo]environment];

    BOOL iphone5Like = [LPTouchUtils is4InchDevice];

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
                         kLPGitShortRevision, @"git revision",
                         kLPGitBranch, @"git branch",
                         nil];
    return res;
    
}


@end
