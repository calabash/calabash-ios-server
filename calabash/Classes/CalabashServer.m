//
//  CalabashServer.m
//
//  Created by Karl Krukow on 11/08/11.
//  Copyright 2011 LessPainful. All rights reserved.
//

#import "CalabashServer.h"
#import "LPHTTPServer.h"
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
#import "LPIntrospectionRoute.h"
#import "LPConditionRoute.h"
#import "LPUIARouteOverUserPrefs.h"
#import "LPUIARouteOverSharedElement.h"
#import "LPUIATapRoute.h"
#import "LPUIATapRouteOverSharedElement.h"
#import "LPKeyboardRoute.h"
#import "LPLocationRoute.h"
#import "LPDebugRoute.h"
#import "LPDumpRoute.h"
#import "LPKeyboardLanguageRoute.h"
#import <dlfcn.h>
#import "LPInfoPlist.h"
#import "LPPluginLoader.h"
#import "LPWKWebViewRuntimeLoader.h"
#import "LPCocoaLumberjack.h"
#import "LPTTYLogFormatter.h"
#import "LPASLLogFormatter.h"
#import "LPProcessInfoRoute.h"
#import "LPDevice.h"
#import "LPShakeRoute.h"
#import "LPSuspendAppRoute.h"
#import "LPReflectionRoute.h"

@interface CalabashServer ()
- (void) start;
@end

@implementation CalabashServer


+ (void) start {
  CalabashServer *server = [[CalabashServer alloc] init];
  [server start];


  NSString *automationLibPath =
  @"/Developer/Library/PrivateFrameworks/UIAutomation.framework/UIAutomation";

  NSURL *url = [NSURL fileURLWithPath:automationLibPath];

  const char *cFileSystemRep;
  if ([url respondsToSelector:@selector(fileSystemRepresentation)]) {
    // iOS > 6
    cFileSystemRep = [url fileSystemRepresentation];
  } else {
    NSString *absolutePath = [url path];
    cFileSystemRep = [absolutePath cStringUsingEncoding:NSUTF8StringEncoding];
  }

  char *error;
  dlopen(cFileSystemRep, RTLD_LOCAL);
  error = dlerror();

  if (error) {
    LPLogWarn(@"Could not load private UIAutomation.framework.");
    LPLogWarn(@"%@", [NSString stringWithUTF8String:error]);
  }

  LPPluginLoader *loader = [LPPluginLoader new];
  [loader loadCalabashPlugins];
  [loader release];

  [[LPWKWebViewRuntimeLoader shared] loadImplementation];
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

    LPKeyboardLanguageRoute *keyboard_language = [LPKeyboardLanguageRoute new];
    [LPRouter addRoute:keyboard_language forPath:@"keyboard-language"];
    [keyboard_language release];

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

    LPIntrospectionRoute *introspectionRoute = [LPIntrospectionRoute new];
    [LPRouter addRoute:introspectionRoute forPath:@"introspection"];
    [introspectionRoute release];

    LPProcessInfoRoute *processInfoRoute = [LPProcessInfoRoute new];
    [LPRouter addRoute:processInfoRoute forPath:@"process-info"];
    [processInfoRoute release];

    LPShakeRoute *shakeAppRoute = [LPShakeRoute new];
    [LPRouter addRoute:shakeAppRoute forPath:@"shake"];
    [shakeAppRoute release];

    LPSuspendAppRoute *suspendAppRoute = [LPSuspendAppRoute new];
    [LPRouter addRoute:suspendAppRoute forPath:@"suspend"];
    [suspendAppRoute release];

    LPReflectionRoute *reflectionRoute = [LPReflectionRoute new];
    [LPRouter addRoute:reflectionRoute forPath:@"reflection"];
    [reflectionRoute release];

    _httpServer = [[[LPHTTPServer alloc] init] retain];

    NSString *uuid = [[NSProcessInfo processInfo] globallyUniqueString];
    NSString *token = [uuid componentsSeparatedByString:@"-"][0];
    NSString *serverName = [NSString stringWithFormat:@"CalabashServer-%@", token];
    [_httpServer setName:serverName];

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

    LPTTYLogFormatter *TTYLogFormatter = [LPTTYLogFormatter new];
    [[LPTTYLogger sharedInstance] setLogFormatter:TTYLogFormatter];
    [LPLog addLogger:[LPTTYLogger sharedInstance]];
    [TTYLogFormatter release];


    LPASLLogFormatter *ASLLogFormatter = [LPASLLogFormatter new];
    [[LPASLLogger sharedInstance] setLogFormatter:ASLLogFormatter];
    [LPLog addLogger:[LPASLLogger sharedInstance]];
    [ASLLogFormatter release];

    LPLogDebug(@"Creating the server: %@", _httpServer);
    LPLogDebug(@"Calabash iOS server version: %@", kLPCALABASHVERSION);

    NSString *dtSdkName = [infoPlist stringForDTSDKName];
    LPLogDebug(@"App Base SDK: %@", dtSdkName);

    [infoPlist release];
  }
  return self;
}


- (void) start {

  [self enableAccessibility];

  NSError *error = nil;
  if (![_httpServer start:&error]) {
    LPLogError(@"Error starting Calabash HTTP Server: %@", error);
  } else {
    LPLogDebug(@"Calabash iOS server is listening on: %@ port %@",
               [[LPDevice sharedDevice] getIPAddress],
               @([_httpServer port]));
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
  LPLogDebug(@"IPHONE_SIMULATOR_ROOT: %@", simulatorRoot);
  if (simulatorRoot) {
    appSupportPath = [simulatorRoot stringByAppendingString:appSupportPath];
  }

  void *appSupport = dlopen([appSupportPath fileSystemRepresentation], RTLD_LAZY);
  if (!appSupport) {
    LPLogError(@"Unable to dlopen AppSupport. Cannot automatically enable accessibility.");
    return;
  }

  CFStringRef (*copySharedResourcesPreferencesDomainForDomain)(
                                                               CFStringRef domain) = dlsym(appSupport,
                                                                                           "CPCopySharedResourcesPreferencesDomainForDomain");
  if (!copySharedResourcesPreferencesDomainForDomain) {
    LPLogError(@"Unable to dlsym CPCopySharedResourcesPreferencesDomainForDomain. Cannot automatically enable accessibility.");
    return;
  }

  CFStringRef accessibilityDomain = copySharedResourcesPreferencesDomainForDomain(CFSTR("com.apple.Accessibility"));
  if (!accessibilityDomain) {
    LPLogError(@"Unable to cop accessibility preferences. Cannot automatically enable accessibility.");
    return;
  }

  CFPreferencesSetValue(CFSTR("ApplicationAccessibilityEnabled"),
                        kCFBooleanTrue,
                        accessibilityDomain,
                        kCFPreferencesAnyUser,
                        kCFPreferencesAnyHost);
  CFRelease(accessibilityDomain);

  [autoreleasePool drain];
}

- (void) dealloc {
  [_httpServer release];
  [super dealloc];
}

@end

