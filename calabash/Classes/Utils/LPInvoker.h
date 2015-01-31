#import <Foundation/Foundation.h>

extern NSString *const LPReceiverDoesNotRespondToSelector;
extern NSString *const LPVoidSelectorReturnValue;
extern NSString *const LPSelectorHasUnhandledEncoding;
extern NSString *const LPSelectorHasUnhandledArguments;
extern NSString *const LPCannotCoerceSelectorReturnValueToObject;
extern NSString *const LPSelectorHasUnknownEncoding;
extern NSString *const LPUnspecifiedInvocationError;

@interface LPInvoker : NSObject

@property(assign, nonatomic, readonly) SEL selector;
@property(strong, nonatomic, readonly) id receiver;

// Designated initializer.
- (id) initWithSelector:(SEL) selector
               receiver:(id) receiver;

// Always returns an object.
+ (id) objectForSelector:(SEL) selector sentToReceiver:(id) receiver;

- (BOOL) receiverRespondsToSelector;
- (NSString *) encoding;
- (BOOL) encodingIsUnhandled;

@end
