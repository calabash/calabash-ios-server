#import <Foundation/Foundation.h>

@interface LPDecimalRounder : NSObject

- (CGFloat)round:(CGFloat)cgFloat;
- (CGFloat)round:(CGFloat)cgFloat withScale:(NSUInteger)scale;

@end
