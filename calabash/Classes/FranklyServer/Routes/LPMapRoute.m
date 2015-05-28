#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif
//
//  MapRoute.m
//  Created by Karl Krukow on 13/08/11.
//  Copyright 2011 LessPainful. All rights reserved.
//
#import "LPMapRoute.h"
#import "LPOperation.h"
#import "LPTouchUtils.h"
#import "LPOrientationOperation.h"
#import "LPLog.h"
#import "LPJSONUtils.h"
#import "LPHTTPDataResponse.h"
#import "LPDevice.h"
#import "LPInvoker.h"

@implementation LPMapRoute

@synthesize parser = _parser;

- (BOOL) supportsMethod:(NSString *) method atPath:(NSString *) path {
  return [method isEqualToString:@"POST"];
}

// Calabash as Frank Plug-In support.
- (BOOL) canHandlePostForPath:(NSArray *) path {
  return [@"cal_map" isEqualToString:[path lastObject]];
}

// Calabash as Frank Plug-In support.
// The connection argument will be: RoutingHTTPConnection which has the
// 'postDataAsString' selector defined.
- (id) handleRequestForPath:(NSArray *) path withConnection:(id) connection {

  if (![self canHandlePostForPath:path]) {
    return nil;
  }

  NSDictionary *response = nil;
  SEL selector = NSSelectorFromString(@"postDataAsString");

  if ([connection respondsToSelector:selector]) {
    id connectionData = [LPInvoker invokeSelector:selector
                                       withTarget:connection];
    NSDictionary *data = [LPJSONUtils deserializeDictionary:connectionData];

    response = [self JSONResponseForMethod:@"POST"
                                       URI:@"cal_map"
                                      data:data];

  } else {

    NSString *reason = [NSString stringWithFormat:@"%@ does not respond to selector %@",
                        [connection class], NSStringFromSelector(selector)];
    NSString *details = [NSString stringWithFormat:@"The %@ method should only be on called on the %@ class instances when Calabash is being used as a plug-in for Frank.",
                         NSStringFromSelector(@selector(handleRequestForPath:withConnection:)),
                         [LPMapRoute class]];
    response =
    @{
      @"outcome" : @"FAILURE",
      @"reason" : reason,
      @"details" : details
      };
  }

  NSData *jsonData = [[LPJSONUtils serializeDictionary:response]
                      dataUsingEncoding:NSUTF8StringEncoding];

  return [[LPHTTPDataResponse alloc] initWithData:jsonData];
}

- (NSArray *) applyOperation:(NSDictionary *) operation
                     toViews:(NSArray *) views
                     error:(NSError *__autoreleasing*) error {
  NSString *operationName = [operation objectForKey:@"method_name"];

  if (!operationName) {  return [views copy];  }

  LPOperation *op = [LPOperation operationFromDictionary:operation];
  NSMutableArray *finalRes = [NSMutableArray arrayWithCapacity:[views count]];

  if (views == nil || views.count == 0) {
    id res = [op performWithTarget:nil error:error];
    if (res != nil) {
      [finalRes addObject:res];
    }
  } else {
    for (id view in views) {
      NSError *err = nil;
      id val = [op performWithTarget:view error:&err];
      if (err) {continue;}
      if (val == nil) {
        [finalRes addObject:[NSNull null]];
      } else {
        [finalRes addObject:val];
      }
    }
  }
  return finalRes;
}

- (NSDictionary *) JSONResponseForMethod:(NSString *) method
                                     URI:(NSString *) path
                                    data:(NSDictionary *) data {
  id scriptObj = [data objectForKey:@"query"];
  NSDictionary *operation = [data objectForKey:@"operation"];
  NSArray *result = nil;
  if ([NSNull null] != scriptObj) {

    self.parser = [UIScriptParser scriptParserWithObject:scriptObj];
    [self.parser parse];
    NSArray *tokens = [self.parser parsedTokens];
    NSLog(@"Map %@, %@ Parsed UIScript as\n%@", method, path, tokens);

    NSArray *allWindows = [LPTouchUtils applicationWindows];
    result = [self.parser evalWith:allWindows];
  } else {
    result = nil;
  }
  self.parser = nil;
  NSError *error = nil;
  NSArray *resultArray = [self applyOperation:operation
                                      toViews:result
                                        error:&error];

  NSDictionary *resultDict = nil;
  if (resultArray) {
    resultDict =
    @{
      @"status_bar_orientation" : [LPOrientationOperation statusBarOrientation],
      @"results" : resultArray,
      @"outcome" : @"SUCCESS"
      };
  } else {
    resultDict =
    @{
      @"outcome" : @"FAILURE",
      @"reason" : @"",
      @"details" : @""
      };
  }
  [LPLog debug:@"Map results %@", resultDict];

  return resultDict;
}

@end
