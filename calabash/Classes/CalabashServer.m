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
#import "LPPlaybackRoute.h"
#import "LPAsyncPlaybackRoute.h"
#import "LPBackgroundRoute.h"
#import "LPInterpolateRoute.h"
#import "LPBackdoorRoute.h"
#import <dlfcn.h>
// category for UUID
#import "UIDevice+IdentifierAddition.h"
#import "NSString+MD5Addition.h"

@interface CalabashServer()
- (void) start;
@end
@implementation CalabashServer


+ (void) start {
    CalabashServer* server = [[CalabashServer alloc] init];
    [server start];
}

- (id) init
{
	self = [super init];    
	if (self != nil) {
		
        LPMapRoute* mr = [LPMapRoute new];
        [LPRouter addRoute:mr forPath:@"/map"];
        LPScreenshotRoute *sr =[LPScreenshotRoute new];
        [LPRouter addRoute:sr forPath:@"/screenshot"];

        LPRecordRoute *rr =[LPRecordRoute new];
        [LPRouter addRoute:rr forPath:@"/record"];

//        LPPlaybackRoute *pr =[LPPlaybackRoute new];
//        [LPRouter addRoute:pr forPath:@"/play"];
//        [pr release];
//        
        LPAsyncPlaybackRoute *apr =[LPAsyncPlaybackRoute new];
        [LPRouter addRoute:apr forPath:@"/play"];

        LPBackgroundRoute *bgr =[LPBackgroundRoute new];
        [LPRouter addRoute:bgr forPath:@"/background"];

        LPInterpolateRoute *panr =[LPInterpolateRoute new];
        [LPRouter addRoute:panr forPath:@"/interpolate"];
        
        LPBackdoorRoute* backdr = [LPBackdoorRoute new];
        [LPRouter addRoute:backdr forPath:@"/backdoor"];
        

//        
//        LPScreencastRoute *scr = [LPScreencastRoute new];
//        [LPRouter addRoute:scr forPath:@"/screencast"];
//        [scr release];
//        

		_httpServer = [[LPHTTPServer alloc]init];
		
		[_httpServer setName:@"Calabash Server"];
		[_httpServer setType:@"_http._tcp."];

		// Advertise this device's capabilities to our listeners inside of the TXT record
		NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
		NSMutableDictionary *capabilities = [[NSMutableDictionary alloc]
		                                     initWithObjectsAndKeys:
		                                     [[UIDevice currentDevice] name], @"name",
		                                     [[UIDevice currentDevice] model], @"model",
		                                     [[UIDevice currentDevice] systemVersion], @"os_version",
		                                     [info objectForKey:@"CFBundleDisplayName"], @"app",
		                                     [info objectForKey:@"CFBundleIdentifier"], @"app_id",
		                                     [info objectForKey:@"CFBundleVersion"], @"app_version",
		                                     nil];
		if ([[UIDevice currentDevice] respondsToSelector:@selector(uniqueIdentifier)]) {
      [capabilities setObject:[[UIDevice currentDevice] uniqueDeviceIdentifier] forKey:@"uuid"];
			//[capabilities setObject:[[UIDevice currentDevice] uniqueIdentifier] forKey:@"uuid"];
		}

		[_httpServer setTXTRecordDictionary:capabilities];
		[_httpServer setConnectionClass:[LPRouter class]];
		[_httpServer setPort:37265];
        // Serve files from our embedded Web folder
//        NSString *webPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Web"];
//        [_httpServer setDocumentRoot:webPath];
		NSLog( @"Creating the server: %@", _httpServer );
	}
	return self;
}

- (void) start {
    [self enableAccessibility];

    NSError *error=nil;
	if( ![_httpServer start:&error] ) {
		NSLog(@"Error starting LPHTTP Server: %@",error);// %@", error);
	}
}

- (void) enableAccessibility
{
    // Approach described at:
    // http://sgleadow.github.com/blog/2011/11/16/enabling-accessibility-programatically-on-ios-devices/
    @autoreleasepool {
        NSString *appSupportPath = @"/System/Library/PrivateFrameworks/AppSupport.framework/AppSupport";

        // If we're on the simulator, make sure we're using the sim's copy of AppSupport
        NSDictionary *environment = [[NSProcessInfo processInfo] environment];
        NSString *simulatorRoot = [environment objectForKey:@"IPHONE_SIMULATOR_ROOT"];
        if (simulatorRoot) {
            appSupportPath = [simulatorRoot stringByAppendingString:appSupportPath];
        }

        void *appSupport = dlopen([appSupportPath fileSystemRepresentation], RTLD_LAZY);
        if (!appSupport) {
            NSLog(@"ERROR: Unable to dlopen AppSupport. Cannot automatically enable accessibility.");
            return;
        }

        CFStringRef (*copySharedResourcesPreferencesDomainForDomain)(CFStringRef domain)
            = dlsym(appSupport, "CPCopySharedResourcesPreferencesDomainForDomain");
        if (!copySharedResourcesPreferencesDomainForDomain) {
            NSLog(@"ERROR: Unable to dlsym CPCopySharedResourcesPreferencesDomainForDomain. "
                   "Cannot automatically enable accessibility.");
            return;
        }

        CFStringRef accessibilityDomain
            = copySharedResourcesPreferencesDomainForDomain(CFSTR("com.apple.Accessibility"));
        if (!accessibilityDomain) {
            NSLog(@"ERROR: Unable to cop accessibility preferences. Cannot automatically enable accessibility.");
            return;
        }

        CFPreferencesSetValue(CFSTR("ApplicationAccessibilityEnabled"),
                              kCFBooleanTrue,
                              accessibilityDomain,
                              kCFPreferencesAnyUser,
                              kCFPreferencesAnyHost);
        CFRelease(accessibilityDomain);
    }
}



@end
