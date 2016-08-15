#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import <XCTest/XCTest.h>
#import "LPSetDeviceOrientationRoute.h"
#import "LPOrientationOperation.h"

@interface UIDevice (LP_DEVICE_ORIENTATION_CATEGORY)

-(void)setOrientation:(NSInteger)orientation animated:(BOOL)animated;
@end

@interface LPSetDeviceOrientationRoute (LPTEST)

- (NSInteger)orientationWithDictionary:(NSDictionary *)arguments;
- (NSInteger)orientationForString:(NSString *)string;
- (BOOL)isValidUIDeviceOrientation:(NSInteger)orientation;

@end

@interface LPSetDeviceOrientationRouteTest : XCTestCase

@property(atomic, strong) LPSetDeviceOrientationRoute *route;

@end

@implementation LPSetDeviceOrientationRouteTest

- (void)setUp {
  [super setUp];
  self.route = [LPSetDeviceOrientationRoute new];
}

- (void)tearDown {
  self.route = nil;
  [super tearDown];
}

- (void)testRespondsToPOST {
  BOOL actual = [self.route supportsMethod:@"POST" atPath:nil];
  expect(actual).to.equal(YES);
}

- (void)testDoesNotRespondToGET {
  BOOL actual = [self.route supportsMethod:@"GET" atPath:nil];
  expect(actual).to.equal(NO);
}

- (void)testOrientationForStringUpsideDown {
  NSInteger expected = (NSInteger)UIDeviceOrientationPortraitUpsideDown;

  expect([self.route orientationForString:@"up"]).to.equal(expected);
  expect([self.route orientationForString:@"top"]).to.equal(expected);
  expect([self.route orientationForString:@"upside down"]).to.equal(expected);
}

- (void)testOrientationForStringPortrait {
  NSInteger expected = (NSInteger)UIDeviceOrientationPortrait;

  expect([self.route orientationForString:@"bottom"]).to.equal(expected);
  expect([self.route orientationForString:@"down"]).to.equal(expected);
  expect([self.route orientationForString:@"portrait"]).to.equal(expected);
}

- (void)testOrientationForStringLandscapeRight {
  NSInteger expected = (NSInteger)UIDeviceOrientationLandscapeRight;

  expect([self.route orientationForString:@"left"]).to.equal(expected);
  expect([self.route orientationForString:@"landscape right"]).to.equal(expected);
}

- (void)testOrientationForStringLandscapeLeft {
  NSInteger expected = (NSInteger)UIDeviceOrientationLandscapeLeft;

  expect([self.route orientationForString:@"right"]).to.equal(expected);
  expect([self.route orientationForString:@"landscape left"]).to.equal(expected);
}

- (void)testOrientationForStringUnexpectedInput {
  NSInteger expected = (NSInteger)UIDeviceOrientationPortrait;

  expect([self.route orientationForString:@"face down"]).to.equal(expected);
  expect([self.route orientationForString:@"face up"]).to.equal(expected);
  expect([self.route orientationForString:@"unknown"]).to.equal(expected);
  expect([self.route orientationForString:nil]).to.equal(expected);
}

- (void)testIsValidDeviceOrientationYES {
  expect([self.route isValidUIDeviceOrientation:UIDeviceOrientationPortrait]).to.equal(YES);
  expect([self.route isValidUIDeviceOrientation:UIDeviceOrientationPortraitUpsideDown]).to.equal(YES);
  expect([self.route isValidUIDeviceOrientation:UIDeviceOrientationLandscapeLeft]).to.equal(YES);
  expect([self.route isValidUIDeviceOrientation:UIDeviceOrientationLandscapeRight]).to.equal(YES);
}

- (void)testIsValidDeviceOrientationNO {
  expect([self.route isValidUIDeviceOrientation:UIDeviceOrientationPortrait - 1]).to.equal(NO);
  expect([self.route isValidUIDeviceOrientation:UIDeviceOrientationLandscapeRight + 1]).to.equal(NO);
}

- (void)testOrientationWithDictionaryNoValueForKey {
  NSDictionary *args = @{};

  expect([self.route orientationWithDictionary:args]).to.equal(1);
}

- (void)testOrientationWithDictionaryStringValue {
  NSDictionary *args = @{
                         @"orientation" : @"string"
                         };
  NSInteger expected = 10;
  id mock = OCMPartialMock(self.route);
  OCMExpect([mock orientationForString:@"string"]).andReturn(expected);
  OCMExpect([mock isValidUIDeviceOrientation:expected]).andReturn(YES);

  NSInteger actual = [self.route orientationWithDictionary:args];
  expect(actual).to.equal(expected);

  OCMVerifyAll(mock);
}

- (void)testOrientationWithDictionaryNumberValue {
  NSInteger expected = 10;
  NSDictionary *args = @{
                         @"orientation" : @(expected)
                         };

  id mock = OCMPartialMock(self.route);
  OCMExpect([mock isValidUIDeviceOrientation:expected]).andReturn(YES);

  NSInteger actual = [self.route orientationWithDictionary:args];
  expect(actual).to.equal(expected);

  OCMVerifyAll(mock);
}

- (void)testOrientationWithDictionaryInvalidObjectType {
  NSInteger expected = (NSInteger)UIDeviceOrientationPortrait;
  NSDictionary *args = @{
                         @"orientation" : @[]
                         };

  id mock = OCMPartialMock(self.route);
  OCMExpect([mock isValidUIDeviceOrientation:expected]).andReturn(YES);

  NSInteger actual = [self.route orientationWithDictionary:args];
  expect(actual).to.equal(expected);
}

- (void)testJSONResponseForMethod {
  id klassMock = OCMClassMock([LPOrientationOperation class]);
  OCMExpect([klassMock statusBarOrientation]).andReturn(@"status bar orientation");
  OCMExpect([klassMock deviceOrientation]).andReturn(@"device orientation");

  id routeMock = OCMPartialMock(self.route);
  NSDictionary *args = @{
                         @"orientation" : @(4)
                         };
  OCMExpect([routeMock orientationWithDictionary:args]).andReturn(4);

  id deviceMock = OCMPartialMock([UIDevice currentDevice]);
  OCMExpect([deviceMock setOrientation:4 animated:YES]).andForwardToRealObject();

  NSDictionary *actual = [routeMock JSONResponseForMethod:nil URI:nil data:args];
  expect(actual[@"outcome"]).to.equal(@"SUCCESS");
  expect(actual[@"results"]).notTo.equal(nil);

  NSDictionary *results = actual[@"results"];

  expect(results[@"device_orientation"]).to.equal(@"device orientation");
  expect(results[@"status_bar_orientation"]).to.equal(@"status bar orientation");

  OCMVerifyAll(klassMock);
  OCMVerifyAll(deviceMock);
  OCMVerifyAll(routeMock);
}

@end
