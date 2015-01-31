#import <Foundation/Foundation.h>

extern NSString *const LPTargetDoesNotRespondToSelector;
extern NSString *const LPVoidSelectorReturnValue;
extern NSString *const LPSelectorHasUnhandledEncoding;
extern NSString *const LPSelectorHasUnhandledArguments;
extern NSString *const LPCannotCoerceSelectorReturnValueToObject;
extern NSString *const LPSelectorHasUnknownEncoding;
extern NSString *const LPUnspecifiedInvocationError;

@interface LPInvoker : NSObject

@property(assign, nonatomic, readonly) SEL selector;
@property(strong, nonatomic, readonly) id target;

// Designated initializer.
- (id) initWithSelector:(SEL) selector
                 target:(id) target;

// Always returns an object.
+ (id) invokeSelector:(SEL) selector withTarget:(id) receiver;

- (BOOL) targetRespondsToSelector;
- (NSString *) encoding;
- (BOOL) encodingIsUnhandled;

@end
