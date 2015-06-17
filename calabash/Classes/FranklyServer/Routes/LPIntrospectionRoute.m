#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif
//
//  LPAccessorRoute.m
//  calabash
//
//  Created by Chris Fuentes on 6/5/15.
//  Copyright (c) 2015 Xamarin. All rights reserved.
//

#import "LPIntrospectionRoute.h"
#import "UIScriptParser.h"
#import "LPTouchUtils.h"
#import "LPJSONUtils+Introspection.h"

@interface LPIntrospectionRoute ()
@end

@implementation LPIntrospectionRoute

- (BOOL) supportsMethod:(NSString *) method atPath:(NSString *) path {
  return [method isEqualToString:@"POST"];
}

- (NSDictionary *)JSONResponseForMethod:(NSString *) method URI:(NSString *) path data:(NSDictionary *) data {
  NSMutableArray *ret;
  id scriptObj              = data[@"query"];
  NSArray *results          = nil;
  
  if (scriptObj != [NSNull null]) {
    results = [self parseQueryIntoViews:scriptObj];
  }
  
  ret   = [NSMutableArray arrayWithCapacity:results.count];
  for (id thing in results) {
    NSMutableDictionary *objectJSON = [[LPJSONUtils objectIntrospection:thing] mutableCopy];
    NSDictionary *objectMetadata    = [LPJSONUtils jsonifyObject:thing];
    
    for (NSString *key in @[@"id", @"description", @"class"]) {
      if (objectMetadata[key])
        objectJSON[key] = objectMetadata[key];
    }
    
    [ret addObject:objectJSON];
  }
  
  return @{@"results" : ret};
}


- (NSArray *)parseQueryIntoViews:(id)scriptObj {
  UIScriptParser *parser  = [UIScriptParser scriptParserWithObject:scriptObj];
  [parser parse];  
  NSArray *allWindows = [LPTouchUtils applicationWindows];
  return [parser evalWith:allWindows];
}

@end
