#import <Foundation/Foundation.h>
#import "LPCocoaLumberjack.h"

typedef enum : NSUInteger {
  LPInvocationErrorTargetDoesNotRespondToSelector = 0,
  LPInvocationErrorCannotCoerceSelectorReturnValueToObject,
  LPInvocationErrorSelectorHasUnknownReturnTypeEncoding,
  LPInvocationErrorSelectorHasArgumentsWhoseTypeCannotBeHandled,
  LPInvocationErrorIncorrectNumberOfArgumentsProvidedToSelector,
  LPInvocationErrorUnspecifiedInvocationError
} LPInvocationErrorType;

@interface LPInvocationError : NSObject

@property(nonatomic, assign, readonly) LPInvocationErrorType type;

+ (BOOL) isInvocationError:(id) object;

- (instancetype) initWithType:(LPInvocationErrorType) type;

+ (LPInvocationError *) targetDoesNotRespondToSelector;
+ (LPInvocationError *) cannotCoerceReturnValueToObject;
+ (LPInvocationError *) hasUnknownReturnTypeEncoding;
+ (LPInvocationError *) hasAnArgumentTypeEncodingThatCannotBeHandled;
+ (LPInvocationError *) incorectNumberOfArgumentsProvided;
+ (LPInvocationError *) unspecifiedInvocationError;

@end
