#import <Foundation/Foundation.h>
#import "LPInvocationResult.h"

extern NSString *const LPTargetDoesNotRespondToSelector;
extern NSString *const LPCannotCoerceSelectorReturnValueToObject;
extern NSString *const LPSelectorHasUnknownReturnTypeEncoding;
extern NSString *const LPSelectorHasArgumentsWhoseTypeCannotBeHandled;
extern NSString *const LPIncorrectNumberOfArgumentsProvidedToSelector;
extern NSString *const LPUnspecifiedInvocationError;

typedef enum : NSUInteger {
  LPInvocationErrorTargetDoesNotRespondToSelector = 0,
  LPInvocationErrorCannotCoerceSelectorReturnValueToObject,
  LPInvocationErrorSelectorHasUnknownReturnTypeEncoding,
  LPInvocationErrorSelectorHasArgumentsWhoseTypeCannotBeHandled,
  LPInvocationErrorIncorrectNumberOfArgumentsProvidedToSelector,
  LPInvocationErrorUnspecifiedInvocationError
} LPInvocationErrorType;

@interface LPInvocationError : LPInvocationResult

@property(nonatomic, assign, readonly) LPInvocationErrorType type;

- (instancetype) initWithType:(LPInvocationErrorType) type;

+ (LPInvocationError *) targetDoesNotRespondToSelector;
+ (LPInvocationError *) cannotCoerceReturnValueToObject;
+ (LPInvocationError *) hasUnknownReturnTypeEncoding;
+ (LPInvocationError *) hasAnArgumentTypeEncodingThatCannotBeHandled;
+ (LPInvocationError *) incorectNumberOfArgumentsProvided;
+ (LPInvocationError *) unspecifiedInvocationError;

@end
