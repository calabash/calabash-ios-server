#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPWKWebViewRuntimeLoader.h"
#import "LPJSONUtils.h"
#import "LPWebViewProtocol.h"
#import <objc/runtime.h>
#import "LPCocoaLumberjack.h"

NSString *const LPWKWebViewISO8601DateFormat = @"yyyy-MM-dd HH:mm:ss Z";

@interface LPWKWebViewRuntimeLoader ()

+ (LPWKWebViewWebViewProtocolImplementation) implementLPWebViewProtocolOnWKWebView;

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

- (id) init_private;

- (void) setState:(LPWKWebViewWebViewProtocolImplementation) newState;

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
                                                                    NSString *javascript) {
  __block id objectFromBlock = nil;
  __block BOOL finish = NO;

  void (^completionHandler)(id result, NSError *error) = ^void(id result, NSError *error) {
    if (error) {
      NSString *localizedDescription = [error localizedDescription];
      LPLogError(@"Error evaluating JavaScript: '%@'", javascript);
      LPLogError(@"Error was: '%@'", localizedDescription);
      NSDictionary *errorDict =
      @{
        @"error" : localizedDescription ? localizedDescription : [NSNull null],
        @"javascript" : javascript ? javascript : [NSNull null]
        };
      objectFromBlock = [[LPJSONUtils serializeDictionary:errorDict] copy];
    } else {
      objectFromBlock = [result copy];
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

  // Unexpected behavior.
  //
  // We are invoking 'evaluateJavaScript:completionHandler' which is an async
  // method.  We should use 'waitUntilDone:YES', but we should _not_ expect
  // that the blocking while loop will be skipped.
  //
  // Put another way, 'evaluationJavaScript:completionHandler' is
  // fire-and-forget regardless of whether we pass YES or NO to waitUntilDone.
  [invocation performSelectorOnMainThread:@selector(invokeWithTarget:)
                               withObject:self
                            waitUntilDone:YES];

  while(!finish) {
    [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
  }

  NSString *returnValue = nil;
  objectFromBlock = [objectFromBlock copy];

  if (!objectFromBlock || objectFromBlock == [NSNull null]) {
    returnValue = @"";
  } else if ([objectFromBlock isKindOfClass:[NSString class]]) {
    returnValue = objectFromBlock;
  } else if ([objectFromBlock isKindOfClass:[NSDate class]]) {
    SEL selector = NSSelectorFromString(@"lpStringWithDate:");
    returnValue = [LPWKWebViewMethodInvoker stringByInvokingSelector:selector
                                                              target:self
                                                            argument:objectFromBlock];
  } else if ([objectFromBlock isKindOfClass:[NSDictionary class]]) {
    SEL selector = NSSelectorFromString(@"lpStringWithDictionary:");
    returnValue = [LPWKWebViewMethodInvoker stringByInvokingSelector:selector
                                                              target:self
                                                            argument:objectFromBlock];
  } else if ([objectFromBlock isKindOfClass:[NSArray class]]) {
    SEL selector = NSSelectorFromString(@"lpStringWithArray:");
    returnValue = [LPWKWebViewMethodInvoker stringByInvokingSelector:selector
                                                              target:self
                                                            argument:objectFromBlock];
  } else {
    SEL stringValueSel = @selector(stringValue);
    if ([objectFromBlock respondsToSelector:stringValueSel]) {
      returnValue = [objectFromBlock stringValue];
    } else {
      returnValue = [objectFromBlock description];
    }
  }
  return returnValue;
}

@implementation LPWKWebViewRuntimeLoader

#pragma mark - Testing Only

- (void) setState:(LPWKWebViewWebViewProtocolImplementation) newState {
  _state = newState;
}

#pragma mark - Singleton Pattern

- (id) init {
  @throw [NSException exceptionWithName:@"Singleton Pattern"
                                 reason:[NSString stringWithFormat:@"%@ does not respond to 'init' selector",
                                         [self class]]
                               userInfo:nil];
}

- (id) init_private {
  self = [super init];
  if (self) {
    _state = LPWKWebViewHaveNotTriedToImplementProtocol;
  }
  return self;
}

+ (LPWKWebViewRuntimeLoader *) shared {
  static LPWKWebViewRuntimeLoader *sharedLoader = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedLoader = [[LPWKWebViewRuntimeLoader alloc] init_private];
  });
  return sharedLoader;
}

- (LPWKWebViewWebViewProtocolImplementation) loadImplementation {
  if (self.state == LPWKWebViewHaveNotTriedToImplementProtocol) {
    [self setState:[[self class] implementLPWebViewProtocolOnWKWebView]];
  } else {
    LPLogError(@"Tried to load WKWebView LPWebViewProtocl implemention again; not allowed");
  }
  return self.state;
}

+ (Class) lpClassForWKWebView {
  return objc_getClass("WKWebView");
}

+ (LPWKWebViewWebViewProtocolImplementation) implementLPWebViewProtocolOnWKWebView {

  Class LPWKWebViewClass = [[self class] lpClassForWKWebView];
  if (!LPWKWebViewClass) {
    LPLogDebug(@"WKWebView is not available");
    return LPWKWebViewNotAvailable;
  }

  if (![[self class] addLPWebViewProtocol:LPWKWebViewClass]) {
    LPLogError(@"Failed to add LPWebViewProtocol to WKWebView");
    return LPWKWebViewFailedToImplementProtocol;
  }

  if (![[self class] addWithDateMethod:LPWKWebViewClass]) {
    LPLogError(@"Failed to add lpStringWithDate: to WKWebView");
    return LPWKWebViewFailedToImplementProtocol;
  }

  if (![[self class] addWithDictionaryMethod:LPWKWebViewClass]) {
    LPLogError(@"Failed to add lpStringWithDictionary: to WKWebView");
    return LPWKWebViewFailedToImplementProtocol;
  }

  if (![[self class] addWithArrayMethod:LPWKWebViewClass]) {
    LPLogError(@"Failed to add lpStringWithArray: to WKWebView");
    return LPWKWebViewFailedToImplementProtocol;
  }

  if (![[self class] addEvaluateJavaScriptMethod:LPWKWebViewClass]) {
    LPLogError(@"Failed to add calabashStringByEvaluatingJavaScript: to WKWebView");
    return LPWKWebViewFailedToImplementProtocol;
  }

  LPLogDebug(@"WKWebView successfully implemented LPWebViewProtocol");
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

  void *buffer;
  [invocation invoke];
  [invocation getReturnValue:&buffer];

  NSString *result = (__bridge NSString *)buffer;
  return result;
}

@end
