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
#import "LPVersionRoute.h"
#import <dlfcn.h>

@interface CalabashServer()
- (void) start;
@end

@implementation CalabashServer

@synthesize httpServer;


+ (void) start {
    CalabashServer* server = [[CalabashServer alloc] init];
    [server start];
    @autoreleasepool {
        NSString *appSupportLocation = @"/System/Library/PrivateFrameworks/AppSupport.framework/AppSupport";
        
        NSDictionary *environment = [[NSProcessInfo processInfo] environment];
        NSString *simulatorRoot = [environment objectForKey:@"IPHONE_SIMULATOR_ROOT"];
        if (simulatorRoot) {
            appSupportLocation = [simulatorRoot stringByAppendingString:appSupportLocation];
        }
        
        void *appSupportLibrary = dlopen([appSupportLocation fileSystemRepresentation], RTLD_LAZY);
        
        CFStringRef (*copySharedResourcesPreferencesDomainForDomain)(CFStringRef domain) = dlsym(appSupportLibrary, "CPCopySharedResourcesPreferencesDomainForDomain");    
        
        if (copySharedResourcesPreferencesDomainForDomain) {
            CFStringRef accessibilityDomain = copySharedResourcesPreferencesDomainForDomain(CFSTR("com.apple.Accessibility"));
            
            if (accessibilityDomain) {
                CFPreferencesSetValue(CFSTR("ApplicationAccessibilityEnabled"), kCFBooleanTrue, accessibilityDomain, kCFPreferencesAnyUser, kCFPreferencesAnyHost);
                CFRelease(accessibilityDomain);
            }
        }
    
    }

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

        LPVersionRoute* verr = [LPVersionRoute new];
        [LPRouter addRoute:verr forPath:@"/version"];


//        
//        LPScreencastRoute *scr = [LPScreencastRoute new];
//        [LPRouter addRoute:scr forPath:@"/screencast"];
//        [scr release];
//        
        self.httpServer = [[LPHTTPServer alloc]init];
		
		[self.httpServer setName:@"Calabash Server"];
		[self.httpServer setType:@"_http._tcp."];

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
			[capabilities setObject:[[UIDevice currentDevice] uniqueIdentifier] forKey:@"uuid"];
		}

		[self.httpServer setTXTRecordDictionary:capabilities];
		[self.httpServer setConnectionClass:[LPRouter class]];
		[self.httpServer setPort:37265];
        // Serve files from our embedded Web folder
        //NSString *webPath = [[NSBundle mainBundle] resourcePath];
        //[self.httpServer setDocumentRoot:webPath];
		NSLog( @"Creating the server: %@", self.httpServer );
	}
	return self;
}

- (void) start {
    
  
    // we need to create a retain cycle so the server will stay alive
    __strong static id _sharedObject = nil;
    static dispatch_once_t pred = 0;
    
    dispatch_once(&pred, ^{
        _sharedObject = self;
    });
    
    [self enableAccessibility];
    NSError *error=nil;
	if( ![self.httpServer start:&error] ) {
		NSLog(@"Error starting LPHTTP Server: %@",error);
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
