//
//  GenericAsyncRoute.m
//  calabash
//
//  Created by Karl Krukow on 29/01/12.
//  Copyright (c) 2012 Xamarin. All rights reserved.
//

#import "LPGenericAsyncRoute.h"

#import "HTTPResponse.h"
#import "HTTPConnection.h"
#import "RoutingHTTPConnection.h"
#import "LPResources.h"
#import "LPRecorder.h"
#import "UIScriptParser.h"
#import "JSON.h"
#import "LPTouchUtils.h"
#import "LPJSONUtils.h"


@implementation LPGenericAsyncRoute

@synthesize done=_done;
@synthesize conn=_conn;
@synthesize data=_data;
@synthesize jsonResponse=_jsonResponse;

-(id) init 
{
    self = [super init];
    if (self) 
    {
        _bytes = nil;
    }
    return self;
}
-(BOOL)matchesPath:(NSArray *)path 
{
    return NO;
}

- (NSObject<HTTPResponse> *) handleRequestForPath: (NSArray *)path withConnection:(RoutingHTTPConnection *)connection_
{
    if (![self matchesPath:path]) { return nil; }
    self.data = [LPJSONUtils deserializeDictionary:[connection_ postDataAsString]];
    self.conn = connection_;

    return [self httpResponse];

}
- (BOOL) canHandlePostForPath: (NSArray *)path
{
    if (![self matchesPath:path]) { return NO; }
    return YES;
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
    if (!self.done) 
    {
        dispatch_sync(dispatch_get_main_queue(), ^{
            
            [self beginOperation];

        });
        return nil;//Data generated async.
    }
    else {//done is set to YES only after events and jsonResponse is set (playbackDone)
        if (!_bytes) 
        {
            __block NSString* serialized;
            dispatch_sync(dispatch_get_main_queue(), ^{

                serialized = [[LPJSONUtils serializeDictionary:self.jsonResponse] retain];
            });
            self.jsonResponse = nil;
            _bytes = [serialized dataUsingEncoding:NSUTF8StringEncoding];
            [serialized release];
            
        }
        if (length >= [_bytes length]) 
        {
            return [[_bytes mutableCopy] autorelease];
        } 
        else 
        {//length < [_bytes length]
            NSData *toReturn = [_bytes subdataWithRange:NSMakeRange(0, length)];
            _bytes = [_bytes subdataWithRange:NSMakeRange(length, _bytes.length - length)];//the rest
            return toReturn;
        }                
    }
}

//Abstract
-(void)beginOperation
{
    
}

// Should only return YES after the HTTPConnection has read all available data.
- (BOOL)isDone 
{
    return _done && !self.jsonResponse;
}


// This method is called from the HTTPConnection class when the connection is closed,
// or when the connection is finished with the response.
// If your response is asynchronous, you should implement this method so you can be sure not to
// invoke HTTPConnection's responseHasAvailableData method after this method is called.
- (void)connectionDidClose 
{
    self.conn = nil;
}

-(void)failWithMessageFormat:(NSString *)messageFmt message:(NSString *)message
{
    self.done = YES;
    NSString *msg = !message ? messageFmt : [NSString stringWithFormat: messageFmt,message];
    
    self.jsonResponse = [NSDictionary dictionaryWithObjectsAndKeys:
                         msg,@"reason",
                         @"",@"details",
                         @"FAILURE",@"outcome",
                         nil];
    [self.conn responseHasAvailableData:self];
}
-(void)succeedWithResult:(NSArray *)result
{
    self.done = YES;
    self.jsonResponse = [NSDictionary dictionaryWithObjectsAndKeys:
                         result, @"results",
                         @"SUCCESS",@"outcome",
                         nil];
    [self.conn responseHasAvailableData:self];
}


-(void) setConnection:(HTTPConnection *)connection
{
    self.conn = connection;
}
-(void) setParameters:(NSDictionary *) params 
{
    self.data = params;
}


- (NSObject<HTTPResponse> *)httpResponse 
{    
    id route = [[[[self class] alloc] init] autorelease];
    [route setParameters:self.data];
    [route setConnection:self.conn];
    self.data = nil;
    self.conn = nil;
    return route;
}

-(void) dealloc 
{
    self.data = nil;
    self.conn = nil;
    self.jsonResponse = nil;
    [super dealloc];
}

@end

//From CocoaHTTPServer
// Important notice to those implementing custom asynchronous and/or chunked responses:
// 
// HTTPConnection supports asynchronous responses.  All you have to do in your custom response class is
// asynchronously generate the response, and invoke HTTPConnection's responseHasAvailableData method.
// You don't have to wait until you have all of the response ready to invoke this method.  For example, if you
// generate the response in incremental chunks, you could call responseHasAvailableData after generating
// each chunk.  You MUST invoke the responseHasAvailableData method on the proper thread/runloop.  That is,
// the thread/runloop that the HTTPConnection is operating in.  Please see the HTTPAsyncFileResponse class
// for an example of how to properly do this.
// 
// The normal flow of events for an HTTPConnection while responding to a request is like this:
// - Get data from response via readDataOfLength method.
// - Add data to asyncSocket's write queue.
// - Wait for asyncSocket to notify it that the data has been sent.
// - Get more data from response via readDataOfLength method.
// ... continue this cycle until it has sent the entire response.
// 
// With an asynchronous response, the flow is a little different.  When HTTPConnection calls your
// readDataOfLength method, you may or may not have any available data.  If you don't, then simply return nil.
// You should later invoke HTTPConnection's responseHasAvailableData when you have data to send.
// 
// You don't have to keep track of when you return nil in the readDataOfLength method, or how many times you've invoked
// responseHasAvailableData. Just simply call responseHasAvailableData whenever you've generated new data, and
// return nil in your readDataOfLength whenever you don't have any available data in the requested range.
// HTTPConnection will automatically detect when it should be requesting new data and will act appropriately.
// 
// It's important that you also keep in mind that the HTTP server supports range requests.
// The setOffset method is mandatory, and should not be ignored.
// Make sure you take into account the offset within the readDataOfLength method.
// You should also be aware that the HTTPConnection automatically sorts any range requests.
// So if your setOffset method is called with a value of 100, then you can safely release bytes 0-98.
// 
// HTTPConnection can also he you keep your memory footprint small.
// Imagine you're dynamically generating a 10 MB response.  You probably don't want to load all this data into
// RAM, and sit around waiting for HTTPConnection to slowly send it out over the network.  All you need to do
// is pay attention to when HTTPConnection requests more data via readDataOfLength.  This is because HTTPConnection
// will never allow asyncSocket's write queue to get much bigger than READ_CHUNKSIZE bytes.  You should
// consider how you might be able to take advantage of this fact to generate your asynchronous response on demand,
// while at the same time keeping your memory footprint small, and your application lightning fast.
// 
// If you don't know the content-length in advanced, you should also implement the isChunked method.
// This means the response will not include a Content-Length header, and will instead use "Transfer-Encoding: chunked".
// There's a good chance that if your response is asynchronous and dynamic, it's also chunked.
// If your response is chunked, you don't need to worry about range requests.

