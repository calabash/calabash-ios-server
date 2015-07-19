//
//  LPRouter.m
//  Created by Karl Krukow on 13/08/11.
//  Copyright 2011 LessPainful. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPRouter.h"
#import "LPJSONUtils.h"
#import "LPCORSResponse.h"
#import "LPInvoker.h"
#import "LPInvocationResult.h"
#import "LPInvocationError.h"
#import "LPCocoaLumberjack.h"

@interface LPRouter ()

@property(nonatomic, retain, readonly) NSMutableData *mutablePostData;

@end

@implementation LPRouter

#pragma mark - Memory Management

@synthesize mutablePostData = _mutablePostData;

static NSMutableDictionary *routes = nil;

- (NSData *) postData {
  return [NSData dataWithData:self.mutablePostData];
}

+ (void) initialize {
  static BOOL initialized = NO;
  if (!initialized) {
    // Initialize class variables
    routes = [[NSMutableDictionary alloc] initWithCapacity:16];
    initialized = YES;
  }
}

+ (void) addRoute:(id <LPRoute>) route forPath:(NSString *) path {
  [routes setObject:route forKey:path];
}

- (void) processBodyData:(NSData *) postDataChunk {
  if (_mutablePostData == nil) {
    _mutablePostData = [[NSMutableData alloc] initWithData:postDataChunk];
  } else {
    [_mutablePostData appendData:postDataChunk];
  }
}

- (NSObject <LPHTTPResponse> *) responseForJSON:(NSDictionary *) json {
  if (json == nil) {
    json = [NSDictionary dictionaryWithObjectsAndKeys:[NSArray array], @"results",
                                                      @"SUCCESS", @"outcome",
                                                      nil];
  }
  NSString *serialized = [LPJSONUtils serializeDictionary:json];
  NSData *data = [serialized dataUsingEncoding:NSUTF8StringEncoding];
  return [[LPCORSResponse alloc] initWithData:data];
}


- (BOOL) supportsMethod:(NSString *) method atPath:(NSString *) path {
  if ([method isEqualToString: @"OPTIONS"]) {
    return YES;
  }
  NSArray *components = [path componentsSeparatedByString:@"?"];
  NSArray *pathComponents = [[components objectAtIndex:0]
          componentsSeparatedByString:@"/"];
  NSString *lastSegment = [pathComponents lastObject];

  id <LPRoute> route = [LPRouter routeForKey:lastSegment];
  BOOL supported = [route supportsMethod:method atPath:lastSegment];

  return supported;
}

- (NSObject <LPHTTPResponse> *) httpResponseOnMainThreadForMethod:(NSString *) method
                                                              URI:(NSString *) path {
  if ([method isEqualToString: @"OPTIONS"]) {
    return [[LPCORSResponse alloc] initWithData:[NSData data]];
  }

  NSArray *components = [path componentsSeparatedByString:@"?"];
  NSArray *pathComponents = [[components objectAtIndex:0]
                             componentsSeparatedByString:@"/"];
  NSString *lastSegment = [pathComponents lastObject];


  id <LPRoute> route = [LPRouter routeForKey:lastSegment];

  if ([route supportsMethod:method atPath:path]) {
    NSDictionary *params = nil;
    if ([method isEqualToString:@"GET"]) {
      params = [super parseGetParams];
    }

    if ([method isEqualToString:@"POST"]) {
      NSData *postData = [self postData];
      if (postData && [postData length] > 0) {
        NSString *postDataAsString;
        postDataAsString = [[NSString alloc] initWithBytes:[postData bytes]
                                                    length:[postData length]
                                                  encoding:NSUTF8StringEncoding];
        params = [LPJSONUtils deserializeDictionary:postDataAsString];

        // UNEXPECTED
        // After the POST data is parsed we need to unset it.
        _mutablePostData = nil;
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
      LPLogDebug(@"Making a raw call to route with:");
      LPLogDebug(@"selector:  %@", NSStringFromSelector(raw));
      LPLogDebug(@"  target:  %@", NSStringFromClass([route class]));
      NSArray *arguments = @[method, path];
      LPInvocationResult *invocationResult;
      invocationResult = [LPInvoker invokeSelector:raw
                                        withTarget:route
                                         arguments:arguments];

      if ([invocationResult isError]) {
        LPLogError(@"%@", [invocationResult description]);
        return nil;
      } else {
        if ([invocationResult isNSNull]) {
          return nil;
        } else {
          return invocationResult.value;
        }
      }
    }

    NSDictionary *json = [route JSONResponseForMethod:method
                                                  URI:path
                                                 data:params];
    return [self responseForJSON:json];
  }
  return nil;
}

- (NSObject <LPHTTPResponse> *) httpResponseForMethod:(NSString *) method
                                                  URI:(NSString *) path {

  if ([[NSThread currentThread] isMainThread]) {
    return [self httpResponseOnMainThreadForMethod:method URI:path];
  } else {
    __weak typeof(self) wself = self;
    __block NSObject<LPHTTPResponse> *result = nil;
    dispatch_sync(dispatch_get_main_queue(), ^{
      result = [wself httpResponseOnMainThreadForMethod:method
                                                    URI:path];
    });
    return result;
  }
}

@end
