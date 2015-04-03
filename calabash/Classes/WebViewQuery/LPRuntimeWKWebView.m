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

- (NSString *) withDatePrototype:(NSDate *) date;
+ (BOOL) addWithDateMethod:(Class) klass;

- (NSString *) withDictionaryPrototype:(NSDictionary *) dictionary;
+ (BOOL) addWithDictionaryMethod:(Class) klass;

- (NSString *) withArrayPrototype:(NSDictionary *) array;
+ (BOOL) addWithArrayMethod:(Class) klass;

- (void) prototypeForEvalJS:(NSString *)javaScriptString
                    handler:(void (^)(id, NSError *))completionHandler;
+ (BOOL) addEvaluateJavaScriptMethod:(Class) klass;

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

+ (Class) lpClassForWKWebView {
  return objc_getClass("WKWebView");
}

+ (LPWKWebViewWebViewProtocolImplementation) implementLPWebViewProtocolOnWKWebView {

  Class LPWKWebViewClass = [[self class] lpClassForWKWebView];
  if (!LPWKWebViewClass) {
    NSLog(@"WKWebView is not available");
    return LPWKWebViewNotAvailable;
  }

  if (![[self class] addLPWebViewProtocol:LPWKWebViewClass]) {
    NSLog(@"Failed to add LPWebViewProtocol to WKWebView");
    return LPWKWebViewFailedToImplementProtocol;
  }

  if (![[self class] addWithDateMethod:LPWKWebViewClass]) {
    NSLog(@"Failed to add lpStringWithDate: to WKWebView");
    return LPWKWebViewFailedToImplementProtocol;
  }

  if (![[self class] addWithDictionaryMethod:LPWKWebViewClass]) {
    NSLog(@"Failed to add lpStringWithDictionary: to WKWebView");
    return LPWKWebViewFailedToImplementProtocol;
  }

  if (![[self class] addWithArrayMethod:LPWKWebViewClass]) {
    NSLog(@"Failed to add lpStringWithArray: to WKWebView");
    return LPWKWebViewFailedToImplementProtocol;
  }

  if (![[self class] addEvaluateJavaScriptMethod:LPWKWebViewClass]) {
    NSLog(@"Failed to add calabashStringByEvaluatingJavaScript: to WKWebView");
    return LPWKWebViewFailedToImplementProtocol;
  }

  NSLog(@"WKWebView successfully implemented LPWebViewProtocol");
  return LPWKWebViewDidImplementProtocol;
}

#pragma mark - Protocol

+ (BOOL) addLPWebViewProtocol:(Class) klass {
  Protocol *lpWebViewProtocol = NSProtocolFromString(@"LPWebViewProtocol");
  return class_addProtocol(klass, lpWebViewProtocol);
}

#pragma mark - lpStringWithDate:

- (NSString *) withDatePrototype:(NSDate *) date {  return @""; }

+ (BOOL) addWithDateMethod:(Class) klass {
  Method method = class_getInstanceMethod([self class],
                                          @selector(withDatePrototype:));
  const char *types = method_getTypeEncoding(method);

  SEL selector = NSSelectorFromString(@"lpStringWithDate:");
  return class_addMethod(klass,
                         selector,
                         (IMP)LPWKWebViewStringWithDateIMP,
                         types);
}

#pragma mark - lpStringWithDictionary:

- (NSString *) withDictionaryPrototype:(NSDictionary *) dictionary {  return @""; }

+ (BOOL) addWithDictionaryMethod:(Class) klass {
  Method method = class_getInstanceMethod([self class],
                                          @selector(withDictionaryPrototype:));
  const char *types = method_getTypeEncoding(method);

  SEL selector = NSSelectorFromString(@"lpStringWithDictionary:");
  return class_addMethod(klass,
                         selector,
                         (IMP)LPWKWebViewStringWithDictionaryIMP,
                         types);
}

#pragma mark - lpStringWithArray:

- (NSString *) withArrayPrototype:(NSDictionary *) dictionary {  return @""; }

+ (BOOL) addWithArrayMethod:(Class) klass {
  Method method = class_getInstanceMethod([self class],
                                          @selector(withArrayPrototype:));
  const char *types = method_getTypeEncoding(method);

  SEL selector = NSSelectorFromString(@"lpStringWithArray:");
  return class_addMethod(klass,
                         selector,
                         (IMP)LPWKWebViewStringWithArrayIMP,
                         types);
}

#pragma mark - calabashStringByEvaluatingJavaScript:

- (void) prototypeForEvalJS:(NSString *)javaScriptString
                    handler:(void (^)(id, NSError *))completionHandler { return; }

+ (BOOL) addEvaluateJavaScriptMethod:(Class) klass {
  return NO;
}

@end

@implementation LPWKWebViewMethodInvoker

+ (NSString *) stringByInvokingSelector:(SEL) selector
                                 target:(id) target
                               argument:(id) argument {
  NSMethodSignature *signature;
  signature = [[target class] instanceMethodSignatureForSelector:selector];

  NSInvocation *invocation;
  invocation = [NSInvocation invocationWithMethodSignature:signature];
  invocation.target = target;
  invocation.selector = selector;

  [invocation setArgument:&argument atIndex:2];
  [invocation retainArguments];

  NSString *result = nil;
  [invocation invoke];
  [invocation getReturnValue:&result];
  return result;
}

@end
