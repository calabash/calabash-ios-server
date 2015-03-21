#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPDevice.h"

@interface LPDevice (LPXCTEST)

- (id) init_private;

@end

SpecBegin(LPDevice)

describe(@"LPDevice", ^{

  __block LPDevice *device = [[LPDevice alloc] init_private];

  describe(@"init", ^{
    expect(^{
      LPDevice __unused *tmp = [[LPDevice alloc] init];
    }).to.raiseAny();
  });

  describe(@"#simulator", ^{
    it(@"returns NO", ^{
      id currentDevice = OCMPartialMock([UIDevice currentDevice]);
      [[[currentDevice stub] andReturn:@"Anything but: iPhone Simulator"] model];
      expect(device.simulator).to.equal(NO);
    });

    it(@"returns YES", ^{
      id currentDevice = OCMPartialMock([UIDevice currentDevice]);
      [[[currentDevice stub] andReturn:@"iPhone Simulator"] model];
      expect(device.simulator).to.equal(YES);
    });
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
