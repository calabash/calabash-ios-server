#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif


#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "LPTouchUtils.h"
#import <OCMock/OCMock.h>

@interface LPTouchUtils (TEST)

+ (BOOL) isLetterBox;
+ (NSString *) stringForSystemName;

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

#pragma mark - Mocking

- (id)mockCurrentDeviceWithIdiom:(UIUserInterfaceIdiom)aIdiom {
  id currentDeviceMock = [OCMockObject partialMockForObject:[UIDevice currentDevice]];
  [[[currentDeviceMock stub] andReturnValue:OCMOCK_VALUE(aIdiom)] userInterfaceIdiom];
  return currentDeviceMock;
}

- (id)mockMainScreenWithScale:(CGFloat)aScale
                       height:(CGFloat)aHeight {
  id mainScreenMock = [OCMockObject partialMockForObject:[UIScreen mainScreen]];
  [(UIScreen *)[[mainScreenMock stub] andReturnValue:OCMOCK_VALUE(aScale)] scale];
  CGRect mockBounds = CGRectMake(0, 0, 0, aHeight);
  [(UIScreen *)[[mainScreenMock stub] andReturnValue:OCMOCK_VALUE(mockBounds)] bounds];
  return mainScreenMock;
}

- (id)mockThreeAndAHalfInchDevice:(BOOL)aValue {
  id touchUtilsMock = [OCMockObject mockForClass:[LPTouchUtils class]];
  [[[touchUtilsMock stub] andReturnValue:@(aValue)] isThreeAndAHalfInchDevice];
  return touchUtilsMock;
}

#pragma mark - isLetterBox

- (void) testIsLetterBox {

  [self mockCurrentDeviceWithIdiom:UIUserInterfaceIdiomPhone];
  [self mockMainScreenWithScale:2.0 height:480];
  [self mockThreeAndAHalfInchDevice:NO];

  XCTAssert([LPTouchUtils isLetterBox]);
}

- (void) testIsLetterBoxWhenNotIphone {

  [self mockCurrentDeviceWithIdiom:UIUserInterfaceIdiomPad];
  [self mockMainScreenWithScale:2.0 height:480];
  [self mockThreeAndAHalfInchDevice:NO];

  XCTAssertFalse([LPTouchUtils isLetterBox]);
}

- (void) testIsLetterBoxWhenNotRetina {
  [self mockCurrentDeviceWithIdiom:UIUserInterfaceIdiomPhone];
  [self mockMainScreenWithScale:1.0 height:480];
  [self mockThreeAndAHalfInchDevice:NO];

  XCTAssertFalse([LPTouchUtils isLetterBox]);
}

- (void) testIsLetterBoxWhenNotCropped {
  [self mockCurrentDeviceWithIdiom:UIUserInterfaceIdiomPhone];
  [self mockMainScreenWithScale:2.0 height:568];
  [self mockThreeAndAHalfInchDevice:NO];

  XCTAssertFalse([LPTouchUtils isLetterBox]);
}

- (void) testIsLetterBoxWhenNot4inchDevice {
  [self mockCurrentDeviceWithIdiom:UIUserInterfaceIdiomPhone];
  [self mockMainScreenWithScale:2.0 height:480];
  [self mockThreeAndAHalfInchDevice:YES];

  XCTAssertFalse([LPTouchUtils isLetterBox]);
}

#pragma mark - isThreeAndAHalfInchDevice

// Marketing Name | Machine Name | Screen Size
// iPhone 3*      | iPhone3*     | 3.5
// iPhone 4*      | iPhone4*     | 3.5
// iPhone 5       | iPhone5*     | 4
// iPhone 5c      | iPhone5*     | 4
// iPhone 5c      | iPhone6*     | 4
// iPod   5       | iPod5*       | 4

- (void) testIsThreeAndAHalfInchDeviceWhenIsThreeAndAHalfInchSimulator {
  id currentDeviceMock = [OCMockObject partialMockForObject:[UIDevice currentDevice]];
  [[[currentDeviceMock stub] andReturnValue:OCMOCK_VALUE(@"iPhone Simulator")] model];

  NSDictionary *fakeEnvironment =
  @{
    @"SIMULATOR_VERSION_INFO":
      @"CoreSimulator 110.4 - Device: iPhone 4s - Runtime: iOS 8.1 (12B411) - DeviceType: iPhone 4s"
  };

  id processInfoStub = [OCMockObject partialMockForObject:[NSProcessInfo processInfo]];
  [[[processInfoStub stub] andReturn:fakeEnvironment] environment];

  XCTAssert([LPTouchUtils isThreeAndAHalfInchDevice]);
}

- (void) testIsThreeAndAHalfInchDeviceWhenIs4inchSimulator {
  id currentDeviceMock = [OCMockObject partialMockForObject:[UIDevice currentDevice]];
  [[[currentDeviceMock stub] andReturnValue:OCMOCK_VALUE(@"iPhone Simulator")] model];

  NSDictionary *fakeEnvironment =
  @{
    @"SIMULATOR_VERSION_INFO":
      @"CoreSimulator 110.4 - Device: iPhone 5 - Runtime: iOS 8.1 (12B411) - DeviceType: iPhone 5"
  };

  id processInfoStub = [OCMockObject partialMockForObject:[NSProcessInfo processInfo]];
  [[[processInfoStub stub] andReturn:fakeEnvironment] environment];

  XCTAssertFalse([LPTouchUtils isThreeAndAHalfInchDevice]);
}

- (void) testIsThreeAndAHalfInchDeviceWhenIs4inchDevice {
  id currentDeviceMock = [OCMockObject partialMockForObject:[UIDevice currentDevice]];
  [[[currentDeviceMock stub] andReturnValue:OCMOCK_VALUE(@"iPhone")] model];

  id touchUtilsMock = [OCMockObject mockForClass:[LPTouchUtils class]];
  [[[touchUtilsMock stub] andReturn:@"iPhone5"] stringForSystemName];

  XCTAssertFalse([LPTouchUtils isThreeAndAHalfInchDevice]);
}

- (void) testIsThreeAndAHalfInchDeviceWhenIsThreeAndAHalfInchDevice {
  id currentDeviceMock = [OCMockObject partialMockForObject:[UIDevice currentDevice]];
  [[[currentDeviceMock stub] andReturnValue:OCMOCK_VALUE(@"iPhone")] model];

  id touchUtilsMock = [OCMockObject mockForClass:[LPTouchUtils class]];
  [[[touchUtilsMock stub] andReturn:@"iPhone4"] stringForSystemName];

  XCTAssert([LPTouchUtils isThreeAndAHalfInchDevice]);
}

- (void) testIsThreeAndAHalfInchDeviceWhenIsFourInchIPod {
  id currentDeviceMock = [OCMockObject partialMockForObject:[UIDevice currentDevice]];
  [[[currentDeviceMock stub] andReturnValue:OCMOCK_VALUE(@"iPod")] model];

  id touchUtilsMock = [OCMockObject mockForClass:[LPTouchUtils class]];
  [[[touchUtilsMock stub] andReturn:@"iPod5"] stringForSystemName];

  XCTAssertFalse([LPTouchUtils isThreeAndAHalfInchDevice]);
}

@end
