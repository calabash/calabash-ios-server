#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPDevice.h"

static NSString *const LPiPhone6SimVersionInfo = @"Device: iPhone 6 - Runtime: iOS 8.1 (12B411) - DeviceType: iPhone 6";

static NSString *const LPiPhone6PlusSimVersionInfo = @"CoreSimulator 110.4 - Device: iPhone 6 Plus - Runtime: iOS 8.1 (12B411) - DeviceType: iPhone 6 Plus";

static NSString *const LPiPhone5sSimVersionInfo = @"CoreSimulator 110.4 - Device: iPhone 5s - Runtime: iOS 8.1 (12B411) - DeviceType: iPhone 5s";

@interface LPDevice (LPXCTEST)

- (id) init_private;
- (NSPredicate *) iPhone6SimPredicate;
- (NSPredicate *) iPhone6PlusSimPredicate;

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

  describe(@"#simulator", ^{
    it(@"returns NO", ^{
      LPDevice *device = [[LPDevice alloc] init_private];
      id currentDevice = OCMPartialMock([UIDevice currentDevice]);
      [[[currentDevice stub] andReturn:@"Anything but: iPhone Simulator"] model];
      expect(device.simulator).to.equal(NO);
    });

    it(@"returns YES", ^{
      LPDevice *device = [[LPDevice alloc] init_private];
      id currentDevice = OCMPartialMock([UIDevice currentDevice]);
      [[[currentDevice stub] andReturn:@"iPhone Simulator"] model];
      expect(device.simulator).to.equal(YES);
    });
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
        [[[mockDevice expect] andReturnValue:OCMOCK_VALUE(yes)] simulator];

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
      it(@"returns NO", ^{
        XCTAssertTrue(NO);
      });

      it(@"returns YES", ^{
        XCTAssertTrue(NO);
      });
    });
  });

  describe(@"#iPhone6Plus", ^{
    describe(@"simulator", ^{
      it(@"returns NO", ^{
        XCTAssertTrue(NO);
      });

      it(@"returns YES", ^{
        XCTAssertTrue(NO);
      });
    });

    describe(@"device", ^{
      it(@"returns NO", ^{
        XCTAssertTrue(NO);
      });

      it(@"returns YES", ^{
        XCTAssertTrue(NO);
      });
    });
  });
});

SpecEnd
