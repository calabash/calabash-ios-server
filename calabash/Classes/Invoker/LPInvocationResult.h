#import <Foundation/Foundation.h>

extern NSString *const LPVoidSelectorReturnValue;

@interface LPInvocationResult : NSObject

@property(nonatomic, strong, readonly) id value;

+ (LPInvocationResult *) resultWithValue:(id) value;
- (id) initWithValue:(id) value;

- (BOOL) isError;
- (BOOL) isNSNull;

@end
