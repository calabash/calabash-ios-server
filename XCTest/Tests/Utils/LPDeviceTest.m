#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPDevice.h"

static NSString *const LPiPhone6SimVersionInfo = @"Device: iPhone 6 - Runtime: iOS 8.1 (12B411) - DeviceType: iPhone 6";

static NSString *const LPiPhone6PlusSimVersionInfo = @"CoreSimulator 110.4 - Device: iPhone 6 Plus - Runtime: iOS 8.1 (12B411) - DeviceType: iPhone 6 Plus";

static NSString *const LPiPhone5sSimVersionInfo = @"CoreSimulator 110.4 - Device: iPhone 5s - Runtime: iOS 8.1 (12B411) - DeviceType: iPhone 5s";

@interface LPDevice (LPXCTEST)

- (id) init_private;

- (UIScreen *) mainScreen;
- (UIScreenMode *) currentScreenMode;
- (CGSize) sizeForCurrentScreenMode;
- (CGFloat) scaleForMainScreen;
- (CGFloat) heightForMainScreenBounds;
- (NSString *) physicalDeviceModelIdentifier;
- (NSPredicate *) iPhone6SimPredicate;
- (NSPredicate *) iPhone6PlusSimPredicate;
- (NSDictionary *) processEnvironment;
- (NSString *) simulatorVersionInfo;
- (NSDictionary *) formFactorMap;

@end

@interface LPDeviceTest : XCTestCase

@property(nonatomic, strong) LPDevice *device;

@end

@implementation LPDeviceTest

- (void)setUp {
  [super setUp];
  self.device = [[LPDevice alloc] init_private];
}

- (void)tearDown {
  [super tearDown];
  self.device = nil;
}

#if TARGET_IPHONE_SIMULATOR

- (void) testSimulatorModelIdentiferReturnsSomething {
  expect([self.device simulatorModelIdentifier]).notTo.equal(nil);
}

- (void) testSimulatorVersionReturnsSomething {
  expect([self.device simulatorVersionInfo]).notTo.equal(nil);
}

- (void) testSimulator {
  expect([self.device isSimulator]).to.equal(YES);
}

- (void) testPhysicalDevice {
  expect([self.device isPhysicalDevice]).to.equal(NO);
}

#else

- (void) testSimulatorModelIdentifierReturnsNothing {
  expect([self.device simulatorModelIdentifier]).to.equal(nil);
}

- (void) testSimulatorVersionReturnsNothing {
  expect([self.device simulatorVersionInfo]).to.equal(nil);
}

- (void) testSimulator {
  expect([self.device isSimulator]).to.equal(NO);
}

- (void) testPhysicalDevice {
  expect([self.device isPhysicalDevice]).to.equal(YES);
}

- (void) testPhysicalDeviceModelIdentifierReturnsSomething {
  NSString *actual = [self.device physicalDeviceModelIdentifier];
  expect(actual).notTo.equal(nil);
  expect(actual).notTo.equal(@"");
}

#endif

- (void) testiOSVersionReturnsSomething {
  NSString *actual = [self.device iOSVersion];
  expect(actual).notTo.equal(nil);
  expect(actual).notTo.equal(@"");
}

- (void) testProcessEnvironment {
  NSDictionary *dictionary = [self.device processEnvironment];
  expect([dictionary count]).notTo.equal(0);
  NSDictionary *memomized = [self.device processEnvironment];
  XCTAssertEqual(dictionary, memomized);
}

- (void) testSimulatorModelIdentifierKeyFound {
  NSDictionary *env = @{LPDeviceSimKeyModelIdentifier : @"apples"};
  id mock = OCMPartialMock(self.device);
  [[[mock expect] andReturn:env] processEnvironment];

  expect([self.device simulatorModelIdentifier]).to.equal(@"apples");

  [mock verify];
}

- (void) testSimulatorModelIdentifierKeyNotFound {
  NSDictionary *env = @{};
  id mock = OCMPartialMock(self.device);
  [[[mock expect] andReturn:env] processEnvironment];

  expect([self.device simulatorModelIdentifier]).to.equal(nil);

  [mock verify];
}

- (void) testSimulatorVersionInfoKeyFound {
  NSDictionary *env = @{LPDeviceSimKeyVersionInfo : @"oranges"};
  id mock = OCMPartialMock(self.device);
  [[[mock expect] andReturn:env] processEnvironment];

  expect([self.device simulatorVersionInfo]).to.equal(@"oranges");

  [mock verify];
}

- (void) testSimulatorVersionInfoKeyNotFound {
  NSDictionary *env = @{};
  id mock = OCMPartialMock(self.device);
  [[[mock expect] andReturn:env] processEnvironment];

  expect([self.device simulatorVersionInfo]).to.equal(nil);

  [mock verify];
}

- (void) testSimulatorYES {
  id mock = OCMPartialMock(self.device);
  OCMStub([mock simulatorModelIdentifier]).andReturn(@"anything");

  expect([self.device isSimulator]).to.equal(YES);

  OCMVerify([mock simulatorModelIdentifier]);
}

- (void) testSimulatorNO {
  id mock = OCMPartialMock(self.device);
  OCMStub([mock simulatorModelIdentifier]).andReturn(nil);

  expect([self.device isSimulator]).to.equal(NO);

  OCMVerify([mock simulatorModelIdentifier]);
}

- (void) testIPadYES {
  id mock = OCMPartialMock([UIDevice currentDevice]);
  BOOL ipadIdiom = UIUserInterfaceIdiomPad;
  [[[mock stub] andReturnValue:OCMOCK_VALUE(ipadIdiom)] userInterfaceIdiom];

  expect([self.device isIPad]).to.equal(YES);
}

- (void) testIPadNO {
  id mock = OCMPartialMock([UIDevice currentDevice]);
  BOOL ipadIdiom = UIUserInterfaceIdiomPhone;
  [[[mock stub] andReturnValue:OCMOCK_VALUE(ipadIdiom)] userInterfaceIdiom];

  expect([self.device isIPad]).to.equal(NO);
}

- (void) testSystemSimulator {
  id mock = OCMPartialMock(self.device);
  OCMExpect([mock isSimulator]).andReturn(YES);
  OCMExpect([mock simulatorModelIdentifier]).andReturn(@"simulator");

  expect([mock modelIdentifier]).to.equal(@"simulator");

  OCMVerifyAll(mock);
}

- (void) testSystemPhysicalDevice {
  id mock = OCMPartialMock(self.device);
  OCMExpect([mock isSimulator]).andReturn(NO);
  OCMExpect([mock physicalDeviceModelIdentifier]).andReturn(@"physical device");

  expect([mock modelIdentifier]).to.equal(@"physical device");

  OCMVerifyAll(mock);
}

- (void) testFormFactorIpad {
  id mock = OCMPartialMock(self.device);
  OCMExpect([mock isIPad]).andReturn(YES);
  OCMExpect([mock formFactorMap]).andReturn(@{});

  expect([mock formFactor]).to.equal(@"ipad");

  OCMVerifyAll(mock);
}

- (void) testFormFactorUnknown {
  id mock = OCMPartialMock(self.device);
  OCMExpect([mock modelIdentifier]).andReturn(@"iPhone30,30");
  OCMExpect([mock isIPad]).andReturn(NO);
  OCMExpect([mock formFactorMap]).andReturn(@{});

  expect([mock formFactor]).to.equal(@"iPhone30,30");

  OCMVerifyAll(mock);
}

- (void) testFormFactorHasValueInMap {
  NSString *modelIdentifier = [self.device modelIdentifier];
  NSString *formFactor = [self.device formFactor];

  expect(modelIdentifier).notTo.equal(nil);
  expect(formFactor).notTo.equal(nil);
}

- (void) testIsIPhone4LikeYES {
  id mock = OCMPartialMock(self.device);
  OCMExpect([mock formFactor]).andReturn(@"iphone 3.5in");

  expect([mock isIPhone4Like]).to.equal(YES);

  OCMVerifyAll(mock);
}

- (void) testIsIphone4LikeNO {
  id mock = OCMPartialMock(self.device);
  OCMExpect([mock formFactor]).andReturn(@"garbage");

  expect([mock isIPhone4Like]).to.equal(NO);

  OCMVerifyAll(mock);
}

- (void) testIsIPhone5LikeYES {
  id mock = OCMPartialMock(self.device);
  OCMExpect([mock formFactor]).andReturn(@"iphone 4in");

  expect([mock isIPhone5Like]).to.equal(YES);

  OCMVerifyAll(mock);
}

- (void) testIsIphone5LikeNO {
  id mock = OCMPartialMock(self.device);
  OCMExpect([mock formFactor]).andReturn(@"garbage");

  expect([mock isIPhone5Like]).to.equal(NO);

  OCMVerifyAll(mock);
}

- (void) testIsIPadProYES {
  id mock = OCMPartialMock(self.device);
  OCMExpect([mock formFactor]).andReturn(@"ipad pro FORM FACTOR");

  expect([mock isIPadPro]).to.equal(YES);

  OCMVerifyAll(mock);
}

- (void) testIsIPadProNO {
  id mock = OCMPartialMock(self.device);
  OCMExpect([mock formFactor]).andReturn(@"garbage");

  expect([mock isIPadPro]).to.equal(NO);

  OCMVerifyAll(mock);
}

- (void) testIsIpadPro12point9inchYES {
  id mock = OCMPartialMock(self.device);
  OCMExpect([mock modelIdentifier]).andReturn(@"ipad pro 12.9");

  expect([mock isIPadPro12point9inch]).to.equal(YES);

  OCMVerifyAll(mock);
}

- (void) testIsIpadPro12point9inchNO {
  id mock = OCMPartialMock(self.device);
  OCMExpect([mock modelIdentifier]).andReturn(@"garbage");

  expect([mock isIPadPro12point9inch]).to.equal(NO);

  OCMVerifyAll(mock);
}

- (void) testIsIpadPro9point7inchYES {
  id mock = OCMPartialMock(self.device);
  OCMExpect([mock modelIdentifier]).andReturn(@"ipad pro 9.7");

  expect([mock isIPadPro9point7inch]).to.equal(YES);

  OCMVerifyAll(mock);
}

- (void) testIsIpadPro9point7inchNO {
  id mock = OCMPartialMock(self.device);
  OCMExpect([mock modelIdentifier]).andReturn(@"garbage");

  expect([mock isIPadPro9point7inch]).to.equal(NO);

  OCMVerifyAll(mock);
}

- (void) testIsIpad9point7inchYES {
  id mock = OCMPartialMock(self.device);
  OCMExpect([mock modelIdentifier]).andReturn(@"ipad 9.7");

  expect([mock isIPad9point7inch]).to.equal(YES);

  OCMVerifyAll(mock);
}

- (void) testIsIpad9point7inchNO {
  id mock = OCMPartialMock(self.device);
  OCMExpect([mock modelIdentifier]).andReturn(@"garbage");

  expect([mock isIPad9point7inch]).to.equal(NO);

  OCMVerifyAll(mock);
}

- (void) testIsIpadPro10point5inchYES {
  id mock = OCMPartialMock(self.device);
  OCMExpect([mock modelIdentifier]).andReturn(@"ipad pro 10.5");

  expect([mock isIPadPro10point5inch]).to.equal(YES);

  OCMVerifyAll(mock);
}

- (void) testIsIpadPro10point5inchNO {
  id mock = OCMPartialMock(self.device);
  OCMExpect([mock modelIdentifier]).andReturn(@"garbage");

  expect([mock isIPadPro10point5inch]).to.equal(NO);

  OCMVerifyAll(mock);
}

- (void) testIsIPhone6LikeYES {
  id mock = OCMPartialMock(self.device);
  OCMExpect([mock formFactor]).andReturn(@"iphone 6");

  expect([mock isIPhone6Like]).to.equal(YES);

  OCMVerifyAll(mock);
}

- (void) testIsIPhone6LikeNO {
  id mock = OCMPartialMock(self.device);
  OCMExpect([mock formFactor]).andReturn(@"garbage");

  expect([mock isIPhone6Like]).to.equal(NO);

  OCMVerifyAll(mock);
}

- (void) testIsIPhone6PlusLikeYES {
  id mock = OCMPartialMock(self.device);
  OCMExpect([mock formFactor]).andReturn(@"iphone 6+");

  expect([mock isIPhone6PlusLike]).to.equal(YES);

  OCMVerifyAll(mock);
}

- (void) testIsIPhone6PlusLikeNO {
  id mock = OCMPartialMock(self.device);
  OCMExpect([mock formFactor]).andReturn(@"garbage");

  expect([mock isIPhone6PlusLike]).to.equal(NO);

  OCMVerifyAll(mock);
}

- (void) testisIPhone10LikeYES {
  id mock = OCMPartialMock(self.device);
  OCMExpect([mock formFactor]).andReturn(@"iphone 10");

  expect([mock isIPhone10Like]).to.equal(YES);

  OCMVerifyAll(mock);
}

- (void) testisIPhone10SMaxLikeYES {
  id mock = OCMPartialMock(self.device);
  OCMExpect([mock formFactor]).andReturn(@"iphone 10s max");

  expect([mock isIPhone10SMaxLike]).to.equal(YES);

  OCMVerifyAll(mock);
}

- (void) testisIPhone10RLikeYES {
  id mock = OCMPartialMock(self.device);
  OCMExpect([mock formFactor]).andReturn(@"iphone 10r");

  expect([mock isIPhone10RLike]).to.equal(YES);

  OCMVerifyAll(mock);
}

- (void) testisIphone11LikeYES {
  id mock = OCMPartialMock(self.device);
  OCMExpect([mock formFactor]).andReturn(@"iphone 10r");

  expect([mock isIPhone11Like]).to.equal(YES);

  OCMVerifyAll(mock);
}

- (void) testisIphone11ProLikeYES {
  id mock = OCMPartialMock(self.device);
  OCMExpect([mock formFactor]).andReturn(@"iphone 10");

  expect([mock isIPhone11ProLike]).to.equal(YES);

  OCMVerifyAll(mock);
}

- (void) testisIphone11ProMaxLikeYES {
  id mock = OCMPartialMock(self.device);
  OCMExpect([mock formFactor]).andReturn(@"iphone 10s max");

  expect([mock isIPhone11ProMaxLike]).to.equal(YES);

  OCMVerifyAll(mock);
}

- (void) testisIPhone10LikeNO {
  id mock = OCMPartialMock(self.device);
  OCMExpect([mock formFactor]).andReturn(@"garbage");

  expect([mock isIPhone10Like]).to.equal(NO);

  OCMVerifyAll(mock);
}

- (void) testisIPhone10LetterBoxNO {
  id mock = OCMPartialMock(self.device);
  OCMExpect([mock isIPhone10Like]).andReturn(NO);

  expect([mock isIPhone10LetterBox]).to.equal(NO);

  OCMVerifyAll(mock);
}

- (void) testisIPhone10LetterBoxScreenHeightIsWrong {
  id mock = OCMPartialMock(self.device);
  OCMExpect([mock isIPhone10Like]).andReturn(YES);

  NSDictionary *dimensions = @{@"height" : @(2436)};
  OCMExpect([mock screenDimensions]).andReturn(dimensions);

  expect([mock isIPhone10LetterBox]).to.equal(NO);

  OCMVerifyAll(mock);
}

- (void) testisIPhone10LetterBoxScreenBoundsHeightIsWrong {
  id mock = OCMPartialMock(self.device);
  OCMExpect([mock isIPhone10Like]).andReturn(YES);

  NSDictionary *dimensions = @{
                               @"height" : @(2001),
                               @"bounds_portrait_height" : @(768)
                               };
  OCMExpect([mock screenDimensions]).andReturn(dimensions);

  expect([mock isIPhone10LetterBox]).to.equal(NO);

  OCMVerifyAll(mock);
}

- (void) testisIPhone10LetterBoxYES {
  id mock = OCMPartialMock(self.device);
  OCMExpect([mock isIPhone10Like]).andReturn(YES);

  NSDictionary *dimensions = @{
                               @"height" : @(2001),
                               @"bounds_portrait_height" : @(667)
                               };
  OCMExpect([mock screenDimensions]).andReturn(dimensions);


  expect([mock isIPhone10LetterBox]).to.equal(YES);

  OCMVerifyAll(mock);
}

- (void) testIsLetterBoxNoBecauseIpad {
  id mock = OCMPartialMock(self.device);
  OCMExpect([mock isIPad]).andReturn(YES);

  expect([mock isLetterBox]).to.equal(NO);

  OCMVerifyAll(mock);
}

- (void) testIsLetterBoxNoBecauseIPhone4Like {
  id mock = OCMPartialMock(self.device);
  OCMExpect([mock isIPad]).andReturn(NO);
  OCMExpect([mock isIPhone4Like]).andReturn(YES);

  expect([mock isLetterBox]).to.equal(NO);

  OCMVerifyAll(mock);
}

- (void) testIsLetterBoxNoScaleIsWrong {
  id mock = OCMPartialMock(self.device);
  OCMExpect([mock isIPad]).andReturn(NO);
  OCMExpect([mock isIPhone4Like]).andReturn(NO);
  OCMExpect([mock scaleForMainScreen]).andReturn(2.0);

  expect([mock isLetterBox]).to.equal(NO);

  OCMVerifyAll(mock);
}

- (void) testIsLetterBoxNoHeightIsWrong {
  id mock = OCMPartialMock(self.device);
  OCMExpect([mock isIPad]).andReturn(NO);
  OCMExpect([mock isIPhone4Like]).andReturn(NO);
  OCMExpect([mock scaleForMainScreen]).andReturn(2.0);
  OCMExpect([mock heightForMainScreenBounds]).andReturn(10);

  expect([mock isLetterBox]).to.equal(NO);

  OCMVerifyAll(mock);
}

- (void) testIsLetterBoxYES {
  id mock = OCMPartialMock(self.device);
  OCMExpect([mock isIPad]).andReturn(NO);
  OCMExpect([mock isIPhone4Like]).andReturn(NO);
  OCMExpect([mock scaleForMainScreen]).andReturn(2.0);
  OCMExpect([mock heightForMainScreenBounds]).andReturn(480);

  expect([mock isLetterBox]).to.equal(YES);

  OCMVerifyAll(mock);
}

- (void) testGetIPAddressIPv4 {
  NSString *ip = [self.device getIPAddress];
  expect(ip).notTo.equal(nil);
}

@end
