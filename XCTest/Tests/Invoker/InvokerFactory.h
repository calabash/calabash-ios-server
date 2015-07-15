#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <CoreLocation/CoreLocation.h>

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
+ (LPInvoker *) invokerWithArgmentValue:(NSString *) key;

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
- (CLLocationCoordinate2D) selectorThatReturnsCoreLocation2D;

// Handled

- (BOOL) selectorBOOL_YES:(BOOL) arg;
- (BOOL) selectorBOOL_NO:(BOOL) arg;
- (BOOL) selectorBool_true:(bool) arg;
- (BOOL) selectorBool_false:(bool) arg;
- (BOOL) selectorNSInteger:(NSInteger) arg;
- (BOOL) selectorNSUInteger:(NSUInteger) arg;
- (BOOL) selectorShort:(short) arg;
- (BOOL) selectorUnsignedShort:(unsigned short) arg;
- (BOOL) selectorCGFloat:(CGFloat) arg;
- (BOOL) selectorDouble:(double) arg;
- (BOOL) selectorFloat:(float) arg;
- (BOOL) selectorChar:(char) arg;
- (BOOL) selectorCharStar:(char *) arg;
- (BOOL) selectorConstCharStar:(const char *) arg;
- (BOOL) selectorUnsignedChar:(unsigned char) arg;
- (BOOL) selectorLong:(long) arg;
- (BOOL) selectorUnsignedLong:(unsigned long) arg;
- (BOOL) selectorLongLong:(long long) arg;
- (BOOL) selectorUnsignedLongLong:(unsigned long long) arg;
- (BOOL) selectorCGPoint:(CGPoint) arg;
- (BOOL) selectorCGRect:(CGRect) arg;
- (BOOL) selectorClass:(Class) arg;
- (BOOL) selectorObjectPointer:(id) arg;

// Not Handled

- (void) selectorVoidStar:(void *) arg;
- (void) selectorFloatStar:(float *) arg;
- (BOOL) selectorObjectStarStar:(NSError *__autoreleasing*) arg;
- (void) selectorSelector:(SEL) arg;
- (void) selectorPrimativeArray:(int []) arg;
- (void) selectorStruct:(InvokerFactoryStruct) arg;
// TODO: Unions throw:
// "+[NSMethodSignature signatureWithObjCTypes:]: unsupported type encoding spec
//  '(' in '8(InvokerUnion=di)16'"
// TODO: Function pointer
// TODO: Bitfield

@end
