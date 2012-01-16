//
//  LPRouter.m
//  Created by Karl Krukow on 13/08/11.
//  Copyright 2011 LessPainful. All rights reserved.
//

#import "LPRouter.h"
#import "LPJSONUtils.h"
#import "HTTPDataResponse.h"

@implementation LPRouter
@synthesize postData=_postData;

static NSMutableDictionary* routes = nil;

+ (void)initialize
{
	static BOOL initialized = NO;
	if(!initialized)
	{
		// Initialize class variables
		routes = [[NSMutableDictionary alloc] initWithCapacity:5];
		initialized = YES;
	}
}

+ (void) addRoute:(id<LPRoute>) route forPath:(NSString*) path {
    [routes setObject:route forKey:path];
}

- (void)processBodyData:(NSData *)postDataChunk {
    if (_postData == nil) {
        _postData = [[NSMutableData alloc] initWithData:postDataChunk];
    } else {
        [_postData appendData:postDataChunk];
    }
	
}

- (void) dealloc {
    [_postData release];_postData=nil;
    [super dealloc];
}

- (NSObject<HTTPResponse> *) responseForJSON:(NSDictionary*) json {
    if (json == nil) {
        json=[NSDictionary dictionaryWithObjectsAndKeys:
              [NSArray array], @"results",
              @"SUCCESS",@"outcome",nil];
    }
    NSString* serialized = [LPJSONUtils serializeDictionary:json];
    NSData *data = [serialized dataUsingEncoding:NSUTF8StringEncoding];
    HTTPDataResponse *rsp = [[HTTPDataResponse alloc] initWithData:data];
    return [rsp autorelease];
}

- (BOOL)supportsMethod:(NSString *)method atPath:(NSString *)path
{
    id<LPRoute> route = [routes objectForKey:path];
    return ([route supportsMethod:method atPath:path]);
}

- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path {
    id<LPRoute> route = [routes objectForKey:path];
    if ([route supportsMethod:method atPath:path]) {
        NSDictionary* params = nil;
        if ([method isEqualToString:@"GET"]) {
            params=[super parseGetParams];
        }
        if ([method isEqualToString:@"POST"]) {
            if (_postData != nil && [_postData length]>0) {
                NSString* postDataAsString = [[NSString alloc] initWithBytes:[_postData bytes] length:[_postData length] encoding:NSUTF8StringEncoding];
                params=[LPJSONUtils deserializeDictionary:postDataAsString];
                [postDataAsString release];                    
            } 
        }
        if ([route respondsToSelector:@selector(setConnection:)]) {
            [route setConnection:self];
        }
        if ([route respondsToSelector:@selector(setParameters:)]) {
            [route setParameters:params];
        }
        
        SEL raw = @selector(httpResponseForMethod:URI:);
        if ([route respondsToSelector:raw]) {
            return [route performSelector:raw withObject:method withObject:path];
        }
        
        NSDictionary* json = [route JSONResponseForMethod:method URI:path data:params];
        return [self responseForJSON:json];
    }
    return nil;
    

}

@end
