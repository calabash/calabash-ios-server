#import <Foundation/Foundation.h>

extern NSString *const LPTargetDoesNotRespondToSelector;
extern NSString *const LPCannotCoerceSelectorReturnValueToObject;
extern NSString *const LPSelectorHasUnknownReturnTypeEncoding;
extern NSString *const LPSelectorHasArgumentsWhoseTypeCannotBeHandled;
extern NSString *const LPVoidSelectorReturnValue;
extern NSString *const LPUnspecifiedInvocationError;

@interface LPCoercion : NSObject

@property(strong, nonatomic, readonly) id value;
@property(copy, nonatomic, readonly) NSString *failureMessage;

+ (id) coercionWithValue:(id) value;
+ (id) coercionWithFailureMessage:(NSString *) failureMessage;
- (BOOL) wasSuccessful;

@end
