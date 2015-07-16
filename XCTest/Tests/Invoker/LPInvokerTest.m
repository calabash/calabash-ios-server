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
+ (BOOL) isCGRectEncoding:(NSString *) encoding;
+ (BOOL) isCGPointEncoding:(NSString *) encoding;
+ (NSString *) encodingAtIndex:(NSUInteger) index
                     signature:(NSMethodSignature *) signature;

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
  SEL selector = @selector(encodingForSelectorReturnType);
  self.originalEncodingMethod = class_getInstanceMethod([LPInvoker class],
                                                        selector);
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
  [[[mock expect] andReturn:mockEncoding] encodingForSelectorReturnType];
  return mock;
}

- (id) stubInvokerEncoding:(NSString *) mockEncoding {
  LPInvoker *invoker = [[LPInvoker alloc] initWithSelector:@selector(length)
                                                    target:@"string"];
  id mock = [OCMockObject partialMockForObject:invoker];
  [[[mock stub] andReturn:mockEncoding] encodingForSelectorReturnType];
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
  id actual = [LPInvoker invokeZeroArgumentSelector:selector withTarget:target];
  XCTAssertEqualObjects(actual, LPIncorrectNumberOfArgumentsProvidedToSelector);
}

- (void) testInvokeSelectorTargetDoesNotRespondToSelector {
  NSString *target = @"string";
  SEL selector = NSSelectorFromString(@"obviouslyUnknownSelector");
  id actual = [LPInvoker invokeZeroArgumentSelector:selector withTarget:target];
  XCTAssertEqualObjects(actual, LPTargetDoesNotRespondToSelector);
}

- (void) testInvokeSelectorTargetVoid {
  NSString *target = @"string";
  SEL selector = @selector(length);
  @try {
    [self swizzleEncodingWithNewSelector:@selector(encodingSwizzledToVoid)];
    id actual = [LPInvoker invokeZeroArgumentSelector:selector withTarget:target];
    XCTAssertEqualObjects(actual, LPVoidSelectorReturnValue);
  } @finally {
    [self unswizzleEncoding];
  }
}

- (void) testInvokeSelectorTargetUnknown {
  NSString *target = @"string";
  SEL selector = @selector(length);
  @try {
    [self swizzleEncodingWithNewSelector:@selector(encodingSwizzledToUnknown)];
    id actual = [LPInvoker invokeZeroArgumentSelector:selector withTarget:target];
    XCTAssertEqualObjects(actual, LPSelectorHasUnknownReturnTypeEncoding);
  } @finally {
    [self unswizzleEncoding];
  }
}

- (void) testInvokeSelectorTargetObject {
  NSString *target = @"target";
  SEL selector = @selector(description);
  id actual = [LPInvoker invokeZeroArgumentSelector:selector withTarget:target];
  XCTAssertEqualObjects(actual, target);
}

- (void) testInvokeSelectorTargetNil {
  NSString *target = @"string";
  SEL selector = @selector(returnsNil);
  id actual = [LPInvoker invokeZeroArgumentSelector:selector withTarget:target];
  XCTAssertEqual(actual, [NSNull null]);
}

- (void) testInvokeSelectorTargetCoerced {
  NSString *target = @"string";
  SEL selector = @selector(length);
  id actual = [LPInvoker invokeZeroArgumentSelector:selector withTarget:target];
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
  NSString *actual = [invoker encodingForSelectorReturnType];
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
  NSString *actual = [invoker encodingForSelectorReturnType];
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

#pragma mark - Detecting CGRect and CGPoint Encoding

- (void) testIsCGRectEncodingYES {
  NSString *encoding = @(@encode(typeof(CGRectZero)));
  BOOL actual = [LPInvoker isCGRectEncoding:encoding];
  expect(actual).to.equal(YES);
}

- (void) testIsCGRectEncodingNO {
  NSString *encoding = @(@encode(typeof(CGSizeZero)));
  BOOL actual = [LPInvoker isCGRectEncoding:encoding];
  expect(actual).to.equal(NO);
}

- (void) testIsCGPointEncodingYES {
  NSString *encoding = @(@encode(typeof(CGPointZero)));
  BOOL actual = [LPInvoker isCGPointEncoding:encoding];
  expect(actual).to.equal(YES);
}

- (void) testIsCGPointEncodingNO {
  NSString *encoding = @(@encode(typeof(CGSizeZero)));
  BOOL actual = [LPInvoker isCGPointEncoding:encoding];
  expect(actual).to.equal(NO);
}

#pragma mark - Argument Encodings

- (void) testEncodingAtIndex {
  NSMethodSignature *signature;
  SEL selector = @selector(substringFromIndex:);
  signature = [[NSString class] instanceMethodSignatureForSelector:selector];

  NSString *encoding = [LPInvoker encodingAtIndex:2
                                        signature:signature];
  expect(encoding).to.equal(@"Q");
}

- (void) testSelectorArgumentCountMatchesArgumentCountYES {
  LPInvoker *invocation = [InvokerFactory invokerWithArgmentValue:@"object pointer"];
  BOOL actual = [invocation selectorArgumentCountMatchesArgumentsCount:@[@(1)]];
  expect(actual).to.equal(YES);
}

- (void) testSelectorArgumentCountMatchesArgumentCountNO {
  LPInvoker *invocation = [InvokerFactory invokerWithArgmentValue:@"object pointer"];
  NSArray *arguments = @[@(1), @(2)];
  BOOL actual = [invocation selectorArgumentCountMatchesArgumentsCount:arguments];
  expect(actual).to.equal(NO);

  arguments = @[];
  actual = [invocation selectorArgumentCountMatchesArgumentsCount:arguments];
  expect(actual).to.equal(NO);
}

@end
