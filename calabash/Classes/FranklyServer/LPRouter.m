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

@interface LPRouterDictionary : NSObject

@property(atomic, strong, readonly) NSMutableDictionary *routes;

+ (LPRouterDictionary *) shared;
- (id) init_private;

@end

@implementation LPRouterDictionary

#pragma mark - Memory Management

@synthesize routes = _routes;

- (id) init {
  NSString *reason;
  reason = [NSString stringWithFormat:@"%@ does not respond to 'init' selector",
            [self class]];
  @throw [NSException exceptionWithName:@"Singleton Pattern"
                                 reason:reason
                               userInfo:nil];
}

+ (LPRouterDictionary *) shared {
  static LPRouterDictionary *sharedDictionary = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedDictionary = [[LPRouterDictionary alloc] init_private];
  });
  return sharedDictionary;
}

- (id) init_private {
  self = [super init];
  if (self) {
    _routes = [[NSMutableDictionary alloc] initWithCapacity:32];
  }
  return self;
}

@end


@interface LPRouter ()

@property(nonatomic, retain, readonly) NSMutableData *mutablePostData;

- (NSObject <LPHTTPResponse> *) httpResponseOnMainThreadForMethod:(NSString *) method
                                                              URI:(NSString *) path;

@end

@implementation LPRouter

#pragma mark - Adding and Fetching Routes

+ (void) addRoute:(id <LPRoute>) route forPath:(NSString *) path {
  LPRouterDictionary *shared = [LPRouterDictionary shared];
  [shared.routes setObject:route forKey:path];
}

+ (id<LPRoute>) routeForKey:(NSString *) key {
  LPRouterDictionary *shared = [LPRouterDictionary shared];
  return [shared.routes objectForKey:key];
}

#pragma mark - Memory Management

@synthesize mutablePostData = _mutablePostData;

- (NSData *) postData {
  return [NSData dataWithData:self.mutablePostData];
}

- (NSMutableData *) mutablePostData {
  if (_mutablePostData) { return _mutablePostData;  }
  _mutablePostData = [[NSMutableData alloc] initWithData:[NSData data]];
  return _mutablePostData;
}

- (void) processBodyData:(NSData *) postDataChunk {
  [self.mutablePostData appendData:postDataChunk];
}

- (NSObject <LPHTTPResponse> *) responseForJSON:(NSDictionary *) json {
  if (json == nil) {
    json =
    @{
      @"results" : @[],
      @"outcome" : @"SUCCESS"
    };
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
        LPLogInfo(@"POST: [%@] %@", NSStringFromClass([route class]), params);
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
    // Use performSelectorOnMainThread instead of dispatch_sync because using a dispatch method prevents
    // further blocks from being processed on the main queue until the initial block in which the
    // httpResponseOnMainThreadForMethod was invoked has completed.
    // dispatch_sync prevents other blocks being processed in nested calls to NSRunLoop run methods within tests.
    NSObject<LPHTTPResponse> __unsafe_unretained *result = nil;
    SEL selector = @selector(httpResponseOnMainThreadForMethod:URI:);
    NSMethodSignature *methodSignature = [self methodSignatureForSelector:selector];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
    [invocation setTarget:self];
    [invocation setSelector:selector];
    [invocation setArgument:&method atIndex:2];
    [invocation setArgument:&path atIndex:3];
    [invocation retainArguments];
    [invocation performSelectorOnMainThread:@selector(invoke) withObject:nil waitUntilDone:YES];
    [invocation getReturnValue:&result];
    return result;
  }
}

@end
