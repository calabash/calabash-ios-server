#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif


#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "LPTouchUtils.h"
#import <OCMock/OCMock.h>

@interface LPTouchUtils (TEST)

+ (BOOL) isLetterBox;

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

- (id)mock4inDevice:(BOOL)aValue {
  id touchUtilsMock = [OCMockObject mockForClass:[LPTouchUtils class]];
  [[[touchUtilsMock stub] andReturnValue:@(aValue)] is4InchDevice];
  return touchUtilsMock;
}

#pragma mark - isLetterBox

- (void) testIsLetterBox {

  [self mockCurrentDeviceWithIdiom:UIUserInterfaceIdiomPhone];
  [self mockMainScreenWithScale:2.0 height:480];
  [self mock4inDevice:YES];

  XCTAssert([LPTouchUtils isLetterBox]);
}

- (void) testIsLetterBoxWhenNotIphone {

  [self mockCurrentDeviceWithIdiom:UIUserInterfaceIdiomPad];
  [self mockMainScreenWithScale:2.0 height:480];
  [self mock4inDevice:YES];

  XCTAssertFalse([LPTouchUtils isLetterBox]);
}

- (void) testIsLetterBoxWhenNotRetina {
  [self mockCurrentDeviceWithIdiom:UIUserInterfaceIdiomPhone];
  [self mockMainScreenWithScale:1.0 height:480];
  [self mock4inDevice:YES];

  XCTAssertFalse([LPTouchUtils isLetterBox]);
}

- (void) testIsLetterBoxWhenNotCropped {
  [self mockCurrentDeviceWithIdiom:UIUserInterfaceIdiomPhone];
  [self mockMainScreenWithScale:2.0 height:568];
  [self mock4inDevice:YES];

  XCTAssertFalse([LPTouchUtils isLetterBox]);
}

- (void) testIsLetterBoxWhenNot4inchDevice {
  [self mockCurrentDeviceWithIdiom:UIUserInterfaceIdiomPhone];
  [self mockMainScreenWithScale:2.0 height:480];
  [self mock4inDevice:NO];

  XCTAssertFalse([LPTouchUtils isLetterBox]);
}


@end
