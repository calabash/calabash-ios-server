//
//  LPCalabashFrankRegistrar.m
//  calabash
//
//  Created by Karl Krukow on 22/07/14.
//  Copyright (c) 2014 Xamarin. All rights reserved.
//

#import "LPCalabashFrankRegistrar.h"
#import "UIScriptParser.h"
#import "LPTouchUtils.h"
#import "LPUIARoute.h"
#import "LPVersionRoute.h"

static NSString *const selectorName = @"calabash_uispec";


@implementation LPCalabashFrankRegistrar

+(void)load{
  LPCalabashFrankRegistrar *calabashUIQuerySelector = [self new];
  [SelectorEngineRegistry registerSelectorEngine:calabashUIQuerySelector WithName:selectorName];
  NSLog(@"Registered Calabash selector engine registered with Frank under name '%@'", selectorName);
  [calabashUIQuerySelector release];
  NSLog(@"About to create route...");
  Class c = NSClassFromString(@"RequestRouter");
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector" 
#pragma clang diagnostic ignored "-Wobjc-method-access"
  id frankRouter = [c performSelector:@selector(singleton)];
  NSLog(@"Router: %@", frankRouter);
  
  LPUIARoute *uiaRoute = [LPUIARoute new];
  [frankRouter registerRoute:uiaRoute];
  [uiaRoute release];

  LPVersionRoute *versionRoute = [LPVersionRoute new];
  [frankRouter registerRoute:versionRoute];
  [versionRoute release];
#pragma clang diagnostic pop
}

- (NSArray *) selectViewsWithSelector:(NSString *)selector {
  
  return [self selectViewsWithSelector:selector inWindows:[LPTouchUtils applicationWindows]];
}

- (NSArray *) selectViewsWithSelector:(NSString *)selector inWindows:(NSArray *)windows
{
  UIScriptParser *parser = [[UIScriptParser alloc] initWithUIScript:selector];
  [parser parse];
  NSArray *viewsFound = [parser evalWith:windows];
  [parser release];
  return viewsFound;
}

@end
