//
//  LPAccessorRoute.m
//  calabash
//
//  Created by Chris Fuentes on 6/5/15.
//  Copyright (c) 2015 Xamarin. All rights reserved.
//

#import "LPAccessorRoute.h"
#import "UIScriptParser.h"
#import "LPTouchUtils.h"
#import "LPJSONUtils+Accessors.h"

@interface LPAccessorRoute ()
//@property(nonatomic, strong) UIScriptParser *parser;
@end

@implementation LPAccessorRoute

- (NSDictionary *)JSONResponseForMethod:(NSString *) method URI:(NSString *) path data:(NSDictionary *) data {
  NSMutableArray *ret;
  id scriptObj              = data[@"query"];
  int options               = [self parseAccessorJSONOptions:data[@"options"]];
  NSArray *results          = nil;
  
  if (scriptObj != [NSNull null]) {
    results = [self parseQueryIntoViews:scriptObj];
  }
  
  ret   = [NSMutableArray arrayWithCapacity:results.count];
  for (id thing in results) {
    NSMutableDictionary *objectJSON = [[LPJSONUtils accessorsForObject:thing options:options] mutableCopy];
    NSDictionary *objectMetadata    = [LPJSONUtils jsonifyObject:thing];
    
    for (NSString *key in @[@"id", @"description", @"class"]) {
      objectJSON[key] = objectMetadata[key];
    }
    
    [ret addObject:objectJSON];
  }
  
  return @{@"results" : ret};
}

- (int)parseAccessorJSONOptions:(NSDictionary *)options {
  int opts = 0;
  if ([options[@"include_private"] boolValue])      opts |= kLPAccessorOptionsIncludePrivateMethods;
  if ([options[@"exclude_superclasses"] boolValue]) opts |= kLPAccessorOptionsOnlyExcludeSuperclasses;
  if ([options[@"verbose"] boolValue])              opts |= kLPAccessorOptionsVerbose;
  return opts;
}

- (NSArray *)parseQueryIntoViews:(id)scriptObj {
  
  UIScriptParser *parser  = [UIScriptParser scriptParserWithObject:scriptObj];
  [parser parse];  
  NSArray *allWindows = [LPTouchUtils applicationWindows];
  return [parser evalWith:allWindows];
}

@end
