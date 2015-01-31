#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "LPInvoker.h"
#import <OCMock/OCMock.h>
#import "InvokerFactory.h"
#import <objc/runtime.h>

@interface NSString (LPXCTTEST)

- (id) returnsNil;

@end

@implementation NSString (LPXCTTEST)

- (id) returnsNil {
  return nil;
}

@end

@interface LPInvoker (LPXCTTEST)

- (NSInvocation *) invocation;
- (NSMethodSignature *) signature;
- (BOOL) selectorReturnsObject;
- (BOOL) selectorReturnsVoid;
- (BOOL) selectorReturnValueCanBeCoerced;
- (id) objectByCoercingReturnValue;
- (NSUInteger) numberOfArguments;
- (BOOL) selectorHasArguments;

@end

@interface LPInvokerTest : XCTestCase

@property (assign) Method originalEncodingMethod;
@property (assign) Method swizzledEncodingMethod;

- (void) swizzleEncodingWithNewSelector:(SEL) newSelector;
- (void) unswizzleEncoding;
- (NSString *) encodingSwizzledToVoid;
- (NSString *) encodingSwizzledToUnknown;

@end

@implementation LPInvokerTest

- (void)setUp {
  [super setUp];
  self.originalEncodingMethod = class_getInstanceMethod([LPInvoker class],
                                                        @selector(encoding));
}

- (void)tearDown {
  [super tearDown];
}

#pragma mark - Playground

- (void) testCannotInitInvokerFactory {
  XCTAssertThrows([InvokerFactory new]);
}

#pragma mark - Swizzling

- (NSString *) encodingSwizzledToVoid {
  return @(@encode(void));
}

- (NSString *) encodingSwizzledToUnknown {
  return @"?";
}

- (void) swizzleEncodingWithNewSelector:(SEL) newSelector {
  self.swizzledEncodingMethod  = class_getInstanceMethod([self class],
                                                         newSelector);
  method_exchangeImplementations(self.originalEncodingMethod,
                                 self.swizzledEncodingMethod);
}

- (void) unswizzleEncoding {
  method_exchangeImplementations(self.swizzledEncodingMethod,
                                 self.originalEncodingMethod);
}

#pragma mark - Mocking

- (id) expectInvokerEncoding:(NSString *) mockEncoding {
  LPInvoker *invoker = [[LPInvoker alloc] initWithSelector:@selector(length)
                                                    target:@"string"];
  id mock = [OCMockObject partialMockForObject:invoker];
  [[[mock expect] andReturn:mockEncoding] encoding];
  return mock;
}

- (id) stubInvokerEncoding:(NSString *) mockEncoding {
  LPInvoker *invoker = [[LPInvoker alloc] initWithSelector:@selector(length)
                                                    target:@"string"];
  id mock = [OCMockObject partialMockForObject:invoker];
  [[[mock stub] andReturn:mockEncoding] encoding];
  return mock;
}

- (id) stubInvokerDoesNotRespondToSelector {
  LPInvoker *invoker = [[LPInvoker alloc] initWithSelector:@selector(length)
                                                    target:@"string"];
  id mock = [OCMockObject partialMockForObject:invoker];
  BOOL falsey = NO;
  [[[mock stub] andReturnValue:OCMOCK_VALUE(falsey)] targetRespondsToSelector];
  return mock;
}

#pragma mark - init

- (void) testInitThrowsException {
  XCTAssertThrows([LPInvoker new]);
}

#pragma mark - initWithSelector:target

- (void) testDesignatedInitializer {
  NSString *target = @"string";
  SEL selector = @selector(length);
  LPInvoker *invoker = [[LPInvoker alloc] initWithSelector:selector
                                                    target:target];
  XCTAssertEqual(invoker.selector, selector);
  XCTAssertEqualObjects(invoker.target, target);
}

#pragma mark - LPInvoker invokeSelector:withTarget:

- (void) objectBySafelyInvokingSelectorSelectorHasArguments {
  NSString *target = @"string";
  SEL selector = @selector(substringToIndex:);
  id actual = [LPInvoker invokeSelector:selector withTarget:target];
  XCTAssertEqualObjects(actual, LPSelectorHasUnhandledArguments);
}

- (void) objectBySafelyInvokingSelectorDNRS {
  NSString *target = @"string";
  SEL selector = NSSelectorFromString(@"obviouslyUnknownSelector");
  id actual = [LPInvoker invokeSelector:selector withTarget:target];
  XCTAssertEqualObjects(actual, LPTargetDoesNotRespondToSelector);
}

- (void) objectBySafelyInvokingSelectorVoid {
  NSString *target = @"string";
  SEL selector = @selector(length);
  @try {
    [self swizzleEncodingWithNewSelector:@selector(encodingSwizzledToVoid)];
    id actual = [LPInvoker invokeSelector:selector withTarget:target];
    XCTAssertEqualObjects(actual, LPVoidSelectorReturnValue);
  } @finally {
    [self unswizzleEncoding];
  }
}

- (void) objectBySafelyInvokingSelectorUnknown {
  NSString *target = @"string";
  SEL selector = @selector(length);
  @try {
    [self swizzleEncodingWithNewSelector:@selector(encodingSwizzledToUnknown)];
    id actual = [LPInvoker invokeSelector:selector withTarget:target];
    XCTAssertEqualObjects(actual, LPSelectorHasUnhandledEncoding);
  } @finally {
    [self unswizzleEncoding];
  }
}

- (void) objectBySafelyInvokingSelectorObject {
  NSString *target = @"target";
  SEL selector = @selector(description);
  id actual = [LPInvoker invokeSelector:selector withTarget:target];
  XCTAssertEqualObjects(actual, target);
}

- (void) objectBySafelyInvokingSelectorNil {
  NSString *target = @"string";
  SEL selector = @selector(returnsNil);
  id actual = [LPInvoker invokeSelector:selector withTarget:target];
  XCTAssertEqual(actual, [NSNull null]);
}

- (void) objectBySafelyInvokingSelectorCoerced {
  NSString *target = @"string";
  SEL selector = @selector(length);
  id actual = [LPInvoker invokeSelector:selector withTarget:target];
  XCTAssertEqual([actual unsignedIntegerValue], target.length);
}

#pragma mark - invocation

- (void) testInvocationRS {
  NSString *target = @"string";
  SEL selector = @selector(length);
  LPInvoker *invoker = [[LPInvoker alloc] initWithSelector:selector
                                                    target:target];
  NSInvocation *invocation = [invoker invocation];
  XCTAssertEqual(invocation.selector, selector);
  XCTAssertEqualObjects(invocation.target, target);
}

- (void) testInvocationDNRS {
  NSString *target = @"string";
  SEL selector = NSSelectorFromString(@"obviouslyUnknownSelector");
  LPInvoker *invoker = [[LPInvoker alloc] initWithSelector:selector
                                                    target:target];
  NSInvocation *invocation = [invoker invocation];
  XCTAssertNil(invocation);
}

#pragma mark - signature

- (void) testSignatureRS {
  NSString *target = @"string";
  SEL selector = @selector(length);
  LPInvoker *invoker = [[LPInvoker alloc] initWithSelector:selector
                                                    target:target];
  XCTAssertNotNil([invoker signature]);
}

- (void) testSignatureDNRS {
  NSString *target = @"string";
  SEL selector = NSSelectorFromString(@"obviouslyUnknownSelector");
  LPInvoker *invoker = [[LPInvoker alloc] initWithSelector:selector
                                                    target:target];
  XCTAssertNil([invoker signature]);
}

#pragma mark - description

- (void) testDescription {
  NSString *target = @"string";
  SEL selector = @selector(length);
  LPInvoker *invoker = [[LPInvoker alloc] initWithSelector:selector
                                                    target:target];
  XCTAssertNoThrow([invoker description]);
  XCTAssertNoThrow([invoker debugDescription]);
}

#pragma mark - targetRespondsToSelector

- (void) testtargetRespondsToSelectorYES {
  NSString *target = @"string";
  SEL selector = @selector(length);
  LPInvoker *invoker = [[LPInvoker alloc] initWithSelector:selector
                                                    target:target];
  XCTAssertTrue([invoker targetRespondsToSelector]);
}

- (void) testtargetRespondsToSelectorNO {
  NSString *target = @"string";
  SEL selector = NSSelectorFromString(@"obviouslyUnknownSelector");
  LPInvoker *invoker = [[LPInvoker alloc] initWithSelector:selector
                                                    target:target];
  XCTAssertFalse([invoker targetRespondsToSelector]);
}

#pragma mark - encoding

- (void) testEncoding {
  NSString *target = @"string";
  SEL selector = @selector(length);
  LPInvoker *invoker = [[LPInvoker alloc] initWithSelector:selector
                                                    target:target];
  NSString *actual = [invoker encoding];
  XCTAssertEqualObjects(actual, @"I");
}

- (void) testEncodingDoesNotRespondToSelector {
  NSString *target = @"string";
  SEL selector = NSSelectorFromString(@"obviouslyUnknownSelector");
  LPInvoker *invoker = [[LPInvoker alloc] initWithSelector:selector
                                                    target:target];
  NSString *actual = [invoker encoding];
  XCTAssertEqualObjects(actual, LPTargetDoesNotRespondToSelector);
}

#pragma mark - numberOfArguments

/*
 Mocking does not work; infinite loop on forwardSelector
 */

- (void) testNumberOfArguments0 {
  NSString *target = @"string";
  SEL selector = @selector(length);
  LPInvoker *invoker = [[LPInvoker alloc] initWithSelector:selector
                                                    target:target];
  XCTAssertEqual([invoker numberOfArguments], 0);
}

- (void) testNumberOfArguments1 {
  NSString *target = @"string";
  SEL selector = @selector(substringToIndex:);
  LPInvoker *invoker = [[LPInvoker alloc] initWithSelector:selector
                                                    target:target];
  XCTAssertEqual([invoker numberOfArguments], 1);
}

#pragma mark - selectorHasArguments

- (void) testSelectorHasArgumentsNO {
  NSString *target = @"string";
  SEL selector = @selector(length);
  LPInvoker *invoker = [[LPInvoker alloc] initWithSelector:selector
                                                    target:target];
  XCTAssertEqual([invoker selectorHasArguments], NO);
}

- (void) testSelectorHasArgumentsYES {
  NSString *target = @"string";
  SEL selector = @selector(substringToIndex:);
  LPInvoker *invoker = [[LPInvoker alloc] initWithSelector:selector
                                                    target:target];
  XCTAssertEqual([invoker selectorHasArguments], YES);
}

#pragma mark - encodingIsUnhandled

- (void) testUnhandledEncodingVoidStar {
  NSString *encoding = @(@encode(void *));
  id mock = [self expectInvokerEncoding:encoding];
  XCTAssertTrue([mock encodingIsUnhandled]);
  [mock verify];
}

- (void) testUnhandledEncodingTypeStar {
  NSString *encoding = @(@encode(float *));
  id mock = [self expectInvokerEncoding:encoding];
  XCTAssertTrue([mock encodingIsUnhandled]);
  [mock verify];
}

- (void) testUnhandledEncodingNSObjectStarStar {
  NSString *encoding = @(@encode(typeof(NSObject **)));
  id mock = [self expectInvokerEncoding:encoding];
  XCTAssertTrue([mock encodingIsUnhandled]);
  [mock verify];
}

- (void) testUnhandledEncodingClassObject {
  NSString *encoding = @(@encode(typeof(NSObject)));
  id mock = [self expectInvokerEncoding:encoding];
  XCTAssertTrue([mock encodingIsUnhandled]);
  [mock verify];
}

- (void) testUnhandledEncodingClassInstance {
  NSString *encoding = @(@encode(typeof(NSObject)));
  id mock = [self expectInvokerEncoding:encoding];
  XCTAssertTrue([mock encodingIsUnhandled]);
  [mock verify];
}

- (void) testUnhandledEncodingStruct {
  typedef struct _struct {
    short a;
    long long b;
    unsigned long long c;
  } Struct;
  NSString *encoding = @(@encode(typeof(Struct)));
  id mock = [self expectInvokerEncoding:encoding];
  XCTAssertTrue([mock encodingIsUnhandled]);
  [mock verify];
}

- (void) testUnhandledEncodingCArray {
  int arr[5] = {1, 2, 3, 4, 5};
  NSString *encoding = @(@encode(typeof(arr)));
  id mock = [self expectInvokerEncoding:encoding];
  XCTAssertTrue([mock encodingIsUnhandled]);
  [mock verify];
}

- (void) testUnhandledEncodingSelector {
  NSString *encoding = @(@encode(typeof(@selector(length))));
  id mock = [self expectInvokerEncoding:encoding];
  XCTAssertTrue([mock encodingIsUnhandled]);
  [mock verify];
}

- (void) testUnhandledEncodingUnion {

  typedef union _myunion {
    double PI;
    int B;
  } MyUnion;

  NSString *encoding = @(@encode(typeof(MyUnion)));
  id mock = [self expectInvokerEncoding:encoding];
  XCTAssertTrue([mock encodingIsUnhandled]);
  [mock verify];
}

- (void) testUnhandledEncodingBitField {

  struct {
    unsigned int age : 3;
  } Age;

  NSString *encoding = @(@encode(typeof(Age)));
  id mock = [self expectInvokerEncoding:encoding];
  XCTAssertTrue([mock encodingIsUnhandled]);
  [mock verify];
}

- (void) testUnhandledUnknown {
  NSString *encoding = @"?";
  id mock = [self expectInvokerEncoding:encoding];
  XCTAssertTrue([mock encodingIsUnhandled]);
  [mock verify];
}

#pragma mark - selectorReturnsObject

- (void) testSelectorReturnsObjectYES {
  NSString *encoding = @(@encode(NSObject *));
  id mock = [self expectInvokerEncoding:encoding];
  XCTAssertTrue([mock selectorReturnsObject]);
  [mock verify];
}

- (void) testSelectorReturnsObjectNO {
  NSString *encoding = @(@encode(char *));
  id mock = [self expectInvokerEncoding:encoding];
  XCTAssertFalse([mock selectorReturnsObject]);
  [mock verify];
}

- (void) testSelectorReturnsObjectDNRS {
  id mock = [self stubInvokerDoesNotRespondToSelector];
  XCTAssertFalse([mock selectorReturnsObject]);
  [mock verify];
}

#pragma mark - selectorReturnsVoid

- (void) testSelectorReturnsVoidYES {
  NSString *encoding = @(@encode(void));
  id mock = [self expectInvokerEncoding:encoding];
  XCTAssertTrue([mock selectorReturnsVoid]);
  [mock verify];
}

- (void) testSelectorReturnsVoidNO {
  NSString *encoding = @(@encode(char *));
  id mock = [self expectInvokerEncoding:encoding];
  XCTAssertFalse([mock selectorReturnsVoid]);
  [mock verify];
}

- (void) testSelectorReturnsVoidDNRS {
  id mock = [self stubInvokerDoesNotRespondToSelector];
  XCTAssertFalse([mock selectorReturnsVoid]);
  [mock verify];
}

#pragma mark - selectorReturnsAutoBoxable

- (void) testSelectorReturnsAutoBoxableVoid {
  NSString *encoding = @(@encode(void));
  id mock = [self stubInvokerEncoding:encoding];
  XCTAssertFalse([mock selectorReturnValueCanBeCoerced]);
  [mock verify];
}

- (void) testSelectorReturnsAutoBoxableObject {
  NSString *encoding = @(@encode(NSObject *));
  id mock = [self stubInvokerEncoding:encoding];
  XCTAssertFalse([mock selectorReturnValueCanBeCoerced]);
  [mock verify];
}

- (void) testSelectorReturnsAutoBoxableUnknown {
  NSString *encoding = @"?";
  id mock = [self stubInvokerEncoding:encoding];
  XCTAssertFalse([mock selectorReturnValueCanBeCoerced]);
  [mock verify];
}

- (void) testSelectorReturnsAutoBoxableDNRS {
  id mock = [self stubInvokerDoesNotRespondToSelector];
  XCTAssertFalse([mock selectorReturnValueCanBeCoerced]);
  [mock verify];
}

- (void) testSelectorReturnsAutoBoxableCharStar {
  NSString *encoding = @(@encode(char *));
  id mock = [self stubInvokerEncoding:encoding];
  XCTAssertTrue([mock selectorReturnValueCanBeCoerced]);
  [mock verify];
}

#pragma mark - objectWithAutoboxedValue

- (void) testAutoboxedValueDNRS {
  id mock = [self stubInvokerDoesNotRespondToSelector];
  XCTAssertEqualObjects([mock objectByCoercingReturnValue],
                        LPTargetDoesNotRespondToSelector);
  [mock verify];
}

- (void) testAutoboxedValueNotAutoboxable {
  LPInvoker *invoker = [[LPInvoker alloc] initWithSelector:@selector(length)
                                                    target:@"string"];
  id mock = [OCMockObject partialMockForObject:invoker];
  BOOL falsey = NO;
  [[[mock expect] andReturnValue:OCMOCK_VALUE(falsey)] selectorReturnValueCanBeCoerced];

  XCTAssertEqualObjects([mock objectByCoercingReturnValue],
                        LPCannotCoerceSelectorReturnValueToObject);
  [mock verify];
}

- (void) testAutoboxedValueUnexpectedEncoding {
  // space is intential; don't want first char to match
  NSString *encoding = @" unexpected encoding";
  id mock = [self expectInvokerEncoding:encoding];
  XCTAssertEqualObjects([mock objectByCoercingReturnValue],
                        LPSelectorHasUnknownEncoding);
  [mock verify];
}

- (void) testAutoboxedValueInvalidEncoding {
  // space is intential; don't want first char to match
  NSString *encoding = @"";
  id mock = [self expectInvokerEncoding:encoding];
  XCTAssertEqualObjects([mock objectByCoercingReturnValue],
                        LPSelectorHasUnknownEncoding);
  [mock verify];
}

- (void) testAutoboxedValueConstCharStar {
  LPInvoker *invoker = [InvokerFactory invokerWithSelectorReturnValue:@"const char *"];
  XCTAssertEqualObjects([invoker objectByCoercingReturnValue], @"const char *");
}

- (void) testAutoboxedValueCharStar {
  LPInvoker *invoker = [InvokerFactory invokerWithSelectorReturnValue:@"char *"];
  XCTAssertEqualObjects([invoker objectByCoercingReturnValue], @"char *");
}

- (void) testAutoboxedValueChar {
  LPInvoker *invoker = [InvokerFactory invokerWithSelectorReturnValue:@"char"];
  XCTAssertEqualObjects([invoker objectByCoercingReturnValue], @"c");
}

- (void) testAutoboxedValueUnsignedChar {
  LPInvoker *invoker = [InvokerFactory invokerWithSelectorReturnValue:@"unsigned char"];
  XCTAssertEqualObjects([invoker objectByCoercingReturnValue], @"C");
}

- (void) testAutoboxedValueBool {
  LPInvoker *invoker = [InvokerFactory invokerWithSelectorReturnValue:@"bool true"];
  XCTAssertEqual([[invoker objectByCoercingReturnValue] boolValue], YES);

  invoker = [InvokerFactory invokerWithSelectorReturnValue:@"bool false"];
  XCTAssertEqual([[invoker objectByCoercingReturnValue] boolValue], NO);
}

- (void) testAutoboxedValueBOOL {
  LPInvoker *invoker = [InvokerFactory invokerWithSelectorReturnValue:@"BOOL YES"];
  XCTAssertEqual([[invoker objectByCoercingReturnValue] boolValue], YES);

  invoker = [InvokerFactory invokerWithSelectorReturnValue:@"BOOL NO"];
  XCTAssertEqual([[invoker objectByCoercingReturnValue] boolValue], NO);
}

- (void) testAutoboxedValueInteger {
  LPInvoker *invoker = [InvokerFactory invokerWithSelectorReturnValue:@"NSInteger"];
  XCTAssertEqual([[invoker objectByCoercingReturnValue] integerValue], NSIntegerMin);

  invoker = [InvokerFactory invokerWithSelectorReturnValue:@"NSUInteger"];
  XCTAssertEqual([[invoker objectByCoercingReturnValue] unsignedIntegerValue], NSNotFound);
}

- (void) testAutoboxedValueShort {
  LPInvoker *invoker = [InvokerFactory invokerWithSelectorReturnValue:@"short"];
  XCTAssertEqual([[invoker objectByCoercingReturnValue] integerValue], SHRT_MIN);

  invoker = [InvokerFactory invokerWithSelectorReturnValue:@"unsigned short"];
  XCTAssertEqual([[invoker objectByCoercingReturnValue] unsignedIntegerValue], SHRT_MAX);
}

- (void) testAutoboxedValueDouble {
  LPInvoker *invoker = [InvokerFactory invokerWithSelectorReturnValue:@"double"];
  XCTAssertEqual([[invoker objectByCoercingReturnValue] doubleValue], DBL_MAX);
}

- (void) testAutoboxedValueFloat {
  LPInvoker *invoker = [InvokerFactory invokerWithSelectorReturnValue:@"float"];
  XCTAssertEqual([[invoker objectByCoercingReturnValue] doubleValue], MAXFLOAT);
}

- (void) testAutoboxedValueLong {
  LPInvoker *invoker = [InvokerFactory invokerWithSelectorReturnValue:@"long"];
  XCTAssertEqual([[invoker objectByCoercingReturnValue] longValue], LONG_MIN);

  invoker = [InvokerFactory invokerWithSelectorReturnValue:@"unsigned long"];
  XCTAssertEqual([[invoker objectByCoercingReturnValue] unsignedLongValue], ULONG_MAX);

  invoker = [InvokerFactory invokerWithSelectorReturnValue:@"long long"];
  XCTAssertEqual([[invoker objectByCoercingReturnValue] longLongValue], LONG_LONG_MIN);

  invoker = [InvokerFactory invokerWithSelectorReturnValue:@"unsigned long long"];
  XCTAssertEqual([[invoker objectByCoercingReturnValue] unsignedLongLongValue], ULONG_LONG_MAX);
}

@end
