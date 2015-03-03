#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPWebQuery.h"

@interface LPWebQueryTest : XCTestCase


@end

@implementation LPWebQueryTest

- (void) setUp {
  [super setUp];
}

- (void) tearDown {
  [super tearDown];
}

- (void) testWebQueryEmptyTest {
  // For TDD - can be removed.
}

@end
