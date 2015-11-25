#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import <XCTest/XCTest.h>
#import "LPProcessInfoRoute.h"

@interface LPProcessInfoRouteTest : XCTestCase

@property(nonatomic, strong) LPProcessInfoRoute *route;
@end

@implementation LPProcessInfoRouteTest

- (void) setUp {
  [super setUp];
  self.route = [LPProcessInfoRoute new];
}

- (void) tearDown {
  [super tearDown];
  self.route = nil;
}

- (void) testSupportsMethodGET {
  expect([self.route supportsMethod:@"GET" atPath:nil]).to.equal(YES);
}

- (void) testSupportsMethodAnythingButGET {
  expect([self.route supportsMethod:@"POST" atPath:nil]).to.equal(NO);
}

- (void) testJSONResponseForMethod {
  NSDictionary *info = [self.route JSONResponseForMethod:nil
                                                     URI:nil
                                                     data:nil];
  expect(info[@"arguments"]).notTo.equal(nil);
  expect(info[@"environment"]).notTo.equal(nil);
}

@end
