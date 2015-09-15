#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPDevice.h"
#import "LPTouchUtils.h"

static NSString *const LPiPhone6SimVersionInfo = @"Device: iPhone 6 - Runtime: iOS 8.1 (12B411) - DeviceType: iPhone 6";

static NSString *const LPiPhone6PlusSimVersionInfo = @"CoreSimulator 110.4 - Device: iPhone 6 Plus - Runtime: iOS 8.1 (12B411) - DeviceType: iPhone 6 Plus";

static NSString *const LPiPhone5sSimVersionInfo = @"CoreSimulator 110.4 - Device: iPhone 5s - Runtime: iOS 8.1 (12B411) - DeviceType: iPhone 5s";

@interface LPDevice (LPXCTEST)

- (id) init_private;
- (NSString *) physicalDeviceModelIdentifier;
- (NSPredicate *) iPhone6SimPredicate;
- (NSPredicate *) iPhone6PlusSimPredicate;
- (NSDictionary *) processEnvironment;
- (NSString *) simulatorModelIdentfier;
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

- (void) testModelIdentiferReturnsSomething {
  expect([self.device simulatorModelIdentfier]).notTo.equal(nil);
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

- (void) testModelIdentiferReturnsNothing {
  expect([self.device simulatorModelIdentfier]).to.equal(nil);
}

- (void) testSimulatorVersionReturnsNothing {
  expect([self.device simulatorVersionInfo]).to.equal(nil);
}

- (void) testSimulator {
  expect([self.device simulator]).to.equal(NO);
}

- (void) testPhysicalDevice {
  expect([self.device physicalDevice]).to.equal(YES);
}

- (void) testPhysicalDeviceHardwareNameReturnsSomething {
  NSString *actual = [self.device physicalDeviceModelIdentifier];
  expect(actual).notTo.equal(nil);
  expect(actual).notTo.equal(@"");
}

#endif

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

  expect([self.device simulatorModelIdentfier]).to.equal(@"apples");

  [mock verify];
}

- (void) testSimulatorModelIdentifierKeyNotFound {
  NSDictionary *env = @{};
  id mock = OCMPartialMock(self.device);
  [[[mock expect] andReturn:env] processEnvironment];

  expect([self.device simulatorModelIdentfier]).to.equal(nil);

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
  OCMStub([mock simulatorModelIdentfier]).andReturn(@"anything");

  expect([self.device isSimulator]).to.equal(YES);

  OCMVerify([mock simulatorModelIdentfier]);
}

- (void) testSimulatorNO {
  id mock = OCMPartialMock(self.device);
  OCMStub([mock simulatorModelIdentfier]).andReturn(nil);

  expect([self.device isSimulator]).to.equal(NO);

  OCMVerify([mock simulatorModelIdentfier]);
}

- (void) testIPadYES {
  id mock = OCMPartialMock([UIDevice currentDevice]);
  BOOL ipadIdiom = UIUserInterfaceIdiomPad;
  [[[mock stub] andReturnValue:OCMOCK_VALUE(ipadIdiom)] userInterfaceIdiom];

  expect([self.device iPad]).to.equal(YES);
}

- (void) testIPadNO {
  id mock = OCMPartialMock([UIDevice currentDevice]);
  BOOL ipadIdiom = UIUserInterfaceIdiomPhone;
  [[[mock stub] andReturnValue:OCMOCK_VALUE(ipadIdiom)] userInterfaceIdiom];

  expect([self.device iPad]).to.equal(NO);
}

- (void) testSystemSimulator {
  id mock = OCMPartialMock(self.device);
  OCMExpect([mock isSimulator]).andReturn(YES);
  OCMExpect([mock simulatorModelIdentfier]).andReturn(@"simulator");

  expect([mock system]).to.equal(@"simulator");

  OCMVerifyAll(mock);
}

- (void) testSystemPhysicalDevice {
  id mock = OCMPartialMock(self.device);
  OCMExpect([mock isSimulator]).andReturn(NO);
  OCMExpect([mock physicalDeviceModelIdentifier]).andReturn(@"physical device");

  expect([mock system]).to.equal(@"physical device");

  OCMVerifyAll(mock);
}

- (void) testFormFactorIpad {
  id mock = OCMPartialMock(self.device);
  OCMExpect([mock iPad]).andReturn(YES);
  OCMExpect([mock formFactorMap]).andReturn(@{});

  expect([mock formFactor]).to.equal(@"ipad");

  OCMVerifyAll(mock);
}

- (void) testFormFactorIpadPro {
  id mock = OCMPartialMock(self.device);
  OCMExpect([mock system]).andReturn(@"iPad6,8");

  expect([mock formFactor]).to.equal(@"ipad pro");

  OCMVerifyAll(mock);
}

- (void) testFormFactorUnknown {
  id mock = OCMPartialMock(self.device);
  OCMExpect([mock system]).andReturn(@"iPhone30,30");
  OCMExpect([mock iPad]).andReturn(NO);
  OCMExpect([mock formFactorMap]).andReturn(@{});

  expect([mock formFactor]).to.equal(@"iPhone30,30");

  OCMVerifyAll(mock);
}

- (void) testFormFactorHasValueInMap {
  NSString *modelIdentifier = [self.device system];
  NSString *actual = [self.device formFactor];

  expect(actual).notTo.equal(modelIdentifier);
}



@end

SpecBegin(LPDevice)

describe(@"LPDevice", ^{

  __block BOOL yes = YES;
  __block BOOL no = NO;

  describe(@"init", ^{
    expect(^{
      LPDevice __unused *tmp = [[LPDevice alloc] init];
    }).to.raiseAny();
  });

  it(@"sharedDevice", ^{
    LPDevice *shared = [LPDevice sharedDevice];
    NSDictionary *dims = shared.screenDimensions;
    expect(dims).notTo.beNil();
    expect(dims.count).to.equal(4);
    expect(dims[@"height"]).to.beAKindOf([NSNumber class]);
    expect(dims[@"width"]).to.beAKindOf([NSNumber class]);
    expect(dims[@"scale"]).to.beAKindOf([NSNumber class]);
    expect(dims[@"sample"]).to.beAKindOf([NSNumber class]);

    expect(shared).to.beIdenticalTo([LPDevice sharedDevice]);
  });

  it(@"#system", ^{
    LPDevice *device = [[LPDevice alloc] init_private];
    expect([device system]).notTo.beNil();
  });

  it(@"#model", ^{
    LPDevice *device = [[LPDevice alloc] init_private];
    expect([device model]).notTo.beNil();
  });

  it(@"#iPhone6SimPredicate", ^{
    LPDevice *device = [[LPDevice alloc] init_private];
    NSPredicate *pred = [device iPhone6SimPredicate];
    NSString *expected = @"SIMULATOR_VERSION_INFO LIKE \"*iPhone 6*\" AND (NOT SIMULATOR_VERSION_INFO LIKE \"*iPhone 6*Plus*\")";
    expect([pred description]).to.equal(expected);
  });

  it(@"#iPhone6PlusSimPredicate", ^{
    LPDevice *device = [[LPDevice alloc] init_private];
    NSPredicate *pred = [device iPhone6PlusSimPredicate];
    NSString *expected = @"SIMULATOR_VERSION_INFO LIKE \"*iPhone 6*Plus*\"";
    expect([pred description]).to.equal(expected);
  });

  describe(@"#iPhone6", ^{
    describe(@"simulator", ^{
      __block LPDevice *device;
      __block id mockDevice;
      __block id processInfo;

      beforeEach(^{
        device = [[LPDevice alloc] init_private];
        mockDevice = OCMPartialMock(device);
        [[[mockDevice expect] andReturnValue:OCMOCK_VALUE(yes)] isSimulator];

        processInfo = OCMPartialMock([NSProcessInfo processInfo]);
      });

      afterEach(^{
        [processInfo stopMocking];
      });

      describe(@"returns NO", ^{
        it(@"when iPhone 6 Plus", ^{
          NSDictionary *env = @{@"SIMULATOR_VERSION_INFO" : LPiPhone6PlusSimVersionInfo};
          [[[processInfo stub] andReturn:env] environment];

          expect(device.iPhone6).to.equal(NO);
          [mockDevice verify];
          [processInfo verify];
        });

        it(@"when not iPhone 6 form factor", ^{
          NSDictionary *env = @{@"SIMULATOR_VERSION_INFO" : LPiPhone5sSimVersionInfo};
          [[[processInfo stub] andReturn:env] environment];

          expect(device.iPhone6).to.equal(NO);
          [mockDevice verify];
          [processInfo verify];
        });
      });

      it(@"returns YES", ^{
        NSDictionary *env = @{@"SIMULATOR_VERSION_INFO" : LPiPhone6SimVersionInfo};
        [[[processInfo stub] andReturn:env] environment];

        expect(device.iPhone6).to.equal(YES);
        [mockDevice verify];
        [processInfo verify];
      });
    });

    describe(@"device", ^{
      __block LPDevice *device;
      __block id mockDevice;

      beforeEach(^{
        device = [[LPDevice alloc] init_private];
        mockDevice = OCMPartialMock(device);
        [[[mockDevice expect] andReturnValue:OCMOCK_VALUE(no)] isSimulator];
      });

      it(@"returns NO", ^{
        [[[mockDevice expect] andReturn:@"Some Machine"] system];
        expect(device.iPhone6).to.equal(NO);
        [mockDevice verify];
      });

      it(@"returns YES", ^{
        [[[mockDevice expect] andReturn:@"iPhone7,2"] system];
        expect(device.iPhone6).to.equal(YES);
        [mockDevice verify];
      });
    });
  });

  describe(@"#iPhone6Plus", ^{
    describe(@"simulator", ^{
      __block LPDevice *device;
      __block id mockDevice;
      __block id processInfo;

      beforeEach(^{
        device = [[LPDevice alloc] init_private];
        mockDevice = OCMPartialMock(device);
        [[[mockDevice expect] andReturnValue:OCMOCK_VALUE(yes)] isSimulator];

        processInfo = OCMPartialMock([NSProcessInfo processInfo]);
      });

      afterEach(^{
        [processInfo stopMocking];
      });

      describe(@"returns NO", ^{
        it(@"when iPhone 6", ^{
          NSDictionary *env = @{@"SIMULATOR_VERSION_INFO" : LPiPhone6SimVersionInfo};
          [[[processInfo stub] andReturn:env] environment];

          expect(device.iPhone6Plus).to.equal(NO);
          [mockDevice verify];
          [processInfo verify];
        });

        it(@"when not iPhone 6 form factor", ^{
          NSDictionary *env = @{@"SIMULATOR_VERSION_INFO" : LPiPhone5sSimVersionInfo};
          [[[processInfo stub] andReturn:env] environment];

          expect(device.iPhone6).to.equal(NO);
          [mockDevice verify];
          [processInfo verify];
        });
      });

      it(@"returns YES", ^{
        NSDictionary *env = @{@"SIMULATOR_VERSION_INFO" : LPiPhone6PlusSimVersionInfo};
        [[[processInfo stub] andReturn:env] environment];

        expect(device.iPhone6Plus).to.equal(YES);
        [mockDevice verify];
        [processInfo verify];
      });
    });

    describe(@"device", ^{
      __block LPDevice *device;
      __block id mockDevice;

      beforeEach(^{
        device = [[LPDevice alloc] init_private];
        mockDevice = OCMPartialMock(device);
        [[[mockDevice expect] andReturnValue:OCMOCK_VALUE(no)] isSimulator];
      });

      it(@"returns NO", ^{
        [[[mockDevice expect] andReturn:@"Some Machine"] system];
        expect(device.iPhone6Plus).to.equal(NO);
        [mockDevice verify];
      });

      it(@"returns YES", ^{
        [[[mockDevice expect] andReturn:@"iPhone7,1"] system];
        expect(device.iPhone6Plus).to.equal(YES);
        [mockDevice verify];
      });
    });
  });
});

SpecEnd
