//
//  CalabashServer.m
//
//  Created by Karl Krukow on 11/08/11.
//  Copyright 2011 LessPainful. All rights reserved.
//

#import "CalabashLoader.h"
#import "RequestRouter.h"
#import "LPHTTPServer.h"
#import "LPRouter.h"
#import "LPScreenshotRoute.h"
#import "LPMapRoute.h"
#import "LPRecordRoute.h"
#import "LPPlaybackRoute.h"
#import "LPAsyncPlaybackRoute.h"
#import "LPUserPrefRoute.h"
#import "LPInterpolateRoute.h"
#import "LPBackdoorRoute.h"
#import "CalabashUISpecSelectorEngine.h"
#import "LPVersionRoute.h"
#import "LPConditionRoute.h"
#import "LPUIARoute.h"
#import "LPKeyboardRoute.h"
#import <dlfcn.h>


@interface SelectorEngineRegistry
+(void)registerSelectorEngine:(id <SelectorEngine>)engine WithName:(NSString *)name;
@end


@implementation CalabashLoader


+ (void)applicationDidBecomeActive:(NSNotification *)notification {
    [SelectorEngineRegistry registerSelectorEngine:[[CalabashUISpecSelectorEngine alloc] init] WithName:@"calabash_uispec"];
    NSLog(@"Calabash 0.9.200 registered with Frank as selector engine named 'calabash_uispec'");
    LPAsyncPlaybackRoute *apr =[LPAsyncPlaybackRoute new];
    
    [[RequestRouter singleton] registerRoute:apr];
    [apr release];
    
    
    
}

+ (void)load {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidBecomeActive:)
                                                 name:@"UIApplicationDidBecomeActiveNotification"
                                               object:nil];
    dlopen([@"/Developer/Library/PrivateFrameworks/UIAutomation.framework/UIAutomation" fileSystemRepresentation], RTLD_LOCAL);
}


/*
- (id) init
{
	self = [super init];    
	if (self != nil) {
		
        LPMapRoute* mr = [LPMapRoute new];
        [LPRouter addRoute:mr forPath:@"map"];
        [mr release];
        LPScreenshotRoute *sr =[LPScreenshotRoute new];
        [LPRouter addRoute:sr forPath:@"screenshot"];
        [sr release];

        LPRecordRoute *rr =[LPRecordRoute new];
        [LPRouter addRoute:rr forPath:@"record"];
        [rr release];

//        LPPlaybackRoute *pr =[LPPlaybackRoute new];
//        [LPRouter addRoute:pr forPath:@"/play"];
//        [pr release];
//        
        LPAsyncPlaybackRoute *apr =[LPAsyncPlaybackRoute new];
        [LPRouter addRoute:apr forPath:@"play"];
        [apr release];

        LPUserPrefRoute *bgr =[LPUserPrefRoute new];
        [LPRouter addRoute:bgr forPath:@"userprefs"];
        [bgr release];

        LPInterpolateRoute *panr =[LPInterpolateRoute new];
        [LPRouter addRoute:panr forPath:@"interpolate"];
        [panr release];
        
        LPBackdoorRoute* backdr = [LPBackdoorRoute new];
        [LPRouter addRoute:backdr forPath:@"backdoor"];
        [backdr release];

        LPVersionRoute* verr = [LPVersionRoute new];
        [LPRouter addRoute:verr forPath:@"version"];
        [verr release];

        LPConditionRoute* cond = [LPConditionRoute new];
        [LPRouter addRoute:cond forPath:@"condition"];
        [cond release];

        LPKeyboardRoute* keyboard = [LPKeyboardRoute new];
        [LPRouter addRoute:keyboard forPath:@"keyboard"];
        [keyboard release];
        
        LPUIARoute* uia = [LPUIARoute new];
        [LPRouter addRoute:uia forPath:@"uia"];
        [uia release];
        
    


//        
//        LPScreencastRoute *scr = [LPScreencastRoute new];
//        [LPRouter addRoute:scr forPath:@"/screencast"];
//        [scr release];
//        

		_httpServer = [[[LPHTTPServer alloc]init] retain];
		
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
			[capabilities setObject:[[UIDevice currentDevice] uniqueIdentifier] forKey:@"uuid"];
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
*/


@end
