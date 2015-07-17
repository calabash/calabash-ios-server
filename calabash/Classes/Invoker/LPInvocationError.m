#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPInvocationError.h"

NSString *const LPTargetDoesNotRespondToSelector = @"*****";

NSString *const LPCannotCoerceSelectorReturnValueToObject =
@"Error: cannot coerce returned value to an object";

NSString *const LPSelectorHasUnknownReturnTypeEncoding =
@"Error: selector returns an unknown encoding";

NSString *const LPSelectorHasArgumentsWhoseTypeCannotBeHandled =
@"Error: selector has arguments that are not handled";

NSString *const LPIncorrectNumberOfArgumentsProvidedToSelector =
@"Error: incorrect number of arguments provided for selector";

NSString *const LPInvokingSelectorOnTargetRaisedAnException =
@"Error: invoking selector on target raised an exception";

NSString *const LPUnspecifiedInvocationError =
@"Error: invoking selector on target could not be performed";

@interface LPInvocationError ()

- (id) initWithType:(LPInvocationErrorType) type;

@end

@implementation LPInvocationError

@synthesize type = _type;

#pragma mark - Memory Management

- (instancetype) initWithType:(LPInvocationErrorType) type {
  self = [super initWithValue:nil];
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

+ (LPInvocationError *) invokingSelectorOnTargetRaisedAnException {
  return [[LPInvocationError alloc] initWithType:LPInvocationErrorInvokingSelectorOnTargetRaisedAnException];
}

+ (LPInvocationError *) unspecifiedInvocationError {
  return [[LPInvocationError alloc] initWithType:LPInvocationErrorUnspecifiedInvocationError];
}

#pragma mark - State

- (BOOL) isError { return YES; }

- (BOOL) isNSNull { return YES; }

#pragma mark - Description

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

    case LPInvocationErrorInvokingSelectorOnTargetRaisedAnException: {
      return LPInvokingSelectorOnTargetRaisedAnException;
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
