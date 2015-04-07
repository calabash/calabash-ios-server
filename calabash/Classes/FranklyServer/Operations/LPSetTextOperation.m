#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

//  Created by Karl Krukow on 11/09/11.
//  Copyright (c) 2011 LessPainful. All rights reserved.

#import "LPSetTextOperation.h"
#import "LPJSONUtils.h"
#import "LPWebViewProtocol.h"

@implementation LPSetTextOperation
- (NSString *) description {
  return [NSString stringWithFormat:@"Text: %@", _arguments];
}


- (id) performWithTarget:(id) target error:(NSError **) error {
  id result = nil;
  if (!_arguments || [_arguments count] == 0) {
    NSLog(@"Missing the 'text' argument @ index 0 of arguments; nothing to do - returning nil");
    result = nil;
  } else if ([target isKindOfClass:[NSDictionary class]]) {
    NSMutableDictionary *mdict = [NSMutableDictionary dictionaryWithDictionary:target];
    [mdict removeObjectForKey:@"html"];

    id webViewValue = [mdict valueForKey:@"webView"];
    if (!webViewValue) {
      NSLog(@"Missing value for 'webView' key in target; nothing to do - returning nil");
      result = nil;
    } else {
      if (![webViewValue conformsToProtocol:@protocol(LPWebViewProtocol)]) {
        NSLog(@"Expected 'webView' => UIView<LPWebViewProtocol>, found %@; nothing to do - returning nil",
              webViewValue);
        result = nil;
      } else {
        NSString *json = [LPJSONUtils serializeDictionary:mdict];
        NSString *res = [webViewValue stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:LP_SET_TEXT_JS,
                                                                              json]];
      }
    }
  } else if ([target respondsToSelector:@selector(setText:)]) {
    NSString *txt = nil;
    id argument = [_arguments objectAtIndex:0];
    if ([argument isKindOfClass:[NSString class]]) {
      txt = argument;
    } else {
      txt = [argument description];
    }
    [target performSelector:@selector(setText:) withObject:txt];
    result = target;
  }
  return result;
}

@end
