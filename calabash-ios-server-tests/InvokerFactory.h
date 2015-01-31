#import <Foundation/Foundation.h>

@class Receiver;
@class LPInvoker;

@interface InvokerFactory : NSObject

+ (InvokerFactory *) shared;
+ (Receiver *) receiverWithSelectorReturnValue:(NSString *) key;
+ (LPInvoker *) invokerWithSelectorReturnValue:(NSString *) key;

@end

@interface Receiver : NSObject

@property(assign, nonatomic) SEL selector;
@property(strong, nonatomic, readonly) NSObject *object;
@property(strong, nonatomic, readonly) NSNumber *number;
@property(copy, nonatomic, readonly) NSArray *array;
@property(copy, nonatomic, readonly) NSDictionary *dictionary;
@property(strong, nonatomic, readonly) id idType;

- (void) selectorThatReturnsVoid;
- (BOOL) selectorThatReturnsBOOL_YES;
- (BOOL) selectorThatReturnsBOOL_NO;
- (bool) selectorThatReturnsBool_true;
- (bool) selectorThatReturnsBool_false;
- (NSInteger) selectorThatReturnsNSInteger;
- (NSInteger) selectorThatReturnsNSUInteger;
- (short) selectorThatReturnsShort;
- (unsigned short) selectorThatReturnsUnsignedShort;
- (CGFloat) selectorThatReturnsCGFloat;
- (double) selectorThatReturnsDouble;
- (float) selectorThatReturnsFloat;
- (char) selectorThatReturnsChar;
- (char *) selectorThatReturnsCharStar;
- (const char *) selectorThatReturnsConstCharStar;
- (unsigned char) selectorThatReturnsUnsignedChar;
- (long) selectorThatReturnsLong;
- (unsigned long) selectorThatReturnsUnsignedLong;
- (long long) selectorThatReturnsLongLong;
- (unsigned long long) selectorThatReturnsUnsignedLongLong;

@end
