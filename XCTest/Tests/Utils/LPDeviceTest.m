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

  describe(@"#simulator", ^{
    __block LPDevice *device;
    __block id mockDevice;

    beforeEach(^{
      device = [[LPDevice alloc] init_private];
      mockDevice = OCMPartialMock(device);
    });

    it(@"returns NO", ^{
      [[[mockDevice expect] andReturn:@"Anything but: iPhone Simulator"] model];
      expect(device.simulator).to.equal(NO);
      [mockDevice verify];
    });

    it(@"returns YES", ^{
      [[[mockDevice expect] andReturn:@"iPhone Simulator"] model];
      expect(device.simulator).to.equal(YES);
      [mockDevice verify];
    });
  });

  it(@"#system", ^{
    LPDevice *device = [[LPDevice alloc] init_private];
    expect([device system]).notTo.beNil();
  });

  it(@"#model", ^{
    LPDevice *device = [[LPDevice alloc] init_private];
    expect([device model]).notTo.beNil();
  });

  describe(@"#formFactor", ^{
    __block id currentDevice;

    UIUserInterfaceIdiom iphoneIdiom = UIUserInterfaceIdiomPhone;
    UIUserInterfaceIdiom ipadIdiom = UIUserInterfaceIdiomPad;

    beforeEach(^{
      currentDevice = OCMPartialMock([UIDevice currentDevice]);
    });

    afterEach(^{
      [currentDevice stopMocking];
    });

    it(@"iPad", ^{
      [[[currentDevice stub] andReturnValue:OCMOCK_VALUE(ipadIdiom)] userInterfaceIdiom];
      LPDevice *device = [[LPDevice alloc] init_private];
      expect(device.formFactor).to.equal(@"ipad");
    });

    describe(@"iPhone form factors", ^{

      __block id touchMock;
      __block id mockDevice;

      beforeEach(^{
        [[[currentDevice stub] andReturnValue:OCMOCK_VALUE(iphoneIdiom)] userInterfaceIdiom];
        touchMock = OCMStrictClassMock([LPTouchUtils class]);
        mockDevice = OCMPartialMock([[LPDevice alloc] init_private]);
      });

      afterEach(^{
        [touchMock stopMocking];
      });

      it(@"iPhone 4in", ^{
        [[[touchMock stub] andReturnValue:OCMOCK_VALUE(yes)] is4InchDevice];
        [[[touchMock stub] andReturnValue:OCMOCK_VALUE(no)] isThreeAndAHalfInchDevice];
        [[[mockDevice stub] andReturnValue:OCMOCK_VALUE(no)] iPhone6];
        [[[mockDevice stub] andReturnValue:OCMOCK_VALUE(no)] iPhone6Plus];
        LPDevice *device = [[LPDevice alloc] init_private];
        expect(device.formFactor).to.equal(@"iphone 4in");
      });

      it(@"iPhone 3.5in", ^{
        [[[touchMock stub] andReturnValue:OCMOCK_VALUE(no)] is4InchDevice];
        [[[touchMock stub] andReturnValue:OCMOCK_VALUE(yes)] isThreeAndAHalfInchDevice];
        [[[mockDevice stub] andReturnValue:OCMOCK_VALUE(no)] iPhone6];
        [[[mockDevice stub] andReturnValue:OCMOCK_VALUE(no)] iPhone6Plus];
        LPDevice *device = [[LPDevice alloc] init_private];
        expect(device.formFactor).to.equal(@"iphone 3.5in");
      });

      it(@"iPhone 6", ^{
        [[[touchMock stub] andReturnValue:OCMOCK_VALUE(no)] is4InchDevice];
        [[[touchMock stub] andReturnValue:OCMOCK_VALUE(no)] isThreeAndAHalfInchDevice];
        [[[mockDevice stub] andReturnValue:OCMOCK_VALUE(yes)] iPhone6];
        [[[mockDevice stub] andReturnValue:OCMOCK_VALUE(no)] iPhone6Plus];
        expect([mockDevice formFactor]).to.equal(@"iphone 6");
      });

      it(@"iPhone 6+", ^{
        [[[touchMock stub] andReturnValue:OCMOCK_VALUE(no)] is4InchDevice];
        [[[touchMock stub] andReturnValue:OCMOCK_VALUE(no)] isThreeAndAHalfInchDevice];
        [[[mockDevice stub] andReturnValue:OCMOCK_VALUE(no)] iPhone6];
        [[[mockDevice stub] andReturnValue:OCMOCK_VALUE(yes)] iPhone6Plus];
        expect([mockDevice formFactor]).to.equal(@"iphone 6+");
      });

      it(@"returns the empty string otherwise", ^{
        [[[touchMock stub] andReturnValue:OCMOCK_VALUE(no)] is4InchDevice];
        [[[touchMock stub] andReturnValue:OCMOCK_VALUE(no)] isThreeAndAHalfInchDevice];
        [[[mockDevice stub] andReturnValue:OCMOCK_VALUE(no)] iPhone6];
        [[[mockDevice stub] andReturnValue:OCMOCK_VALUE(no)] iPhone6Plus];
        expect([mockDevice formFactor]).to.equal(@"");
      });
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
      __block LPDevice *device;
      __block id mockDevice;

      beforeEach(^{
        device = [[LPDevice alloc] init_private];
        mockDevice = OCMPartialMock(device);
        [[[mockDevice expect] andReturnValue:OCMOCK_VALUE(no)] simulator];
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
        [[[mockDevice expect] andReturnValue:OCMOCK_VALUE(yes)] simulator];

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
        [[[mockDevice expect] andReturnValue:OCMOCK_VALUE(no)] simulator];
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
