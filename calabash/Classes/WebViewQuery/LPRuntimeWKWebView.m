#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPRuntimeWKWebView.h"
#import "LPJSONUtils.h"
#import "LPWebViewProtocol.h"
#import <objc/runtime.h>

NSString *const LPRuntimeWKWebViewISO8601DateFormat = @"yyyy-MM-dd HH:mm:ss Z";

@interface LPRuntimeWKWebView ()

+ (Class) lpClassForWKWebView;

+ (BOOL) addLPWebViewProtocol:(Class) klass;

+ (BOOL) addWithDateMethod:(Class) klass
                  encoding:(const char *) encoding;

+ (BOOL) addWithDictionaryMethod:(Class) klass
                        encoding:(const char *) encoding;

+ (BOOL) addWithArrayMethod:(Class) klass
                  encoding:(const char *) encoding;

+ (BOOL) addEvaluateJavaScriptMethod:(Class) klass
                            encoding:(const char *) encoding;

@end

static NSString *LPWKWebViewStringWithDateIMP(id self, SEL _cmd, NSDate *date) {
  NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
  [formatter setDateFormat:LPRuntimeWKWebViewISO8601DateFormat];
  return [formatter stringFromDate:date];
}

static NSString *LPWKWebViewStringWithDictionaryIMP(id self, SEL _cmd,
                                                    NSDictionary *dictionary) {
  return [LPJSONUtils serializeDictionary:dictionary];
}

static NSString *LPWKWebViewStringWithArrayIMP(id self, SEL _cmd,
                                               NSArray *array) {
  return [LPJSONUtils serializeArray:array];
}

@implementation LPRuntimeWKWebView

+ (LPWKWebViewWebViewProtocolImplementation) implementLPWebViewProtocolOnWKWebView {

  Class LPWKWebViewClass = [[self class] lpClassForWKWebView];
  if (!LPWKWebViewClass) {
    NSLog(@"WKWebView is not available");
    return LPWKWebViewNotAvailable;
  }

  Method descript = class_getInstanceMethod([NSObject class],
                                            @selector(description));

  const char *encoding = method_getTypeEncoding(descript);

  if (![[self class] addLPWebViewProtocol:LPWKWebViewClass]) {
    NSLog(@"Failed to add LPWebViewProtocol to WKWebView");
    return LPWKWebViewFailedToImplementProtocol;
  }

  if (![[self class] addWithDateMethod:LPWKWebViewClass encoding:encoding]) {
    NSLog(@"Failed to add lpStringWithDate: to WKWebView");
    return LPWKWebViewFailedToImplementProtocol;
  }

  if (![[self class] addWithDictionaryMethod:LPWKWebViewClass encoding:encoding]) {
    NSLog(@"Failed to add lpStringWithDictionary: to WKWebView");
    return LPWKWebViewFailedToImplementProtocol;
  }

  if (![[self class] addWithArrayMethod:LPWKWebViewClass encoding:encoding]) {
    NSLog(@"Failed to add lpStringWithArray: to WKWebView");
    return LPWKWebViewFailedToImplementProtocol;
  }

  if (![[self class] addEvaluateJavaScriptMethod:LPWKWebViewClass
                                        encoding:encoding]) {
    NSLog(@"Failed to add calabashStringByEvaluatingJavaScript: to WKWebView");
    return LPWKWebViewFailedToImplementProtocol;
  }

  NSLog(@"WKWebView successfully implemented LPWebViewProtocol");
  return LPWKWebViewDidImplementProtocol;
}

+ (Class) lpClassForWKWebView {
  return objc_getClass("WKWebView");
}

+ (BOOL) addLPWebViewProtocol:(Class) klass {
  Protocol *lpWebViewProtocol = NSProtocolFromString(@"LPWebViewProtocol");
  return class_addProtocol(klass, lpWebViewProtocol);
}

+ (BOOL) addWithDateMethod:(Class) klass
                  encoding:(const char *) encoding {
  SEL selector = NSSelectorFromString(@"lpStringWithDate:");
  return class_addMethod(klass,
                         selector,
                         (IMP)LPWKWebViewStringWithDateIMP,
                         encoding);
}

+ (BOOL) addWithDictionaryMethod:(Class) klass
                        encoding:(const char *) encoding {
  SEL selector = NSSelectorFromString(@"lpStringWithDictionary:");
  return class_addMethod(klass,
                         selector,
                         (IMP)LPWKWebViewStringWithDictionaryIMP,
                         encoding);
}

+ (BOOL) addWithArrayMethod:(Class) klass
                   encoding:(const char *) encoding {
  SEL selector = NSSelectorFromString(@"lpStringWithArray:");
  return class_addMethod(klass,
                         selector,
                         (IMP)LPWKWebViewStringWithArrayIMP,
                         encoding);
}

+ (BOOL) addEvaluateJavaScriptMethod:(Class) klass
                            encoding:(const char *) encoding {
  return NO;
}

@end
