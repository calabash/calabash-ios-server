#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPInvoker.h"
#import "InvokerFactory.h"
#import "LPCoercion.h"

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

#pragma mark - Mocking

- (void) unswizzleEncoding {
  method_exchangeImplementations(self.swizzledEncodingMethod,
                                 self.originalEncodingMethod);
}

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

- (void) testInvokeSelectorTargetSelectorHasArguments {
  NSString *target = @"string";
  SEL selector = @selector(substringToIndex:);
  id actual = [LPInvoker invokeSelector:selector withTarget:target];
  XCTAssertEqualObjects(actual, [NSNull null]);
}

- (void) testInvokeSelectorTargetDoesNotRespondToSelector {
  NSString *target = @"string";
  SEL selector = NSSelectorFromString(@"obviouslyUnknownSelector");
  id actual = [LPInvoker invokeSelector:selector withTarget:target];
  XCTAssertEqualObjects(actual, [NSNull null]);
}

- (void) testInvokeSelectorTargetVoid {
  NSString *target = @"string";
  SEL selector = @selector(length);
  @try {
    [self swizzleEncodingWithNewSelector:@selector(encodingSwizzledToVoid)];
    id actual = [LPInvoker invokeSelector:selector withTarget:target];
    XCTAssertEqualObjects(actual, [NSNull null]);
  } @finally {
    [self unswizzleEncoding];
  }
}

- (void) testInvokeSelectorTargetUnknown {
  NSString *target = @"string";
  SEL selector = @selector(length);
  @try {
    [self swizzleEncodingWithNewSelector:@selector(encodingSwizzledToUnknown)];
    id actual = [LPInvoker invokeSelector:selector withTarget:target];
    XCTAssertEqualObjects(actual, [NSNull null]);
  } @finally {
    [self unswizzleEncoding];
  }
}

- (void) testInvokeSelectorTargetObject {
  NSString *target = @"target";
  SEL selector = @selector(description);
  id actual = [LPInvoker invokeSelector:selector withTarget:target];
  XCTAssertEqualObjects(actual, target);
}

- (void) testInvokeSelectorTargetNil {
  NSString *target = @"string";
  SEL selector = @selector(returnsNil);
  id actual = [LPInvoker invokeSelector:selector withTarget:target];
  XCTAssertEqual(actual, [NSNull null]);
}

- (void) testInvokeSelectorTargetCoerced {
  NSString *target = @"string";
  SEL selector = @selector(length);
  id actual = [LPInvoker invokeSelector:selector withTarget:target];
  XCTAssertEqual([actual unsignedIntegerValue], target.length);
}

#pragma mark - invocation

- (void) testInvocationRespondsToSelector {
  NSString *target = @"string";
  SEL selector = @selector(length);
  LPInvoker *invoker = [[LPInvoker alloc] initWithSelector:selector
                                                    target:target];
  NSInvocation *invocation = [invoker invocation];
  XCTAssertEqual(invocation.selector, selector);
  XCTAssertEqualObjects(invocation.target, target);
}

- (void) testInvocationDoesNotRespondToSelector {
  NSString *target = @"string";
  SEL selector = NSSelectorFromString(@"obviouslyUnknownSelector");
  LPInvoker *invoker = [[LPInvoker alloc] initWithSelector:selector
                                                    target:target];
  NSInvocation *invocation = [invoker invocation];
  XCTAssertNil(invocation);
}

#pragma mark - signature

- (void) testSignatureRespondsToSelector {
  NSString *target = @"string";
  SEL selector = @selector(length);
  LPInvoker *invoker = [[LPInvoker alloc] initWithSelector:selector
                                                    target:target];
  XCTAssertNotNil([invoker signature]);
}

- (void) testSignatureDoesNotRespondToSelector {
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
#if __LP64__
  XCTAssertEqualObjects(actual, @"Q");
#else
  XCTAssertEqualObjects(actual, @"I");
#endif
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

- (void) testSelectorReturnsObjectDoesNotRespondToSelector {
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

- (void) testSelectorReturnsVoidDoesNotRespondToSelector {
  id mock = [self stubInvokerDoesNotRespondToSelector];
  XCTAssertFalse([mock selectorReturnsVoid]);
  [mock verify];
}

#pragma mark - selectorReturnValueCanBeCoerced

- (void) testselectorReturnValueCanBeCoercedVoid {
  NSString *encoding = @(@encode(void));
  id mock = [self stubInvokerEncoding:encoding];
  XCTAssertFalse([mock selectorReturnValueCanBeCoerced]);
  [mock verify];
}

- (void) testselectorReturnValueCanBeCoercedObject {
  NSString *encoding = @(@encode(NSObject *));
  id mock = [self stubInvokerEncoding:encoding];
  XCTAssertFalse([mock selectorReturnValueCanBeCoerced]);
  [mock verify];
}

- (void) testselectorReturnValueCanBeCoercedUnknown {
  NSString *encoding = @"?";
  id mock = [self stubInvokerEncoding:encoding];
  XCTAssertFalse([mock selectorReturnValueCanBeCoerced]);
  [mock verify];
}

- (void) testselectorReturnValueCanBeCoercedDoesNotRespondToSelector {
  id mock = [self stubInvokerDoesNotRespondToSelector];
  XCTAssertFalse([mock selectorReturnValueCanBeCoerced]);
  [mock verify];
}

- (void) testselectorReturnValueCanBeCoercedCharStar {
  NSString *encoding = @(@encode(char *));
  id mock = [self stubInvokerEncoding:encoding];
  XCTAssertTrue([mock selectorReturnValueCanBeCoerced]);
  [mock verify];
}

#pragma mark - objectByCoercingReturnValue

- (void) testObjectByCoercingReturnValueDoesNotRespondToSelector {
  id mock = [self stubInvokerDoesNotRespondToSelector];
  LPCoercion *coercion = [mock objectByCoercingReturnValue];
  XCTAssertEqualObjects(coercion.failureMessage, LPTargetDoesNotRespondToSelector);
  [mock verify];
}

- (void) testObjectByCoercingReturnValueNotAutoboxable {
  LPInvoker *invoker = [[LPInvoker alloc] initWithSelector:@selector(length)
                                                    target:@"string"];
  id mock = [OCMockObject partialMockForObject:invoker];
  BOOL falsey = NO;
  [[[mock expect] andReturnValue:OCMOCK_VALUE(falsey)] selectorReturnValueCanBeCoerced];
  LPCoercion *coercion = [mock objectByCoercingReturnValue];
  XCTAssertEqualObjects(coercion.failureMessage, LPCannotCoerceSelectorReturnValueToObject);
  [mock verify];
}

- (void) testObjectByCoercingReturnValueUnexpectedEncoding {
  // space is intential; don't want first char to match
  NSString *encoding = @" unexpected encoding";
  id mock = [self expectInvokerEncoding:encoding];
  LPCoercion *coercion = [mock objectByCoercingReturnValue];
  XCTAssertEqualObjects(coercion.failureMessage, LPSelectorHasUnknownEncoding);
  [mock verify];
}

- (void) testObjectByCoercingReturnValueInvalidEncoding {
  // space is intential; don't want first char to match
  NSString *encoding = @"";
  id mock = [self expectInvokerEncoding:encoding];
  LPCoercion *coercion = [mock objectByCoercingReturnValue];
  XCTAssertEqualObjects(coercion.failureMessage, LPSelectorHasUnknownEncoding);
  [mock verify];
}

- (void) testObjectByCoercingReturnValueConstCharStar {
  LPInvoker *invoker = [InvokerFactory invokerWithSelectorReturnValue:@"const char *"];
  LPCoercion *coercion = [invoker objectByCoercingReturnValue];
  id value = coercion.value;
  XCTAssertEqualObjects(value, @"const char *");
}

- (void) testObjectByCoercingReturnValueCharStar {
  LPInvoker *invoker = [InvokerFactory invokerWithSelectorReturnValue:@"char *"];
  LPCoercion *coercion = [invoker objectByCoercingReturnValue];
  id value = coercion.value;
  XCTAssertEqualObjects(value, @"char *");
}

- (void) testObjectByCoercingReturnValueChar {
  LPInvoker *invoker = [InvokerFactory invokerWithSelectorReturnValue:@"char"];
  LPCoercion *coercion = [invoker objectByCoercingReturnValue];
  id value = coercion.value;
  XCTAssertEqualObjects(value, @"c");
}

- (void) testObjectByCoercingReturnValueUnsignedChar {
  LPInvoker *invoker = [InvokerFactory invokerWithSelectorReturnValue:@"unsigned char"];
  LPCoercion *coercion = [invoker objectByCoercingReturnValue];
  id value = coercion.value;
  XCTAssertEqualObjects(value, @"C");
}

- (void) testObjectByCoercingReturnValueBool {
  LPInvoker *invoker = [InvokerFactory invokerWithSelectorReturnValue:@"bool true"];
  LPCoercion *coercion = [invoker objectByCoercingReturnValue];
  id value = coercion.value;
  XCTAssertEqual([value boolValue], YES);

  invoker = [InvokerFactory invokerWithSelectorReturnValue:@"bool false"];
  coercion = [invoker objectByCoercingReturnValue];
  value = coercion.value;
  XCTAssertEqual([value boolValue], NO);
}

- (void) testObjectByCoercingReturnValueBOOL {
  LPInvoker *invoker = [InvokerFactory invokerWithSelectorReturnValue:@"BOOL YES"];
  LPCoercion *coercion = [invoker objectByCoercingReturnValue];
  id value = coercion.value;
  XCTAssertEqual([value boolValue], YES);

  invoker = [InvokerFactory invokerWithSelectorReturnValue:@"BOOL NO"];
  coercion = [invoker objectByCoercingReturnValue];
  value = coercion.value;
  XCTAssertEqual([value boolValue], NO);
}

- (void) testObjectByCoercingReturnValueInteger {
  LPInvoker *invoker = [InvokerFactory invokerWithSelectorReturnValue:@"NSInteger"];
  LPCoercion *coercion = [invoker objectByCoercingReturnValue];
  id value = coercion.value;
  XCTAssertEqual([value integerValue], NSIntegerMin);

  invoker = [InvokerFactory invokerWithSelectorReturnValue:@"NSUInteger"];
  coercion = [invoker objectByCoercingReturnValue];
  value = coercion.value;
  XCTAssertEqual([value unsignedIntegerValue], NSNotFound);
}

- (void) testObjectByCoercingReturnValueShort {
  LPInvoker *invoker = [InvokerFactory invokerWithSelectorReturnValue:@"short"];
  LPCoercion *coercion = [invoker objectByCoercingReturnValue];
  id value = coercion.value;
  XCTAssertEqual([value shortValue], SHRT_MIN);

  invoker = [InvokerFactory invokerWithSelectorReturnValue:@"unsigned short"];
  coercion = [invoker objectByCoercingReturnValue];
  value = coercion.value;
  XCTAssertEqual([value unsignedShortValue], SHRT_MAX);
}

- (void) testObjectByCoercingReturnValueDouble {
  LPInvoker *invoker = [InvokerFactory invokerWithSelectorReturnValue:@"double"];
  LPCoercion *coercion = [invoker objectByCoercingReturnValue];
  id value = coercion.value;
  XCTAssertEqual([value doubleValue], DBL_MAX);
}

- (void) testObjectByCoercingReturnValueFloat {
  LPInvoker *invoker = [InvokerFactory invokerWithSelectorReturnValue:@"float"];
  LPCoercion *coercion = [invoker objectByCoercingReturnValue];
  id value = coercion.value;
  XCTAssertEqual([value floatValue], MAXFLOAT);
}

- (void) testObjectByCoercingReturnValueLong {
  LPInvoker *invoker = [InvokerFactory invokerWithSelectorReturnValue:@"long"];
  LPCoercion *coercion = [invoker objectByCoercingReturnValue];
  id value = coercion.value;
  XCTAssertEqual([value longValue], LONG_MIN);

  invoker = [InvokerFactory invokerWithSelectorReturnValue:@"unsigned long"];
  coercion = [invoker objectByCoercingReturnValue];
  value = coercion.value;
  XCTAssertEqual([value unsignedLongValue], ULONG_MAX);

  invoker = [InvokerFactory invokerWithSelectorReturnValue:@"long long"];
  coercion = [invoker objectByCoercingReturnValue];
  value = coercion.value;
  XCTAssertEqual([value longLongValue], LONG_LONG_MIN);

  invoker = [InvokerFactory invokerWithSelectorReturnValue:@"unsigned long long"];
  coercion = [invoker objectByCoercingReturnValue];
  value = coercion.value;
  XCTAssertEqual([value unsignedLongLongValue], ULONG_LONG_MAX);
}

@end
