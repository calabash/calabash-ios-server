//
//  CalabashServer.m
//
//  Created by Karl Krukow on 11/08/11.
//  Copyright 2011 LessPainful. All rights reserved.
//

#import "CalabashServer.h"
#import "LPRouter.h"
#import "LPScreenshotRoute.h"
#import "LPMapRoute.h"
#import "LPRecordRoute.h"
#import "LPAsyncPlaybackRoute.h"
#import "LPUserPrefRoute.h"
#import "LPKeychainRoute.h"
#import "LPAppPropertyRoute.h"
#import "LPQueryLogRoute.h"
#import "LPInterpolateRoute.h"
#import "LPBackdoorRoute.h"
#import "LPExitRoute.h"
#import "LPVersionRoute.h"
#import "LPConditionRoute.h"
#import "LPUIARouteOverUserPrefs.h"
#import "LPUIARouteOverSharedElement.h"
#import "LPUIATapRoute.h"
#import "LPUIATapRouteOverSharedElement.h"
#import "LPKeyboardRoute.h"
#import "LPLocationRoute.h"
#import "LPDebugRoute.h"
#import "LPDumpRoute.h"
#import <dlfcn.h>
#import "LPInfoPlist.h"
#import "LPPluginLoader.h"

@interface CalabashServer ()
- (void) start;
@end

@implementation CalabashServer


+ (void) start {
  CalabashServer *server = [[CalabashServer alloc] init];
  [server start];

  dlopen([@"/Developer/Library/PrivateFrameworks/UIAutomation.framework/UIAutomation" fileSystemRepresentation], RTLD_LOCAL);

  LPPluginLoader *loader = [LPPluginLoader new];
  [loader loadCalabashPlugins];
  [loader release];
}


- (id) init {
  self = [super init];
  if (self != nil) {

    LPMapRoute *mr = [LPMapRoute new];
    [LPRouter addRoute:mr forPath:@"map"];
    [mr release];
    LPScreenshotRoute *sr = [LPScreenshotRoute new];
    [LPRouter addRoute:sr forPath:@"screenshot"];
    [sr release];

    LPRecordRoute *rr = [LPRecordRoute new];
    [LPRouter addRoute:rr forPath:@"record"];
    [rr release];

    //        LPPlaybackRoute *pr =[LPPlaybackRoute new];
    //        [LPRouter addRoute:pr forPath:@"/play"];
    //        [pr release];
    //
    LPAsyncPlaybackRoute *apr = [LPAsyncPlaybackRoute new];
    [LPRouter addRoute:apr forPath:@"play"];
    [apr release];

    LPUserPrefRoute *bgr = [LPUserPrefRoute new];
    [LPRouter addRoute:bgr forPath:@"userprefs"];
    [bgr release];

    LPKeychainRoute *keyr = [LPKeychainRoute new];
    [LPRouter addRoute:keyr forPath:@"keychain"];
    [keyr release];

    LPAppPropertyRoute *appr = [LPAppPropertyRoute new];
    [LPRouter addRoute:appr forPath:@"appproperty"];
    [appr release];

    LPQueryLogRoute *qlr = [LPQueryLogRoute new];
    [LPRouter addRoute:qlr forPath:@"querylog"];
    [qlr release];

    LPInterpolateRoute *panr = [LPInterpolateRoute new];
    [LPRouter addRoute:panr forPath:@"interpolate"];
    [panr release];

    LPBackdoorRoute *backdr = [LPBackdoorRoute new];
    [LPRouter addRoute:backdr forPath:@"backdoor"];
    [backdr release];

    LPExitRoute *exit_route = [LPExitRoute new];
    [LPRouter addRoute:exit_route forPath:@"exit"];
    [exit_route release];

    LPVersionRoute *verr = [LPVersionRoute new];
    [LPRouter addRoute:verr forPath:@"version"];
    [verr release];

    LPConditionRoute *cond = [LPConditionRoute new];
    [LPRouter addRoute:cond forPath:@"condition"];
    [cond release];

    LPKeyboardRoute *keyboard = [LPKeyboardRoute new];
    [LPRouter addRoute:keyboard forPath:@"keyboard"];
    [keyboard release];

    LPUIARouteOverUserPrefs *uiaUsingUserPrefs = [LPUIARouteOverUserPrefs new];
    [LPRouter addRoute:uiaUsingUserPrefs forPath:@"uia"];
    [uiaUsingUserPrefs release];

    LPUIARouteOverSharedElement *uiaUsingSharedEl = [LPUIARouteOverSharedElement new];
    [LPRouter addRoute:uiaUsingSharedEl forPath:@"uia-shared"];
    [uiaUsingSharedEl release];

    LPUIATapRoute *uiaTap = [LPUIATapRoute new];
    [LPRouter addRoute:uiaTap forPath:@"uia-tap"];
    [uiaTap release];

    LPUIATapOverSharedElementRoute *uiaTapShared = [LPUIATapOverSharedElementRoute new];
    [LPRouter addRoute:uiaTapShared forPath:@"uia-tap-shared"];
    [uiaTapShared release];

    LPLocationRoute *location = [LPLocationRoute new];
    [LPRouter addRoute:location forPath:@"location"];
    [location release];

    LPDebugRoute *debugRoute = [LPDebugRoute new];
    [LPRouter addRoute:debugRoute forPath:@"debug"];
    [debugRoute release];

    LPDumpRoute *dumpRoute = [LPDumpRoute new];
    [LPRouter addRoute:dumpRoute forPath:@"dump"];
    [dumpRoute release];

    _httpServer = [[[LPHTTPServer alloc] init] retain];

    [_httpServer setName:@"Calabash Server"];
    [_httpServer setType:@"_http._tcp."];
    [_httpServer setConnectionClass:[LPRouter class]];

    LPInfoPlist *infoPlist = [LPInfoPlist new];
    [_httpServer setPort:[infoPlist serverPort]];

    // Advertise this device's capabilities to our listeners inside of the TXT record
    UIDevice *device = [UIDevice currentDevice];
    NSDictionary *capabilities =
    @{
      @"name" : [device name],
      @"os_version" : [device systemVersion],
      @"app" : [infoPlist stringForDisplayName],
      @"app_id" : [infoPlist stringForIdentifier],
      @"app_version" : [infoPlist stringForVersion],
      };

    [_httpServer setTXTRecordDictionary:capabilities];

    NSLog(@"Creating the server: %@", _httpServer);
    NSLog(@"Calabash iOS server version: %@", kLPCALABASHVERSION);

    NSString *dtSdkName = [infoPlist stringForDTSDKName];
    NSLog(@"App Base SDK: %@", dtSdkName);

    [infoPlist release];
  }
  return self;
}


- (void) start {

  [self enableAccessibility];

  NSError *error = nil;
  if (![_httpServer start:&error]) {
    NSLog(@"Error starting Calabash LPHTTP Server: %@", error);// %@", error);
  }
}


- (void) enableAccessibility {
  // Approach described at:
  // http://sgleadow.github.com/blog/2011/11/16/enabling-accessibility-programatically-on-ios-devices/
  NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];

  NSString *appSupportPath = @"/System/Library/PrivateFrameworks/AppSupport.framework/AppSupport";

  // If we're on the simulator, make sure we're using the sim's copy of AppSupport
  NSDictionary *environment = [[NSProcessInfo processInfo] environment];
  NSString *simulatorRoot = [environment objectForKey:@"IPHONE_SIMULATOR_ROOT"];
  NSLog(@"simroot: %@", simulatorRoot);
  if (simulatorRoot) {
    appSupportPath = [simulatorRoot stringByAppendingString:appSupportPath];
  }

  void *appSupport = dlopen(
                            [appSupportPath fileSystemRepresentation], RTLD_LAZY);
  if (!appSupport) {
    NSLog(@"ERROR: Unable to dlopen AppSupport. Cannot automatically enable accessibility.");
    return;
  }

  CFStringRef (*copySharedResourcesPreferencesDomainForDomain)(
                                                               CFStringRef domain) = dlsym(appSupport,
                                                                                           "CPCopySharedResourcesPreferencesDomainForDomain");
  if (!copySharedResourcesPreferencesDomainForDomain) {
    NSLog(@"ERROR: Unable to dlsym CPCopySharedResourcesPreferencesDomainForDomain. "
          "Cannot automatically enable accessibility.");
    return;
  }

  CFStringRef accessibilityDomain = copySharedResourcesPreferencesDomainForDomain(CFSTR("com.apple.Accessibility"));
  if (!accessibilityDomain) {
    NSLog(@"ERROR: Unable to cop accessibility preferences. Cannot automatically enable accessibility.");
    return;
  }

  CFPreferencesSetValue(CFSTR("ApplicationAccessibilityEnabled"),
                        kCFBooleanTrue, accessibilityDomain, kCFPreferencesAnyUser,
                        kCFPreferencesAnyHost);
  CFRelease(accessibilityDomain);

  [autoreleasePool drain];
}

- (void) dealloc {
  [_httpServer release];
  [super dealloc];
}


@end
