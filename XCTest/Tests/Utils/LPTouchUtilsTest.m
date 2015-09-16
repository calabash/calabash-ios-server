#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPTouchUtils.h"

@interface LPTouchUtils (TEST)

@end

@interface LPTouchUtilsTest : XCTestCase

@end

@implementation LPTouchUtilsTest

- (void)setUp {
  [super setUp];
}

- (void)tearDown {
  [super tearDown];
}

@end
