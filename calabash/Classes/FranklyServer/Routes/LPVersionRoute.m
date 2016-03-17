#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

//
//  LPVersionRoute.m
//  calabash
//
//  Created by Karl Krukow on 22/06/12.
//  Copyright (c) 2012 LessPainful. All rights reserved.
//

#import "LPVersionRoute.h"
#import "LPTouchUtils.h"
#import "LPHTTPDataResponse.h"
#import "LPJSONUtils.h"
#import "LPDevice.h"
#import <sys/utsname.h>
#import "LPInfoPlist.h"

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

#ifdef LP_GIT_REMOTE_ORIGIN
static NSString *const kLPGitRemoteOrigin = LP_GIT_REMOTE_ORIGIN;
#else
static NSString *const kLPGitRemoteOrigin = @"Unknown";
#endif

@interface LPVersionRoute ()

- (BOOL) isIPhoneAppEmulatedOnIPad;

@end

@implementation LPVersionRoute

- (BOOL) isIPhoneAppEmulatedOnIPad {
  UIUserInterfaceIdiom idiom = UI_USER_INTERFACE_IDIOM();
  NSString *model = [[UIDevice currentDevice] model];
  return idiom == UIUserInterfaceIdiomPhone && [model hasPrefix:@"iPad"];
}

- (BOOL) supportsMethod:(NSString *) method atPath:(NSString *) path {
  return [method isEqualToString:@"GET"];
}

// Frank support
- (BOOL)canHandlePostForPath:(NSArray *)path {
  return [@"version" isEqualToString:[path lastObject]];
}

// Frank support
- (id)handleRequestForPath:(NSArray *)path withConnection:(id)connection {
  if (![self canHandlePostForPath:path]) {  return nil;  }

  NSDictionary *version = [self JSONResponseForMethod:@"GET"
                                                  URI:@"version"
                                                 data:nil];
  NSData *jsonData = [[LPJSONUtils serializeDictionary:version]
                      dataUsingEncoding:NSUTF8StringEncoding];
  
  return [[LPHTTPDataResponse alloc] initWithData:jsonData];
}

- (NSDictionary *) JSONResponseForMethod:(NSString *) method
                                     URI:(NSString *) path
                                    data:(NSDictionary *) data {

  LPDevice *device = [LPDevice sharedDevice];
  NSString *modelIdentifier = [device modelIdentifier];
  if (!modelIdentifier) { modelIdentifier = @""; }

  NSString *formFactor = [device formFactor];
  if (!formFactor) { formFactor = @""; }

  BOOL is4inDevice = [device isIPhone5Like];
  BOOL isIphoneAppEmulated = [self isIPhoneAppEmulatedOnIPad];

  NSString *deviceFamily = [device deviceFamily];
  if (!deviceFamily) { deviceFamily = @""; }

  NSString *simulatorInfo = [device simulatorVersionInfo];
  if (!simulatorInfo) { simulatorInfo = @""; }

  NSString *deviceName = [device name];
  if (!deviceName) { deviceName = @""; }

  NSString *iOSVersion = [device iOSVersion];
  if (!iOSVersion) { iOSVersion = @""; }

  NSString *LEGACY_iphoneSimulatorDevice = [device LEGACY_iPhoneSimulatorDevice];
  if (!LEGACY_iphoneSimulatorDevice) { LEGACY_iphoneSimulatorDevice = @""; }

  NSDictionary *git =
  @{
    @"revision" : kLPGitShortRevision,
    @"branch" : kLPGitBranch,
    @"remote_origin" : kLPGitRemoteOrigin
    };

  NSArray *versionTokens = [kLPCALABASHVERSION componentsSeparatedByString:@" "];
  NSString *calabashVersion = [versionTokens lastObject];
  if (!calabashVersion) { calabashVersion = @""; }

  LPInfoPlist *infoPlist = [LPInfoPlist new];

  return

  @{

    @"4inch": @(is4inDevice),
    @"app_base_sdk" : [infoPlist stringForDTSDKName],
    @"app_id" : [infoPlist stringForIdentifier],
    @"app_name" : [infoPlist stringForDisplayName],
    @"app_version": [infoPlist stringForVersion],
    @"device_family" : deviceFamily,
    @"device_name" : deviceName,
    @"form_factor" : formFactor,
    @"git" : git,
    @"iOS_version" : iOSVersion, // deprecated 0.16.2 replaced with ios_version
    @"ios_version" : iOSVersion,
    @"iphone_app_emulated_on_ipad" : @(isIphoneAppEmulated),
    @"model_identifier" : modelIdentifier,
    @"device_name" : deviceName,
    @"outcome" : @"SUCCESS",
    @"screen_dimensions" : [[LPDevice sharedDevice] screenDimensions],
    @"server_port" : @([infoPlist serverPort]),
    @"short_version_string" : [infoPlist stringForShortVersion],
    @"simulator" : simulatorInfo,
    @"simulator_device" : LEGACY_iphoneSimulatorDevice, // deprecate 0.16.2 replaced with device_family
    @"system" : [device LEGACY_systemFromUname],        // deprecated 0.16.2, replaced with model identifer
    @"version" : calabashVersion

    };
}


@end
