#import <Foundation/Foundation.h>

extern NSString *const LPReceiverDoesNotRespondToSelectorEncoding;

@interface LPInvoker : NSObject

@property(assign, nonatomic, readonly) SEL selector;
@property(strong, nonatomic, readonly) id receiver;

// Designated initializer.
- (id) initWithSelector:(SEL) selector
               receiver:(id) receiver;

+ (id) invokeSelector:(SEL) selector receiver:(id) receiver;

- (BOOL) receiverRespondsToSelector;
- (NSString *) encoding;
- (BOOL) encodingIsUnhandled;

@end
