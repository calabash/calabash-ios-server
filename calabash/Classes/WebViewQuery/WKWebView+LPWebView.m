#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "WKWebView+LPWebView.h"

/*
#import "LPJSONUtils.h"

// Inspiration from http://atmarkplant.com/ios-wkwebview-tips/ Daiji Ito @DJ110

NSString *const LPWKWebViewISO8601DateFormat = @"yyyy-MM-dd HH:mm:ss Z";

@interface WKWebView (WKWebView_LPWebView_Private)

- (NSString *) lpStringWithDate:(NSDate *) date;
- (NSString *) lpStringWithDictionary:(NSDictionary *) dictionary;
- (NSString *) lpStringWithArray:(NSArray *) array;

@end

@implementation WKWebView (WKWebView_LPWebView)

- (NSString *) calabashStringByEvaluatingJavaScript:(NSString *) javascript {
  __block id res = nil;
  __block BOOL finish = NO;
  [self evaluateJavaScript:javascript completionHandler:^(id result, NSError *error){
    if (error) {
      NSString *localizedDescription = [error localizedDescription];
      NSLog(@"Error evaluating JavaScript: '%@'", javascript);
      NSLog(@"Error was: '%@'", localizedDescription);
      NSDictionary *errorDict =
      @{
        @"error" : localizedDescription ? localizedDescription : [NSNull null],
        @"javascript" : javascript ? javascript : [NSNull null]
      };
      res = [LPJSONUtils serializeDictionary:errorDict];
    } else {
      res = result;
    }
    finish = YES;
  }];

  while(!finish) {
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
  }

  if (!res) { return @""; }
  if (res == [NSNull null]) { return @""; }
  if ([res isKindOfClass:[NSString class]]) { return res; }

  if ([res isKindOfClass:[NSDate class]]) {
    return [self lpStringWithDate:(NSDate *)res];
  } else if ([res isKindOfClass:[NSDictionary class]]) {
    return [self lpStringWithDictionary:(NSDictionary *)res];
  } else if ([res isKindOfClass:[NSArray class]]) {
    return [self lpStringWithArray:(NSArray *)res];
  } else {
    SEL stringValueSel = @selector(stringValue);
    if ([res respondsToSelector:stringValueSel]) {  return [res stringValue]; }
  }
  return [res description];
}

- (NSString *) lpStringWithDate:(NSDate *) date {
  NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
  [formatter setDateFormat:LPWKWebViewISO8601DateFormat];
  return [formatter stringFromDate:date];
}

- (NSString *) lpStringWithDictionary:(NSDictionary *) dictionary {
  return [LPJSONUtils serializeDictionary:dictionary];
}

- (NSString *) lpStringWithArray:(NSArray *) array {
  return [LPJSONUtils serializeArray:array];
}

@end
*/
