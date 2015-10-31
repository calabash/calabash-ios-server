#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import <XCTest/XCTest.h>
#import "LPShakeAppRoute.h"

@interface LPShakeAppRoute (LPXCTEST)

- (CGFloat) durationWithDictionary:(NSDictionary *) arguments;

@end

@interface LPShakeAppRouteTest : XCTestCase

@property (nonatomic, strong) LPShakeAppRoute *route;

@end

@implementation LPShakeAppRouteTest

- (void)setUp {
  [super setUp];
  self.route = [LPShakeAppRoute new];
}

- (void)tearDown {
  [super tearDown];
  self.route = nil;
}

- (void) testSupportsMethodGET {
  BOOL actual = [self.route supportsMethod:@"GET" atPath:nil];
  expect(actual).to.equal(YES);
}

- (void) testSupportsNoOtherMethod {
  BOOL actual = [self.route supportsMethod:@"POST" atPath:nil];
  expect(actual).to.equal(NO);

  actual = [self.route supportsMethod:@"FOO" atPath:nil];
  expect(actual).to.equal(NO);
}

- (void) testDurationWithDictionaryNoDurationKey {
  NSDictionary *dictionary = @{};

  CGFloat expected = 0.1;
  CGFloat actual = [self.route durationWithDictionary:dictionary];

  expect(actual).to.equal(expected);
}

- (void) testDurationWithDictionaryDurationKey {
  NSDictionary *dictionary = @{@"duration" : @(3.0)};

  CGFloat expected = 3.0;
  CGFloat actual = [self.route durationWithDictionary:dictionary];

  expect(actual).to.equal(expected);
}

@end
