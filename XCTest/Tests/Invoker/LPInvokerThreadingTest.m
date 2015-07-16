#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPInvoker.h"
#import "InvokerFactory.h"

@interface LPInvokerThreadingTest : XCTestCase

@end

@implementation LPInvokerThreadingTest

- (void)setUp {
  [super setUp];
}

- (void)tearDown {
  [super tearDown];
}

- (void) testZeroArgOnMainThread {
  expect([[NSThread currentThread] isMainThread]).to.equal(YES);

  Target *target = [Target new];
  SEL selector = @selector(selectorThatReturnsDouble);

  id result = [LPInvoker invokeOnMainThreadZeroArgumentSelector:selector
                                                     withTarget:target];
  expect(result).to.equal(@(DBL_MAX));
}

- (void) testZeroArgPrimativeOffMainThread {
  expect([[NSThread currentThread] isMainThread]).to.equal(YES);

  XCTestExpectation *expectation = [self expectationWithDescription:@"Async"];

  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    expect([[NSThread currentThread] isMainThread]).to.equal(NO);

    Target *target = [Target new];
    SEL selector = @selector(selectorThatReturnsDouble);

    id result = [LPInvoker invokeOnMainThreadZeroArgumentSelector:selector
                                                       withTarget:target];

    expect(result).to.equal(@(DBL_MAX));
    [expectation fulfill];
  });

  [self waitForExpectationsWithTimeout:0.1 handler:^(NSError *error) {
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

    id result = [LPInvoker invokeOnMainThreadZeroArgumentSelector:selector
                                                       withTarget:target];

    expect(result).to.equal(@"last");
    [expectation fulfill];
  });

  [self waitForExpectationsWithTimeout:0.1 handler:^(NSError *error) {
    if (error) { XCTFail(@"Expectation Failed with error: %@", error); }
  }];
}

@end
