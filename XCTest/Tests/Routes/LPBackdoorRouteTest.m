#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import <XCTest/XCTest.h>
#import "LPBackdoorRoute.h"

@interface LPBackdoorRoute (LPXCTEST)

- (NSDictionary *) failureWithReason:(NSString *) reason
                             details:(NSString *) details;
@end

@interface LPBackdoorRouteTest : XCTestCase

@property(nonatomic, strong) LPBackdoorRoute *route;

@end

@implementation LPBackdoorRouteTest

- (void) setUp {
  [super setUp];
  self.route = [LPBackdoorRoute new];
}

- (void) tearDown {
  self.route = nil;
  [super tearDown];
}

- (void) testSupportsMethodPOST {
  expect([self.route supportsMethod:@"POST" atPath:nil]).to.equal(YES);
}

- (void) testSupportsMethodAnythingButPOST {
  expect([self.route supportsMethod:@"GET" atPath:nil]).to.equal(NO);
}

- (void) testFailureWithReasonDetails {
  NSString *reason = @"A reason";
  NSString *details = @"Some details";

  NSDictionary *dictionary = [self.route failureWithReason:reason
                                                   details:details];
  expect([dictionary count]).to.equal(3);
  expect(dictionary[@"reason"]).to.equal(reason);
  expect(dictionary[@"details"]).to.equal(details);
  expect(dictionary[@"outcome"]).to.equal(@"FAILURE");
}

- (void) testMissingSelector {
  NSDictionary *data = @{};

  NSDictionary *actual = [self.route JSONResponseForMethod:nil
                                                       URI:nil
                                                      data:data];

  expect([actual count]).to.equal(3);
  expect(actual[@"reason"]).to.equal(@"Missing selector name");
  expect(actual[@"details"]).notTo.equal(nil);
  expect(actual[@"outcome"]).to.equal(@"FAILURE");
}

- (void) testArgAndArgumentsKey {
  NSDictionary *data =
  @{
    @"arg" : @"an arg",
    @"arguments" : @[@"a", @"b", @"c"],
    @"selector" : @"selector:"
    };

  NSDictionary *actual = [self.route JSONResponseForMethod:nil
                                                       URI:nil
                                                      data:data];

  expect([actual count]).to.equal(3);
  expect(actual[@"reason"]).to.equal(@"Incompatible keys: 'arg' and 'arguments'");
  expect(actual[@"details"]).notTo.equal(nil);
  expect(actual[@"outcome"]).to.equal(@"FAILURE");
}

- (void) testMissingArgOrArgumentsKey {
  NSDictionary *data =
  @{
    @"selector" : @"selector:"
    };

  NSDictionary *actual = [self.route JSONResponseForMethod:nil
                                                       URI:nil
                                                      data:data];

  expect([actual count]).to.equal(3);
  expect(actual[@"reason"]).to.equal(@"Missing argument(s) for selector");
  expect(actual[@"details"]).notTo.equal(nil);
  expect(actual[@"outcome"]).to.equal(@"FAILURE");
}

- (void) testUnknownSelector {

  NSDictionary *data =
  @{
    @"selector" : @"unknownSelector",
    @"arguments" : @[]
    };


  NSDictionary *actual = [self.route JSONResponseForMethod:nil
                                                       URI:nil
                                                      data:data];

  expect([actual count]).to.equal(3);
  expect(actual[@"reason"]).to.equal(@"The backdoor: 'unknownSelector' is undefined");
  expect(actual[@"details"]).notTo.equal(nil);
  expect(actual[@"outcome"]).to.equal(@"FAILURE");
}

@end
