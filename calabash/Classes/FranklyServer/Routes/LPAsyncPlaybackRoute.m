//
//  LPAsyncPlaybackRoute.m
//  calabash
//
//  Created by Karl Krukow on 29/01/12.
//  Copyright (c) 2012 Trifork. All rights reserved.
//

#import "LPAsyncPlaybackRoute.h"
#import "HTTPResponse.h"
#import "HTTPConnection.h"
#import "LPResources.h"
#import "LPRecorder.h"
#import "UIScriptParser.h"
#import "LPTouchUtils.h"
#import "LPJSONUtils.h"


@implementation LPAsyncPlaybackRoute
@synthesize events=_events;
@synthesize done=_done;
@synthesize conn=_conn;
@synthesize data=_data;
@synthesize jsonResponse=_jsonResponse;


// Returns the length of the data in bytes.
// If you don't know the length in advance, implement the isChunked method and have it return YES.
- (UInt64)contentLength {
    return -1;
}
// The HTTP server supports range requests in order to allow things like
// file download resumption and optimized streaming on mobile devices.
- (UInt64)offset {UInt64 res = 0; return res;};
- (void)setOffset:(UInt64)offset {};

// Important: You should read the discussion at the bottom of this header.
- (BOOL)isChunked {
    return YES;
}
// This method is called from the HTTPConnection class when the connection is closed,
// or when the connection is finished with the response.
// If your response is asynchronous, you should implement this method so you can be sure not to
// invoke HTTPConnection's responseHasAvailableData method after this method is called.
- (void)connectionDidClose {
    self.conn = nil;
}

-(void) playbackEvents {
    self.done = NO;
    NSString *base64Events = [self.data objectForKey:@"events"];
    NSString *query = [self.data objectForKey:@"query"];
    UIView *targetView = nil;
    if (query != nil) {
        UIScriptParser *parser = [[UIScriptParser alloc] initWithUIScript:query];
        [parser parse];
        NSMutableArray* views = [NSMutableArray arrayWithCapacity:32];
        for (UIWindow *window in [[UIApplication sharedApplication] windows]) 
        {
            [views addObjectsFromArray:[window subviews]];
            //        if (![window respondsToSelector:@selector(screen)] || [window screen] == [UIScreen mainScreen]) {
            //            break;
            //        }
        }
        NSArray* result = [parser evalWith:views];
        
        if ([result count] >0) {
            UIView* v = [result objectAtIndex:0];//autopick first?
            NSDictionary *offset = [self.data valueForKey:@"offset"];
            NSNumber *x = [offset valueForKey:@"x"];
            NSNumber *y = [offset valueForKey:@"y"];
            
            CGPoint offsetPoint = CGPointMake([x floatValue], [y floatValue]);
            
            CGPoint center = [LPTouchUtils centerOfView:v];
            NSArray* baseEvents = [LPResources eventsFromEncoding:base64Events];
            
            targetView = v;
            self.events = [LPResources transformEvents:baseEvents 
                                               toPoint:CGPointMake(center.x+offsetPoint.x, center.y+offsetPoint.y)];
            
            
            
            
            
        } else {
            NSLog(@"query %@ found no views. NO-OP.",query);
            self.done = YES;
            self.jsonResponse = [NSDictionary dictionaryWithObjectsAndKeys:
                    [NSString stringWithFormat: @"query %@ found no views. Is accessibility enabled?",query],@"reason",
                    @"",@"details",
                    @"FAILURE",@"outcome",
                    nil];
            self.events = nil;
            [self.conn responseHasAvailableData:self];
            return;
        }
        
        
    } else {
        self.events = [LPResources eventsFromEncoding:base64Events];
    }
    
    if ([self.data objectForKey:@"reverse"]) {
        self.events = [[_events reverseObjectEnumerator] allObjects];
    }
    //NSLog(@"PLAY Events:\n%@",self.events);    
    NSDictionary *firstEvent = [self.events objectAtIndex:0];
    NSDictionary* windowLoc = [firstEvent valueForKey:@"WindowLocation"];
    
    if (!targetView && windowLoc != nil) {
        CGPoint touchPoint = CGPointMake([[windowLoc valueForKey:@"X"] floatValue], 
                                         [[windowLoc valueForKey:@"Y"] floatValue]);
        for (UIWindow *window in [[UIApplication sharedApplication] windows]) {                
            if (![window respondsToSelector:@selector(screen)] || [window screen] == [UIScreen mainScreen]) {
                targetView = [window hitTest:touchPoint withEvent:nil];
                break;
            }
        }
        
    }
    
//    NSString *base64Prototype = [self.data objectForKey:@"prototype"];
//    if (base64Prototype) {
//        NSArray* protoEvents = [LPResources eventsFromEncoding:base64Prototype];
//        
//        NSLog(@"Prototype Events\n%@",protoEvents);
//        
        
//    }
    
    [self play:self.events];
    NSArray *resultArray = nil;
    if (targetView == nil) {
        resultArray = [NSArray array];
    } else {
        resultArray = [NSArray arrayWithObject:targetView];
    }
    
    self.jsonResponse = [NSDictionary dictionaryWithObjectsAndKeys:
            resultArray, @"results",
            @"SUCCESS",@"outcome",
            nil];


}
// Returns the data for the response.
// To support asynchronous responses, read the discussion at the bottom of this header.
- (NSData *)readDataOfLength:(NSUInteger)length {
    if (!self.done) {
        if (!self.events) {
            [self playbackEvents]; 
        }
        return nil;   
    }
    else {        
        self.events = nil;
    
        NSString* serialized = [LPJSONUtils serializeDictionary:self.jsonResponse];
        self.jsonResponse = nil;
        return [serialized dataUsingEncoding:NSUTF8StringEncoding];
    }
}

// Should only return YES after the HTTPConnection has read all available data.
- (BOOL)isDone {
    return self.done && self.events == nil && self.jsonResponse == nil;
}


- (void) play:(NSArray *)events {
    [[LPRecorder sharedRecorder] load: self.events];
    [[LPRecorder sharedRecorder] playbackWithDelegate: self doneSelector: @selector(playbackDone:)];
    
}

-(void) playbackDone:(NSDictionary *)details {
    self.done = YES;
    [self.conn responseHasAvailableData:self];
}


- (BOOL)supportsMethod:(NSString *)method atPath:(NSString *)path {
    return [method isEqualToString:@"POST"];
}
-(void) setConnection:(HTTPConnection *)connection{
    self.conn = connection;
}
-(void) setParameters:(NSDictionary *) params {
    self.data = params;
}


- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path {    
    LPAsyncPlaybackRoute* route = [[[LPAsyncPlaybackRoute alloc] init] autorelease];
    [route setParameters:self.data];
    [route setConnection:self.conn];
    self.data = nil;
    self.conn = nil;
    return route;
}

@end
