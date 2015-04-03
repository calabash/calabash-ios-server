#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPRuntimeWKWebView.h"
#import "LPJSONUtils.h"
#import "LPWebViewProtocol.h"
#import <objc/runtime.h>

NSString *const LPWKWebViewISO8601DateFormat = @"yyyy-MM-dd HH:mm:ss Z";

@interface LPRuntimeWKWebView ()

+ (Class) lpClassForWKWebView;

+ (BOOL) addLPWebViewProtocol:(Class) klass;

- (NSString *) withDatePrototype:(NSDate *) date;
+ (BOOL) addWithDateMethod:(Class) klass;

- (NSString *) withDictionaryPrototype:(NSDictionary *) dictionary;
+ (BOOL) addWithDictionaryMethod:(Class) klass;

- (NSString *) withArrayPrototype:(NSDictionary *) array;
+ (BOOL) addWithArrayMethod:(Class) klass;

- (NSString *) prototypeForEvalJS:(NSString *)js;
+ (BOOL) addEvaluateJavaScriptMethod:(Class) klass;

@end

static NSString *LPWKWebViewStringWithDateIMP(id self, SEL _cmd, NSDate *date) {
  NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
  [formatter setDateFormat:LPWKWebViewISO8601DateFormat];
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

static NSString *LPWKWebViewCalabashStringByEvaluatingJavaScriptIMP(id self,
                                                                    SEL _cmd,
                                                                    NSString
                                                                    *javascript) {
  __block id res = nil;
  __block BOOL finish = NO;

  void (^completionHandler)(id result, NSError *error) = ^void(id result, NSError *error) {
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
  };

  SEL evalSelector = NSSelectorFromString(@"evaluateJavaScript:completionHandler:");
  NSMethodSignature *signature;
  signature = [[self class] instanceMethodSignatureForSelector:evalSelector];

  NSInvocation *invocation;
  invocation = [NSInvocation invocationWithMethodSignature:signature];
  invocation.target = self;
  invocation.selector = evalSelector;

  [invocation setArgument:&javascript atIndex:2];
  [invocation setArgument:&completionHandler atIndex:3];
  [invocation retainArguments];
  [invocation invoke];

  while(!finish) {
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
  }

  if (!res) { return @""; }
  if (res == [NSNull null]) { return @""; }
  if ([res isKindOfClass:[NSString class]]) { return res; }

  if ([res isKindOfClass:[NSDate class]]) {
    SEL selector = NSSelectorFromString(@"lpStringWithDate:");
    return [LPWKWebViewMethodInvoker stringByInvokingSelector:selector
                                                       target:self
                                                     argument:res];
  } else if ([res isKindOfClass:[NSDictionary class]]) {
    SEL selector = NSSelectorFromString(@"lpStringWithDictionary:");
    return [LPWKWebViewMethodInvoker stringByInvokingSelector:selector
                                                       target:self
                                                     argument:res];
  } else if ([res isKindOfClass:[NSArray class]]) {
    SEL selector = NSSelectorFromString(@"lpStringWithArray:");
    return [LPWKWebViewMethodInvoker stringByInvokingSelector:selector
                                                       target:self
                                                     argument:res];
  } else {
    SEL stringValueSel = @selector(stringValue);
    if ([res respondsToSelector:stringValueSel]) {  return [res stringValue]; }
  }
  return [res description];
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

- (NSString *) prototypeForEvalJS:(NSString *)js { return @""; }

+ (BOOL) addEvaluateJavaScriptMethod:(Class) klass {
  Method method = class_getInstanceMethod([self class],
                                          @selector(prototypeForEvalJS:));
  const char *types = method_getTypeEncoding(method);

  SEL selector = NSSelectorFromString(@"calabashStringByEvaluatingJavaScript:");
  return class_addMethod(klass,
                         selector,
                         (IMP)LPWKWebViewCalabashStringByEvaluatingJavaScriptIMP,
                         types);
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
