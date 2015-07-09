#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPCoercion.h"

NSString *const LPTargetDoesNotRespondToSelector = @"*****";
NSString *const LPVoidSelectorReturnValue = @"*selector returns void*";
NSString *const LPSelectorHasUnhandledEncoding = @"*selector returns unhandled encoding*";
NSString *const LPSelectorHasUnhandledArguments = @"*unhandled selector arguments*";
NSString *const LPCannotCoerceSelectorReturnValueToObject = @"*cannot coerce to object*";
NSString *const LPSelectorHasUnknownEncoding = @"*unknown encoding*";
NSString *const LPUnspecifiedInvocationError = @"*invocation error*";

@interface LPCoercion ()

- (id) initWithValue:(id) value
      failureMessage:(NSString *) failureMessage;

@end

@implementation LPCoercion

- (id) initWithValue:(id) value
      failureMessage:(NSString *) failureMessage {
  self = [super init];
  if (self) {
    _value = value;
    _failureMessage = failureMessage;
  };
  return self;
}

+ (id) coercionWithValue:(id) value {
  return [[LPCoercion alloc] initWithValue:value failureMessage:nil];
}

+ (id) coercionWithFailureMessage:(NSString *) failureMessage {
  return [[LPCoercion alloc] initWithValue:nil failureMessage:failureMessage];
}

- (BOOL) wasSuccessful {
  if (self) {
    return YES;
  } else {
    return NO;
  }
}

@end
