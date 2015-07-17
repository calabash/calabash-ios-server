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

- (void) testInitWithValue {
  LPInvocationResult *result;
  id value;

  value = @[];
  result = [[LPInvocationResult alloc] initWithValue:value];
  expect(result.value).to.equal(value);

  value = nil;
  result = [[LPInvocationResult alloc] initWithValue:value];
  expect(result.value).to.equal([NSNull null]);
}

- (void) testIsNSNull {
  LPInvocationResult *result;

  result = [[LPInvocationResult alloc] initWithValue:@[]];
  expect([result isNSNull]).to.equal(NO);

  result = [[LPInvocationResult alloc] initWithValue:nil];
  expect([result isNSNull]).to.equal(YES);
}

@end
