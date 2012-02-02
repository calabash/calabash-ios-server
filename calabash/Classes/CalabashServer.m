//
//  CalabashServer.m
//
//  Created by Karl Krukow on 11/08/11.
//  Copyright 2011 LessPainful. All rights reserved.
//

#import "CalabashServer.h"
#import "HTTPServer.h"
#import "DDLog.h"
#import "DDTTYLogger.h"
#import "LPRouter.h"
#import "LPScreenshotRoute.h"
#import "LPMapRoute.h"
#import "LPRecordRoute.h"
#import "LPPlaybackRoute.h"
#import "LPAsyncPlaybackRoute.h"
#import "LPBackgroundRoute.h"
//#import "LPScreencastRoute.h"
static const int ddLogLevel = LOG_LEVEL_INFO;

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
		[DDLog addLogger:[DDTTYLogger sharedInstance]];
        LPMapRoute* mr = [LPMapRoute new];
        [LPRouter addRoute:mr forPath:@"/map"];
        [mr release];
        LPScreenshotRoute *sr =[LPScreenshotRoute new];
        [LPRouter addRoute:sr forPath:@"/screenshot"];
        [sr release];

        LPRecordRoute *rr =[LPRecordRoute new];
        [LPRouter addRoute:rr forPath:@"/record"];
        [rr release];

//        LPPlaybackRoute *pr =[LPPlaybackRoute new];
//        [LPRouter addRoute:pr forPath:@"/play"];
//        [pr release];
//        
        LPAsyncPlaybackRoute *apr =[LPAsyncPlaybackRoute new];
        [LPRouter addRoute:apr forPath:@"/play"];
        [apr release];

        LPBackgroundRoute *bgr =[LPBackgroundRoute new];
        [LPRouter addRoute:bgr forPath:@"/background"];
        [bgr release];

//        
//        LPScreencastRoute *scr = [LPScreencastRoute new];
//        [LPRouter addRoute:scr forPath:@"/screencast"];
//        [scr release];
//        

		_httpServer = [[[HTTPServer alloc]init] retain];
		
		[_httpServer setName:@"Calabash Server"];
		[_httpServer setType:@"_http._tcp."];
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
    NSError *error=nil;
	if( ![_httpServer start:&error] ) {
		DDLogError(@"Error starting HTTP Server: %@",error);// %@", error);
	}
}

- (void) dealloc
{
	[_httpServer release];
	[super dealloc];
}


@end
