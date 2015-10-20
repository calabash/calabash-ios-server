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
#import "LPUIARouteOverUserPrefs.h"
#import "LPVersionRoute.h"
#import "LPJSONUtils.h"
#import "LPMapRoute.h"
#import "LPCocoaLumberjack.h"

#define MAKE_CATEGORIES_LOADABLE(UNIQUE_NAME) @interface FORCELOAD_##UNIQUE_NAME : NSObject @end @implementation FORCELOAD_##UNIQUE_NAME @end

static NSString *const selectorName = @"calabash_uispec";


@implementation LPCalabashFrankRegistrar

+(void)load{
  LPCalabashFrankRegistrar *calabashUIQuerySelector = [self new];
  [SelectorEngineRegistry registerSelectorEngine:calabashUIQuerySelector WithName:selectorName];
  g(@"Registered Calabash selector engine registered with Frank under name '%@'", selectorName);
  [calabashUIQuerySelector release];
  LPLogDebug(@"About to create route...");
  Class c = NSClassFromString(@"RequestRouter");
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
#pragma clang diagnostic ignored "-Wobjc-method-access"
  id frankRouter = [c performSelector:@selector(singleton)];
  LPLogDebug(@"Router: %@", frankRouter);

  LPUIARouteOverUserPrefs *uiaUsingUserPrefs = [LPUIARouteOverUserPrefs new];
  [frankRouter registerRoute:uiaUsingUserPrefs];
  [uiaUsingUserPrefs release];

  LPVersionRoute *versionRoute = [LPVersionRoute new];
  [frankRouter registerRoute:versionRoute];
  [versionRoute release];

  LPMapRoute *mapRoute = [LPMapRoute new];
  [frankRouter registerRoute:mapRoute];
  [mapRoute release];
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

MAKE_CATEGORIES_LOADABLE(NSObject_CalabashExtensions)

@implementation NSObject (CalabashExtensions)

- (NSDictionary*) query {
  return [LPJSONUtils jsonifyObject:self];
}
@end


