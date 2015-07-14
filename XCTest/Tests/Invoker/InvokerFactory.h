#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@class Target;
@class LPInvoker;

typedef struct InvokerFactoryStruct InvokerFactoryStruct;
struct InvokerFactoryStruct {
   NSUInteger pillar;
};

@interface InvokerFactory : NSObject

+ (InvokerFactory *) shared;
+ (Target *) targetWithSelectorReturnValue:(NSString *) key;
+ (LPInvoker *) invokerWithSelectorReturnValue:(NSString *) key;

@end

@interface Target : NSObject

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
- (CGPoint) selectorThatReturnsCGPoint;
- (CGRect) selectorThatReturnsCGRect;
- (InvokerFactoryStruct) selectorThatReturnsAStruct;
- (Class) selectorThatReturnsClass;

@end
