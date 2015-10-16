#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPInvoker.h"
#import "InvokerFactory.h"
#import "LPInvocationResult.h"
#import "LPInvocationError.h"

@interface LPInvokerThreadingTest : XCTestCase

@end

@implementation LPInvokerThreadingTest

- (void)setUp {
  [super setUp];
}

- (void)tearDown {
  [super tearDown];
}

#pragma mark - Zero Arg Selectors

- (void) testZeroArgOnMainThread {
  expect([[NSThread currentThread] isMainThread]).to.equal(YES);

  Target *target = [Target new];
  SEL selector = @selector(selectorThatReturnsDouble);

  LPInvocationResult *result = [LPInvoker invokeOnMainThreadZeroArgumentSelector:selector
                                                                      withTarget:target];
  expect(result.value).to.equal(@(DBL_MAX));
}

- (void) testZeroArgPrimativeOffMainThread {
  expect([[NSThread currentThread] isMainThread]).to.equal(YES);

  XCTestExpectation *expectation = [self expectationWithDescription:@"Async"];

  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    expect([[NSThread currentThread] isMainThread]).to.equal(NO);

    Target *target = [Target new];
    SEL selector = @selector(selectorThatReturnsDouble);

    LPInvocationResult *result = [LPInvoker invokeOnMainThreadZeroArgumentSelector:selector
                                                                        withTarget:target];

    expect(result.value).to.equal(@(DBL_MAX));
    [expectation fulfill];
  });

  [self waitForExpectationsWithTimeout:0.5 handler:^(NSError *error) {
    if (error) { XCTFail(@"Expectation Failed with error: %@", error); }
  }];
}

- (void) testZeroArgTargetDefinedOnMainThread {
  expect([[NSThread currentThread] isMainThread]).to.equal(YES);

  XCTestExpectation *expectation = [self expectationWithDescription:@"Async"];

  NSArray *target = @[@"first", @"second", @"last"];
  SEL selector = @selector(lastObject);

  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    expect([[NSThread currentThread] isMainThread]).to.equal(NO);

    LPInvocationResult *result = [LPInvoker invokeOnMainThreadZeroArgumentSelector:selector
                                                                        withTarget:target];

    expect(result.value).to.equal(@"last");
    [expectation fulfill];
  });

  [self waitForExpectationsWithTimeout:0.5 handler:^(NSError *error) {
    if (error) { XCTFail(@"Expectation Failed with error: %@", error); }
  }];
}

#pragma mark - Selectors with Arguments

- (void) testOnMainThread {
  expect([[NSThread currentThread] isMainThread]).to.equal(YES);

  Target *target = [Target new];
  SEL selector = @selector(selectorDouble:);

  LPInvocationResult *result = [LPInvoker invokeOnMainThreadSelector:selector
                                                          withTarget:target
                                                           arguments:@[@(DBL_MAX)]];
  expect(result.value).to.equal(@(YES));
}

- (void) testPrimativeArgCalledOffMainThread {
  expect([[NSThread currentThread] isMainThread]).to.equal(YES);

  XCTestExpectation *expectation = [self expectationWithDescription:@"Async"];

  Target *target = [Target new];
  SEL selector = @selector(selectorDouble:);
  NSArray *arguments = @[@(DBL_MAX)];

  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    expect([[NSThread currentThread] isMainThread]).to.equal(NO);


    LPInvocationResult *result = [LPInvoker invokeOnMainThreadSelector:selector
                                                            withTarget:target
                                                             arguments:arguments];

    expect(result.value).to.equal(@(YES));
    [expectation fulfill];
  });

  [self waitForExpectationsWithTimeout:0.5 handler:^(NSError *error) {
    if (error) { XCTFail(@"Expectation Failed with error: %@", error); }
  }];
}

- (void) testPrimativeArgWithAllVariablesCreatedOffMainThread {
  expect([[NSThread currentThread] isMainThread]).to.equal(YES);

  XCTestExpectation *expectation = [self expectationWithDescription:@"Populate"];

  __block Target *target;
  __block NSArray *arguments;

  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    expect([[NSThread currentThread] isMainThread]).to.equal(NO);

    target = [Target new];
    arguments = @[@(DBL_MAX)];

    [expectation fulfill];
  });

  [self waitForExpectationsWithTimeout:0.5 handler:^(NSError *error) {
    if (error) { XCTFail(@"Expectation Failed with error: %@", error); }
  }];

  expectation = [self expectationWithDescription:@"Test"];

  SEL selector = @selector(selectorDouble:);

  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    expect([[NSThread currentThread] isMainThread]).to.equal(NO);


    LPInvocationResult *result = [LPInvoker invokeOnMainThreadSelector:selector
                                                            withTarget:target
                                                             arguments:arguments];

    expect(result.value).to.equal(@(YES));
    [expectation fulfill];
  });

  [self waitForExpectationsWithTimeout:0.5 handler:^(NSError *error) {
    if (error) { XCTFail(@"Expectation Failed with error: %@", error); }
  }];
}

- (void) testPointerArgWithAllVariablesCreatedOffMainThread {
  expect([[NSThread currentThread] isMainThread]).to.equal(YES);

  XCTestExpectation *expectation = [self expectationWithDescription:@"Populate"];

  __block NSString *target;
  __block NSArray *arguments;

  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    expect([[NSThread currentThread] isMainThread]).to.equal(NO);

    target = @"A string";
    arguments = @[@": appended"];

    [expectation fulfill];
  });

  [self waitForExpectationsWithTimeout:0.5 handler:^(NSError *error) {
    if (error) { XCTFail(@"Expectation Failed with error: %@", error); }
  }];

  expectation = [self expectationWithDescription:@"Test"];

  SEL selector = @selector(stringByAppendingString:);

  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    expect([[NSThread currentThread] isMainThread]).to.equal(NO);


    LPInvocationResult *result = [LPInvoker invokeOnMainThreadSelector:selector
                                                            withTarget:target
                                                             arguments:arguments];

    expect(result.value).to.equal(@"A string: appended");
    [expectation fulfill];
  });

  [self waitForExpectationsWithTimeout:0.5 handler:^(NSError *error) {
    if (error) { XCTFail(@"Expectation Failed with error: %@", error); }
  }];
}

@end
