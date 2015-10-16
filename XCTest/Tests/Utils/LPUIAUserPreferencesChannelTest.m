#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import <XCTest/XCTest.h>
#import "LPUIAUserPrefsChannel.h"

@interface LPUIAUserPrefsChannel (LPXCTEST)

- (NSString *) simulatorPreferencesPath;

@end

@interface LPUIAUserPreferencesChannelTest : XCTestCase

@end

@implementation LPUIAUserPreferencesChannelTest

- (void)setUp {
  [super setUp];
}

- (void)tearDown {
  [super tearDown];
}

#if TARGET_IPHONE_SIMULATOR
- (void) testSimulatorPreferencesPathLazyEvaled {
  LPUIAUserPrefsChannel *channel = [LPUIAUserPrefsChannel sharedChannel];

  NSString *firstCall = [channel simulatorPreferencesPath];
  expect(firstCall).notTo.equal(nil);

  NSString *secondCall = [channel simulatorPreferencesPath];
  XCTAssertEqual(firstCall, secondCall);
}
#endif

@end
