//  Created by Karl Krukow on 12/04/14.
//  Copyright (c) 2014 Xamarin. All rights reserved.

#import "LPDumpRoute.h"
#import "LPTouchUtils.h"
#import "LPHTTPDataResponse.h"
#import "LPJSONUtils.h"
#import "LPWebQuery.h"

@implementation LPDumpRoute

- (BOOL) supportsMethod:(NSString *) method atPath:(NSString *) path {
  return [method isEqualToString:@"GET"];
}

- (BOOL)canHandlePostForPath:(NSArray *)path {
  return [@"calabash_dump" isEqualToString:[path lastObject]];
}

- (id)handleRequestForPath:(NSArray *)path withConnection:(id)connection {
  if (![self canHandlePostForPath:path]) {
    return nil;
  }
  NSDictionary *version = [self JSONResponseForMethod:@"GET" URI:@"calabash_dump" data:nil];
  NSData *jsonData = [[LPJSONUtils serializeDictionary:version] dataUsingEncoding:NSUTF8StringEncoding];
  
  return [[[LPHTTPDataResponse alloc] initWithData:jsonData] autorelease];
  
}


- (NSDictionary *) JSONResponseForMethod:(NSString *) method URI:(NSString *) path data:(NSDictionary *) data {
  return [self recursiveDumpParent: self.calabashRootView children: [LPTouchUtils applicationWindows]];

}



/* 
 //Same format as Calabash Android
 return new HashMap() {
{
  put("id", null);
  put("el", null);
  put("rect", null);
  put("hit-point", null);
  put("action", false);
  put("enabled", false);
  put("visible", true);
  put("value", null);
  put("path", new ArrayList<Integer>());
  put("type", "[object CalabashRootView]");
  put("name", null);
  put("label", null);
 }
};
 */

-(NSDictionary*)calabashRootView {
  return [NSMutableDictionary dictionaryWithObjectsAndKeys:
            @"CalabashRootView",@"type",
            @(1), @"visible",
          nil];
}

-(NSDictionary*)recursiveDumpParent:(NSDictionary*) parent children:(NSArray*)children {

  NSMutableArray *serializedChildren = [[NSMutableArray alloc] initWithCapacity:32];
  for (id view in children) {
    NSDictionary *viewDic = [LPJSONUtils jsonifyObject:view fullDump:YES];
    if ([viewDic isKindOfClass:[NSDictionary class]]) {
      if ([view isKindOfClass:[UIWebView class]]) {
        NSMutableDictionary *viewCopy = [NSMutableDictionary dictionaryWithDictionary:viewDic];
        viewCopy[@"children"] = [NSArray arrayWithObject: [LPWebQuery dictionaryOfViewsInWebView:(UIWebView*)view]];
        viewDic = viewCopy;
      }
      else {
        [self recursiveDumpParent:viewDic children: [LPTouchUtils accessibilityChildrenFor: view]];
      }
      [serializedChildren addObject:viewDic];
    }
  }
  [parent setValue:[serializedChildren autorelease] forKey:@"children"];
  return parent;
}

@end
