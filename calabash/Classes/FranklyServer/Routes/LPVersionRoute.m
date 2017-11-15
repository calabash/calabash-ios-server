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
#import "LPGitVersionDefines.h"

// See the LPGitVersionDefines.h
//
// The contents are updated before compile time with the following defines:
//
// #define LP_GIT_SHORT_REVISION <rev>
// #define LP_GIT_BRANCH <branch>
// #define LP_GIT_REMOTE_ORIGIN <origin>
// #define LP_SERVER_BUILD_DATE <date in seconds>
//
// # This is one of two values:
// # 1. If the local git repo is clean, then this value is the commit SHA
// # 2. If the local git repo is not clean, it is the shasum of a .tar of
// #    the calabash/ calabash.xcodeproj/project.pbxproj bin/ sources.
// #define LP_SERVER_ID_KEY_VALUE @"LPSERVERID=<sha>
//
// After compilation, the contents of this file are reset using:
//
// git co -- calabash/LPGitVersionDefines.h
//
// To see how this file is managed, navigate to the calabash target and look at:
//
// 1. Run Script - git versioning 1 of 2
// 2. Run Script - git versioning 2 of 2
//
// and these scripts:
//
// 3. bin/xcode-build-phase/gitversioning-before.sh
// 4. bin/xcode-build-phase/gitversioning-after.sh

#ifdef LP_GIT_SHORT_REVISION
static NSString *const kLPGitShortRevision = LP_GIT_SHORT_REVISION;
#else
static NSString *const kLPGitShortRevision = @"Unknown LP_GIT_SHORT_REVISION";
#endif

#ifdef LP_GIT_BRANCH
static NSString *const kLPGitBranch = LP_GIT_BRANCH;
#else
static NSString *const kLPGitBranch = @"Unknown LP_GIT_BRANCH";
#endif

#ifdef LP_GIT_REMOTE_ORIGIN
static NSString *const kLPGitRemoteOrigin = LP_GIT_REMOTE_ORIGIN;
#else
static NSString *const kLPGitRemoteOrigin = @"Unknown LP_GIT_REMOTE_ORIGIN";
#endif

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
    @"ios_version" : iOSVersion,
    @"iphone_app_emulated_on_ipad" : @(isIphoneAppEmulated),
    @"model_identifier" : modelIdentifier,
    @"device_name" : deviceName,
    @"outcome" : @"SUCCESS",
    @"screen_dimensions" : [[LPDevice sharedDevice] screenDimensions],
    @"server_port" : @([infoPlist serverPort]),
    @"short_version_string" : [infoPlist stringForShortVersion],
    @"simulator" : simulatorInfo,
    @"version" : calabashVersion

    };
}

@end
