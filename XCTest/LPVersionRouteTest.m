#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPVersionRoute.h"

@interface LPVersionRouteTest : XCTestCase

@end

@implementation LPVersionRouteTest

- (void)setUp {
  [super setUp];
}

- (void)tearDown {
  [super tearDown];
}

- (void) testVersionRouteReportsCalabashServerPort {
  LPVersionRoute *versionRoute = [LPVersionRoute new];
  NSDictionary *versionInfo = [versionRoute JSONResponseForMethod:nil
                                                              URI:nil
                                                             data:nil];
  NSNumber *serverPort = versionInfo[@"server_port"];
  XCTAssertEqual([serverPort unsignedShortValue], 37265);
}

@end

SpecBegin(LPVersionRoute)

describe(@"LPVersionRoute", ^{
  describe(@"#JSONResponsForMethod:URI:data:", ^{
    __block NSDictionary *response;

    before(^{
      LPVersionRoute *route = [LPVersionRoute new];
      response = [route JSONResponseForMethod:nil URI:nil data:nil];
    });

    it(@"contains app_base_sdk key", ^{
      XCTAssertNotNil(response[@"app_base_sdk"]);
    });
  });
});

SpecEnd
