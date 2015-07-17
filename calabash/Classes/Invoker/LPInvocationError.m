#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPInvocationError.h"
#import "LPCocoaLumberjack.h"

NSString *const LPTargetDoesNotRespondToSelector = @"*****";

NSString *const LPCannotCoerceSelectorReturnValueToObject =
@"Error: cannot coerce returned value to an object";

NSString *const LPSelectorHasUnknownReturnTypeEncoding =
@"Error: selector returns an unknown encoding";

NSString *const LPSelectorHasArgumentsWhoseTypeCannotBeHandled =
@"Error: selector has arguments that are not handled";

NSString *const LPIncorrectNumberOfArgumentsProvidedToSelector =
@"Error: incorrect number of arguments provided for selector";

NSString *const LPUnspecifiedInvocationError =
@"Error: invoking selector on target raised an exception";

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

- (NSString *) description {
  switch (self.type) {
    case LPInvocationErrorTargetDoesNotRespondToSelector: {
      return LPTargetDoesNotRespondToSelector;
    }

    case LPInvocationErrorCannotCoerceSelectorReturnValueToObject: {
      return LPCannotCoerceSelectorReturnValueToObject;
    }

    case LPInvocationErrorSelectorHasUnknownReturnTypeEncoding: {
      return LPSelectorHasUnknownReturnTypeEncoding;
    }

    case LPInvocationErrorSelectorHasArgumentsWhoseTypeCannotBeHandled: {
      return LPSelectorHasArgumentsWhoseTypeCannotBeHandled;
    }

    case LPInvocationErrorIncorrectNumberOfArgumentsProvidedToSelector: {
      return LPIncorrectNumberOfArgumentsProvidedToSelector;
    }

    case LPInvocationErrorUnspecifiedInvocationError: {
      return LPUnspecifiedInvocationError;
    }
  }
}

- (NSString *) debugDescription {
  return [self description];
}

@end
