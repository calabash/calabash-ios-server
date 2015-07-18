#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPOperation.h"

@interface LPOperationTest : XCTestCase

@end

@implementation LPOperationTest

- (void)setUp {
  [super setUp];
}

- (void)tearDown {
  [super tearDown];
}

- (void) testDescription {
  NSDictionary *dictionary =
  @{@"method_name" : @"appendString:withString:",
    @"arguments" : @[@"A string", @": appended"]};

  LPOperation *operation = [[LPOperation alloc] initWithOperation:dictionary];

  NSString *actual = [operation description];
  NSString *expected = @"<LPOperation 'appendString:withString:' with arguments 'A string, : appended'>";
  expect(actual).to.equal(expected);
}

@end
