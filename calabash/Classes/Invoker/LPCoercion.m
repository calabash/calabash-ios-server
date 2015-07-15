#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPCoercion.h"

NSString *const LPTargetDoesNotRespondToSelector = @"*****";

NSString *const LPCannotCoerceSelectorReturnValueToObject =
@"Error: cannot coerce returned value to an object";

NSString *const LPSelectorHasUnknownReturnTypeEncoding =
@"Error: selector returns an unknown encoding";

NSString *const LPSelectorHasArgumentsWhoseTypeCannotBeHandled =
@"Error: selector has arguments that are not handled";

NSString *const LPVoidSelectorReturnValue = @"<VOID>";
NSString *const LPUnspecifiedInvocationError =
@"Error: invoking selector on target raised an exception";

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
  if (self.value) {
    return YES;
  } else {
    return NO;
  }
}

@end
