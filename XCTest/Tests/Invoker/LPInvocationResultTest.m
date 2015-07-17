#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPInvocationResult.h"

@interface LPInvocationResultTest : XCTestCase

@end

@implementation LPInvocationResultTest

- (void)setUp {
  [super setUp];
}

- (void)tearDown {
  [super tearDown];
}

- (void) testIsError {
  LPInvocationResult *result = [LPInvocationResult new];
  expect([result isError]).to.equal(NO);
}

@end
