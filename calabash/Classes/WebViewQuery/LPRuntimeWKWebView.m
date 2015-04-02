#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPRuntimeWKWebView.h"
#import "LPJSONUtils.h"
#import "LPWebViewProtocol.h"
#import <objc/runtime.h>

NSString *const LPRuntimeWKWebViewISO8601DateFormat = @"yyyy-MM-dd HH:mm:ss Z";

@interface LPJSReturnedObjectParser ()

- (LPJSReturnedObjectParser *) returnsSelfForEncoding;

@end

@implementation LPJSReturnedObjectParser

- (NSString *) lpStringWithDate:(NSDate *) date {
  NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
  [formatter setDateFormat:LPRuntimeWKWebViewISO8601DateFormat];
  return [formatter stringFromDate:date];
}

- (NSString *) lpStringWithDictionary:(NSDictionary *) dictionary {
  return [LPJSONUtils serializeDictionary:dictionary];
}

- (NSString *) lpStringWithArray:(NSArray *) array {
  return [LPJSONUtils serializeArray:array];
}

- (LPJSReturnedObjectParser *) returnsSelfForEncoding {
  return self;
}

@end

static NSString *LPStringWithDateIMP(id self, SEL _cmd, NSDate *date) {
  NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
  [formatter setDateFormat:LPRuntimeWKWebViewISO8601DateFormat];
  return [formatter stringFromDate:date];
}

@implementation LPRuntimeWKWebView

+ (BOOL) create {

  Class LPWKWebViewClass = objc_getClass("WKWebView");
  if (!LPWKWebViewClass) { return NO; }

  Protocol *lpWebViewProtocol = NSProtocolFromString(@"LPWebViewProtocol");
  class_addProtocol(LPWKWebViewClass, lpWebViewProtocol);

  Method descript = class_getInstanceMethod([NSObject class],
                                            @selector(description));

  const char *stringEncoding = method_getTypeEncoding(descript);

  SEL withDateSel = NSSelectorFromString(@"lpStringWithDate:");
  class_addMethod(LPWKWebViewClass, withDateSel,
                  (IMP)LPStringWithDateIMP, stringEncoding);

  return YES;
}

@end
