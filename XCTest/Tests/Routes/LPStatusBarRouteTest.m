#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import <XCTest/XCTest.h>
#import "LPStatusBarRoute.h"
#import "LPOrientationOperation.h"

@interface LPStatusBarRouteTest : XCTestCase

@property(strong) LPStatusBarRoute *route;

@end

@implementation LPStatusBarRouteTest

- (void)setUp {
  [super setUp];
  self.route = [LPStatusBarRoute new];
}

- (void)tearDown {
  self.route = nil;
  [super tearDown];
}

- (void)testRespondsToGET {
  BOOL actual = [self.route supportsMethod:@"GET" atPath:nil];
  expect(actual).to.equal(YES);
}

- (void)testDoesNotRespondToPOST {
  BOOL actual = [self.route supportsMethod:@"POST" atPath:nil];
  expect(actual).to.equal(NO);
}

- (void)testJSONResponseForMethod {
  id mockApp = OCMPartialMock([UIApplication sharedApplication]);

  CGRect frame = CGRectMake(10, 20, 30, 40);

  OCMExpect([mockApp statusBarFrame]).andReturn(frame);
  OCMExpect([mockApp isStatusBarHidden]).andReturn(NO);

  id mockOrientationOp = OCMClassMock([LPOrientationOperation class]);
  OCMExpect([mockOrientationOp statusBarOrientation]).andReturn(@"Drow Ranger");

  NSDictionary *actual = [self.route JSONResponseForMethod:nil
                                                       URI:nil
                                                      data:nil];

  expect(actual[@"outcome"]).to.equal(@"SUCCESS");

  NSDictionary *results = actual[@"results"];
  expect(results[@"orientation"]).to.equal(@"Drow Ranger");
  expect(results[@"hidden"]).to.equal(@(NO));

  NSDictionary *frameDict = results[@"frame"];
  expect(frameDict[@"x"]).to.equal(@(10));
  expect(frameDict[@"y"]).to.equal(@(20));
  expect(frameDict[@"width"]).to.equal(@(30));
  expect(frameDict[@"height"]).to.equal(@(40));

  OCMVerify([mockApp statusBarFrame]);
  OCMVerify([mockApp isStatusBarHidden]);
}

@end
