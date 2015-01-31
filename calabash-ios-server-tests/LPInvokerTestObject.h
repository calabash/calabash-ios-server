#import <Foundation/Foundation.h>

@interface LPInvokerTestObject : NSObject

@property(strong, nonatomic, readonly) NSObject *object;
@property(strong, nonatomic, readonly) NSNumber *number;
@property(copy, nonatomic, readonly) NSArray *array;
@property(copy, nonatomic, readonly) NSDictionary *dictionary;
@property(strong, nonatomic, readonly) id idType;


- (void) selectorThatReturnsVoid;
- (BOOL) selectorThatReturnsBOOL;
- (NSInteger) selectorThatReturnsNSInteger;
- (CGFloat) selectorThatReturnsCGFloat;
- (char) selectorThatReturnsChar;
- (char *) selectorThatReturnsCharStar;

@end

@interface MyObject : LPInvokerTestObject

@end
