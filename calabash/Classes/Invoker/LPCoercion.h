#import <Foundation/Foundation.h>

@interface LPCoercion : NSObject

@property(strong, nonatomic, readonly) id value;
@property(copy, nonatomic, readonly) NSString *failureMessage;

+ (id) coercionWithValue:(id) value;
+ (id) coercionWithFailureMessage:(NSString *) failureMessage;
- (BOOL) wasSuccessful;

@end
