#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import <XCTest/XCTest.h>
#import "LPSuspendAppRoute.h"

@interface LPSuspendAppRoute (LPXCTEST)

- (CGFloat) durationWithDictionary:(NSDictionary *) arguments;
- (NSString *) stringForApplicationState:(UIApplicationState) state;

@end

@interface LPSuspendAppRouteTest : XCTestCase

@property (nonatomic, strong) LPSuspendAppRoute *route;

@end

@implementation LPSuspendAppRouteTest

- (void)setUp {
  [super setUp];
  self.route = [LPSuspendAppRoute new];
}

- (void)tearDown {
  [super tearDown];
  self.route = nil;
}

- (void) testSupportsMethodPOST {
  BOOL actual = [self.route supportsMethod:@"POST" atPath:nil];
  expect(actual).to.equal(YES);
}

- (void) testSupportsMethodGET {
  BOOL actual = [self.route supportsMethod:@"GET" atPath:nil];
  expect(actual).to.equal(YES);
}

- (void) testSupportsNoOtherMethod {
  BOOL actual = [self.route supportsMethod:@"FOO" atPath:nil];
  expect(actual).to.equal(NO);
}

- (void) testDurationWithDictionaryNoDurationKey {
  NSDictionary *dictionary = @{};

  CGFloat expected = 2.0;
  CGFloat actual = [self.route durationWithDictionary:dictionary];

  expect(actual).to.equal(expected);
}

- (void) testDurationWithDictionaryDurationKey {
  NSDictionary *dictionary = @{ @"duration" : @(5.0) };

  CGFloat expected = 5.0;
  CGFloat actual = [self.route durationWithDictionary:dictionary];

  expect(actual).to.equal(expected);
}

- (void) stringForApplicationState {
  NSString *actual;

  actual = [self.route stringForApplicationState:UIApplicationStateActive];
  expect(actual).to.equal(@"active");

  actual = [self.route stringForApplicationState:UIApplicationStateInactive];
  expect(actual).to.equal(@"inactive");

  actual = [self.route stringForApplicationState:UIApplicationStateBackground];
  expect(actual).to.equal(@"background");

  actual = [self.route stringForApplicationState:(UIApplicationState)NSNotFound];
  expect(actual).to.equal(@"unknown");
}

@end
