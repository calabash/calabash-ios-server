#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
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
