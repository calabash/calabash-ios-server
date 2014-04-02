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

- (NSDictionary *) JSONResponseForMethod:(NSString *) method URI:(NSString *) path data:(NSDictionary *) data {
  NSString *versionString = [[NSBundle mainBundle]
                             objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
  if (!versionString) {
    versionString = @"Unknown";
  }
  NSString *idString = [[NSBundle mainBundle]
                        objectForInfoDictionaryKey:@"CFBundleIdentifier"];

  if (!idString) { idString = @"Unknown";  }

  NSString *nameString = [[NSBundle mainBundle]
                          objectForInfoDictionaryKey:@"CFBundleDisplayName"];

  if (!nameString) { nameString = @"Unknown";  }

  struct utsname systemInfo;
  uname(&systemInfo);

  NSString *machine = @(systemInfo.machine);

  NSDictionary *env = [[NSProcessInfo processInfo] environment];

  BOOL iphone5Like = [LPTouchUtils is4InchDevice];

  NSString *dev = env[@"IPHONE_SIMULATOR_DEVICE"];
  if (!dev) {  dev = @"";  }

  NSString *sim = env[@"IPHONE_SIMULATOR_VERSIONS"];
  if (!sim) {  sim = @"";  }

  BOOL isIphoneAppEmulated = [self isIPhoneAppEmulatedOnIPad];
  NSDictionary *git = @{@"revision" : kLPGitShortRevision, @"branch" : kLPGitBranch, @"remote_origin" : kLPGitRemoteOrigin};


  NSString *calabashVersion = [kLPCALABASHVERSION componentsSeparatedByString:@" "].lastObject;

  NSDictionary *res = @{@"version": calabashVersion,
                        @"app_id": idString,
                        @"iOS_version": [[UIDevice currentDevice]
                                         systemVersion],
                        @"app_name": nameString,
                        @"system": machine,
                        @"4inch": @(iphone5Like),
                        @"simulator_device": dev,
                        @"simulator": sim,
                        @"app_version": versionString,
                        @"outcome": @"SUCCESS",
                        @"iphone_app_emulated_on_ipad": @(isIphoneAppEmulated),
                        @"git": git};
  return res;
}


@end
