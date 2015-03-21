#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPDevice.h"

@interface LPDevice (LPXCTEST)

- (id) init_private;
- (NSPredicate *) iPhone6SimPredicate;
- (NSPredicate *) iPhone6PlusSimPredicate;

@end

SpecBegin(LPDevice)

describe(@"LPDevice", ^{

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
