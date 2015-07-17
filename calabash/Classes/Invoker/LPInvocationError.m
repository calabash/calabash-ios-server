#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPInvocationError.h"
#import "LPCocoaLumberjack.h"

@implementation LPInvocationError

@synthesize type = _type;

+ (BOOL) isInvocationError:(id) object {
  return [object isKindOfClass:[LPInvocationError class]];
}

#pragma mark - Memory Management

- (instancetype) initWithType:(LPInvocationErrorType) type {
  self = [super init];
  if (self) {
    _type = type;
  }
  return self;
}

+ (LPInvocationError *) targetDoesNotRespondToSelector {
  return [[LPInvocationError alloc] initWithType:LPInvocationErrorTargetDoesNotRespondToSelector];
}

+ (LPInvocationError *) cannotCoerceReturnValueToObject {
  return [[LPInvocationError alloc] initWithType:LPInvocationErrorCannotCoerceSelectorReturnValueToObject];
}

+ (LPInvocationError *) hasUnknownReturnTypeEncoding {
  return [[LPInvocationError alloc] initWithType:LPInvocationErrorSelectorHasUnknownReturnTypeEncoding];
}

+ (LPInvocationError *) hasAnArgumentTypeEncodingThatCannotBeHandled {
  return [[LPInvocationError alloc] initWithType:LPInvocationErrorSelectorHasArgumentsWhoseTypeCannotBeHandled];
}

+ (LPInvocationError *) incorectNumberOfArgumentsProvided {
  return [[LPInvocationError alloc] initWithType:LPInvocationErrorIncorrectNumberOfArgumentsProvidedToSelector];
}

+ (LPInvocationError *) unspecifiedInvocationError {
  return [[LPInvocationError alloc] initWithType:LPInvocationErrorUnspecifiedInvocationError];
}

@end
