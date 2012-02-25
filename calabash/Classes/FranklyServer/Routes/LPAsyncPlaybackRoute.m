//
//  LPAsyncPlaybackRoute.m
//  calabash
//
//  Created by Karl Krukow on 29/01/12.
//  Copyright (c) 2012 LessPainful. All rights reserved.
//

#import "LPAsyncPlaybackRoute.h"
#import "LPHTTPResponse.h"
#import "LPHTTPConnection.h"
#import "LPResources.h"
#import "LPRecorder.h"
#import "UIScriptParser.h"
#import "LPTouchUtils.h"
#import "LPJSONUtils.h"

@interface LPAsyncPlaybackRoute ()
-(void) playbackEvents;
@end

@implementation LPAsyncPlaybackRoute
@synthesize events=_events;
@synthesize done=_done;
@synthesize conn=_conn;
@synthesize data=_data;
@synthesize jsonResponse=_jsonResponse;

-(id) init {
    self = [super init];
    if (self) {
        _bytes = nil;
    }
    return self;
}

- (UInt64)offset {return 0;}
- (void)setOffset:(UInt64)offset {
    //this is not handled - we know our client wont use range requests
}


// Returns the length of the data in bytes.
// If you don't know the length in advance, implement the isChunked method and have it return YES.
- (UInt64)contentLength {
    return -1;
}
// Important: You should read the discussion at the bottom of this header.
- (BOOL)isChunked {
    return YES;
}

// To support asynchronous responses, read the discussion at the bottom of this header.
- (NSData *)readDataOfLength:(NSUInteger)length {
    if (!self.done) {
        [self playbackEvents]; 
        return nil;//Data generated async.
    }
    else {//done is set to YES only after events and jsonResponse is set (playbackDone)
        if (!_bytes) {
            NSString* serialized = [LPJSONUtils serializeDictionary:self.jsonResponse];
            self.events = nil;        
            self.jsonResponse = nil;
            _bytes = [serialized dataUsingEncoding:NSUTF8StringEncoding];    
        }
        if (length >= [_bytes length]) {
            return _bytes;
        } else {//length < [_bytes length]
            NSData *toReturn = [_bytes subdataWithRange:NSMakeRange(0, length)];
            _bytes = [_bytes subdataWithRange:NSMakeRange(length, _bytes.length - length)];//the rest
            return toReturn;
        }                
    }
}

// Should only return YES after the LPHTTPConnection has read all available data.
- (BOOL)isDone {
    return self.done && self.events == nil && self.jsonResponse == nil;
}


// This method is called from the LPHTTPConnection class when the connection is closed,
// or when the connection is finished with the response.
// If your response is asynchronous, you should implement this method so you can be sure not to
// invoke LPHTTPConnection's responseHasAvailableData method after this method is called.
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
        NSDictionary *offset = [self.data valueForKey:@"offset"];
        NSNumber *x = [offset valueForKey:@"x"];
        NSNumber *y = [offset valueForKey:@"y"];
        
        CGPoint offsetPoint = CGPointMake([x floatValue], [y floatValue]);
        
        self.events = [LPResources eventsFromEncoding:base64Events];
        self.events = [LPResources transformEvents:self.events 
                                           toPoint:CGPointMake(offsetPoint.x, offsetPoint.y)];
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




- (void) play:(NSArray *)events {
    [[LPRecorder sharedRecorder] load: self.events];
    [[LPRecorder sharedRecorder] playbackWithDelegate: self doneSelector: @selector(playbackDone:)];
    
}

//When this event occurs, jsonResponse has already been determined.
-(void) playbackDone:(NSDictionary *)details {
    self.done = YES;
    [self.conn responseHasAvailableData:self];
}



// Callbacks from router.
- (BOOL)supportsMethod:(NSString *)method atPath:(NSString *)path {
    return [method isEqualToString:@"POST"];
}

-(void) setConnection:(LPHTTPConnection *)connection{
    self.conn = connection;
}
-(void) setParameters:(NSDictionary *) params {
    self.data = params;
}


- (NSObject<LPHTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path {    
    LPAsyncPlaybackRoute* route = [[[LPAsyncPlaybackRoute alloc] init] autorelease];
    [route setParameters:self.data];
    [route setConnection:self.conn];
    self.data = nil;
    self.conn = nil;
    return route;
}

-(void) dealloc {
    self.data = nil;
    self.conn = nil;
    self.events = nil;
    self.jsonResponse = nil;
    [super dealloc];
}

@end

//From CocoaHTTPServer
// Important notice to those implementing custom asynchronous and/or chunked responses:
// 
// LPHTTPConnection supports asynchronous responses.  All you have to do in your custom response class is
// asynchronously generate the response, and invoke LPHTTPConnection's responseHasAvailableData method.
// You don't have to wait until you have all of the response ready to invoke this method.  For example, if you
// generate the response in incremental chunks, you could call responseHasAvailableData after generating
// each chunk.  You MUST invoke the responseHasAvailableData method on the proper thread/runloop.  That is,
// the thread/runloop that the LPHTTPConnection is operating in.  Please see the LPHTTPAsyncFileResponse class
// for an example of how to properly do this.
// 
// The normal flow of events for an LPHTTPConnection while responding to a request is like this:
// - Get data from response via readDataOfLength method.
// - Add data to asyncSocket's write queue.
// - Wait for asyncSocket to notify it that the data has been sent.
// - Get more data from response via readDataOfLength method.
// ... continue this cycle until it has sent the entire response.
// 
// With an asynchronous response, the flow is a little different.  When LPHTTPConnection calls your
// readDataOfLength method, you may or may not have any available data.  If you don't, then simply return nil.
// You should later invoke LPHTTPConnection's responseHasAvailableData when you have data to send.
// 
// You don't have to keep track of when you return nil in the readDataOfLength method, or how many times you've invoked
// responseHasAvailableData. Just simply call responseHasAvailableData whenever you've generated new data, and
// return nil in your readDataOfLength whenever you don't have any available data in the requested range.
// LPHTTPConnection will automatically detect when it should be requesting new data and will act appropriately.
// 
// It's important that you also keep in mind that the LPHTTP server supports range requests.
// The setOffset method is mandatory, and should not be ignored.
// Make sure you take into account the offset within the readDataOfLength method.
// You should also be aware that the LPHTTPConnection automatically sorts any range requests.
// So if your setOffset method is called with a value of 100, then you can safely release bytes 0-98.
// 
// LPHTTPConnection can also help you keep your memory footprint small.
// Imagine you're dynamically generating a 10 MB response.  You probably don't want to load all this data into
// RAM, and sit around waiting for LPHTTPConnection to slowly send it out over the network.  All you need to do
// is pay attention to when LPHTTPConnection requests more data via readDataOfLength.  This is because LPHTTPConnection
// will never allow asyncSocket's write queue to get much bigger than READ_CHUNKSIZE bytes.  You should
// consider how you might be able to take advantage of this fact to generate your asynchronous response on demand,
// while at the same time keeping your memory footprint small, and your application lightning fast.
// 
// If you don't know the content-length in advanced, you should also implement the isChunked method.
// This means the response will not include a Content-Length header, and will instead use "Transfer-Encoding: chunked".
// There's a good chance that if your response is asynchronous and dynamic, it's also chunked.
// If your response is chunked, you don't need to worry about range requests.

