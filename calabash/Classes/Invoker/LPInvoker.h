#import <Foundation/Foundation.h>

@interface LPInvoker : NSObject

@property(assign, nonatomic, readonly) SEL selector;
@property(strong, nonatomic, readonly) id target;

// Designated initializer.
- (id) initWithSelector:(SEL) selector
                 target:(id) target;

// Always returns an object.
+ (id) invokeZeroArgumentSelector:(SEL) selector withTarget:(id) receiver;

- (BOOL) targetRespondsToSelector;
- (NSString *) encoding;
- (BOOL) encodingIsUnhandled;

@end
