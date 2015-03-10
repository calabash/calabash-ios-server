#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPLegacyAppRectTranslator.h"
#import "LPTouchUtils.h"
#import "LPInfoPlist.h"

@interface LPLegacyAppRectTranslator (LPXCTEST)

@property(strong, nonatomic) LPInfoPlist *infoPlist;
@property(strong, nonatomic) UIDevice *device;

- (BOOL) appCompiledAgainstSDK6;
- (BOOL) iOSVersionOnTestDeviceIsGteTo80;
- (UIInterfaceOrientation) statusBarOrientation;
- (BOOL) appOrientationRequiresTranslation;
- (CGSize) canonicalScreenSizeForLegacyApp;

@end

SpecBegin(LPLegacyAppRectTranslator)

describe(@"LPLegacyAppRectTranslator", ^{

  it(@"#infoPlist", ^{
    LPLegacyAppRectTranslator *translator = [LPLegacyAppRectTranslator new];
    LPInfoPlist *plist = translator.infoPlist;
    expect(plist).notTo.equal(nil);
    expect(plist).to.beAnInstanceOf([LPInfoPlist class]);
  });

  it(@"#device", ^{
    LPLegacyAppRectTranslator *translator = [LPLegacyAppRectTranslator new];
    UIDevice *device = translator.device;
    expect(device).notTo.equal(nil);
    expect(device).to.beAnInstanceOf([UIDevice class]);
  });

  it(@"#statusBarOrientation", ^{
    LPLegacyAppRectTranslator *translator = [LPLegacyAppRectTranslator new];
    UIInterfaceOrientation orientation = translator.statusBarOrientation;
    expect(orientation).to.beInTheRangeOf(UIDeviceOrientationPortrait,
                                          UIDeviceOrientationLandscapeRight);
  });

  describe(@"#appCompliedAgainstSDK6", ^{
    describe(@"returns YES", ^{
      __block LPInfoPlist *plist;

      beforeEach(^{
        plist = mock([LPInfoPlist class]);
      });

      it(@"when simulator target", ^{
        NSString *dtSdk = @"iphonesimulator6.1";
        [given([plist stringForDTSDKName]) willReturn:dtSdk];
        LPLegacyAppRectTranslator *translator = [LPLegacyAppRectTranslator new];
        translator.infoPlist = plist;
        expect([translator appCompiledAgainstSDK6]).equal(YES);
      });

      it (@"when device target", ^{
        NSString *dtSdk = @"iphoneos6.1";
        [given([plist stringForDTSDKName]) willReturn:dtSdk];
        LPLegacyAppRectTranslator *translator = [LPLegacyAppRectTranslator new];
        translator.infoPlist = plist;
        expect([translator appCompiledAgainstSDK6]).equal(YES);
      });
    });

    describe(@"returns NO in all other cases", ^{
      it(@"when simulator target", ^{
        LPLegacyAppRectTranslator *translator = [LPLegacyAppRectTranslator new];
        expect([translator appCompiledAgainstSDK6]).equal(NO);
      });
    });
  });

  describe(@"#systemVersionIs80", ^{

    __block UIDevice *device;

    beforeEach(^{
      device = mock([UIDevice class]);
    });

    describe(@"returns YES", ^{
      it(@"when iOS == 8.0", ^{
        NSString *sdkVersion = @"8.0";
        [given([device systemVersion]) willReturn:sdkVersion];
        LPLegacyAppRectTranslator *translator = [LPLegacyAppRectTranslator new];
        translator.device = device;
        expect([translator iOSVersionOnTestDeviceIsGteTo80]).to.equal(YES);
      });

      it(@"when iOS > 8.0", ^{
        NSString *sdkVersion = @"8.1";
        [given([device systemVersion]) willReturn:sdkVersion];
        LPLegacyAppRectTranslator *translator = [LPLegacyAppRectTranslator new];
        translator.device = device;
        expect([translator iOSVersionOnTestDeviceIsGteTo80]).to.equal(YES);
      });
    });

    it(@"returns false otherwise", ^{
      NSString *sdkVersion = @"7.1";
      [given([device systemVersion]) willReturn:sdkVersion];
      LPLegacyAppRectTranslator *translator = [LPLegacyAppRectTranslator new];
      translator.device = device;
      expect([translator iOSVersionOnTestDeviceIsGteTo80]).to.equal(NO);
    });
  });

  describe(@"#appOrientationRequiresTranslation", ^{
    __block LPLegacyAppRectTranslator *translator;
    __block UIInterfaceOrientation left = UIInterfaceOrientationLandscapeLeft;
    __block UIInterfaceOrientation right = UIInterfaceOrientationLandscapeRight;
    __block UIInterfaceOrientation portrait = UIInterfaceOrientationPortrait;
    __block UIInterfaceOrientation upsideDown = UIInterfaceOrientationPortraitUpsideDown;

    beforeEach(^{
      translator = [LPLegacyAppRectTranslator new];
    });

    it(@"returns NO when app is in portrait", ^{
      id translatorMock = [OCMockObject partialMockForObject:translator];
      [[[translatorMock expect] andReturnValue:OCMOCK_VALUE(portrait)]
       statusBarOrientation];
      expect([translatorMock appOrientationRequiresTranslation]).to.equal(NO);
      [translatorMock verify];
    });

    describe(@"return YES", ^{
      it(@"when app is in left landscape", ^{
        id translatorMock = [OCMockObject partialMockForObject:translator];
        [[[translatorMock expect] andReturnValue:OCMOCK_VALUE(left)]
         statusBarOrientation];
        expect([translatorMock appOrientationRequiresTranslation]).to.equal(YES);
        [translatorMock verify];
      });

      it(@"when app is in right landscape", ^{
        id translatorMock = [OCMockObject partialMockForObject:translator];
        [[[translatorMock expect] andReturnValue:OCMOCK_VALUE(right)]
         statusBarOrientation];
        expect([translatorMock appOrientationRequiresTranslation]).to.equal(YES);
        [translatorMock verify];
      });

      it(@"when app is in upside down", ^{
        id translatorMock = [OCMockObject partialMockForObject:translator];
        [[[translatorMock expect] andReturnValue:OCMOCK_VALUE(upsideDown)]
         statusBarOrientation];
        expect([translatorMock appOrientationRequiresTranslation]).to.equal(YES);
        [translatorMock verify];
      });
    });
  });

  describe(@"#appUnderTestRequiresLegacyRectTranslation", ^{

    __block LPLegacyAppRectTranslator *translator;
    __block BOOL yes = YES;
    __block BOOL no = NO;

    beforeEach(^{
      translator = [LPLegacyAppRectTranslator new];
    });

    describe(@"returns NO", ^{
      it(@"when app is not compiled under SDK 6.0", ^{
        id translatorMock = [OCMockObject partialMockForObject:translator];
        [[[translatorMock expect] andReturnValue:OCMOCK_VALUE(no)]
         appCompiledAgainstSDK6];
        [[[translatorMock expect] andReturnValue:OCMOCK_VALUE(yes)]
         iOSVersionOnTestDeviceIsGteTo80];
        [[[translatorMock expect] andReturnValue:OCMOCK_VALUE(yes)]
         appOrientationRequiresTranslation];
        expect([translatorMock appUnderTestRequiresLegacyRectTranslation]).to.equal(NO);
      });

      it(@"when device under test is >= iOS 8.0", ^{
        id translatorMock = [OCMockObject partialMockForObject:translator];
        [[[translatorMock expect] andReturnValue:OCMOCK_VALUE(yes)]
         appCompiledAgainstSDK6];
        [[[translatorMock expect] andReturnValue:OCMOCK_VALUE(no)]
         iOSVersionOnTestDeviceIsGteTo80];
        [[[translatorMock expect] andReturnValue:OCMOCK_VALUE(yes)]
         appOrientationRequiresTranslation];
        expect([translatorMock appUnderTestRequiresLegacyRectTranslation]).to.equal(NO);
      });

      it(@"when app has orientation landscape", ^{
        id translatorMock = [OCMockObject partialMockForObject:translator];
        [[[translatorMock expect] andReturnValue:OCMOCK_VALUE(yes)]
         appCompiledAgainstSDK6];
        [[[translatorMock expect] andReturnValue:OCMOCK_VALUE(yes)]
         iOSVersionOnTestDeviceIsGteTo80];
        [[[translatorMock expect] andReturnValue:OCMOCK_VALUE(no)]
         appOrientationRequiresTranslation];
        expect([translatorMock appUnderTestRequiresLegacyRectTranslation]).to.equal(NO);
      });
    });

    it(@"returns YES when app compile under SDK 6.0 and device under test is >= iOS 8.0", ^{
      id translatorMock = [OCMockObject partialMockForObject:translator];
      [[[translatorMock expect] andReturnValue:OCMOCK_VALUE(yes)]
       appCompiledAgainstSDK6];
      [[[translatorMock expect] andReturnValue:OCMOCK_VALUE(yes)]
       iOSVersionOnTestDeviceIsGteTo80];
      [[[translatorMock expect] andReturnValue:OCMOCK_VALUE(yes)]
       appOrientationRequiresTranslation];
      expect([translatorMock appUnderTestRequiresLegacyRectTranslation]).to.equal(YES);
    });
  });

  describe(@"#canonicalScreenSizeForLegacyApp", ^{

    __block LPLegacyAppRectTranslator *translator;
    __block BOOL yes = YES;
    __block BOOL no = NO;
    __block UIUserInterfaceIdiom ipad = UIUserInterfaceIdiomPad;
    __block UIUserInterfaceIdiom iphone = UIUserInterfaceIdiomPhone;
    __block CGSize actual;

    beforeEach(^{
      translator = [LPLegacyAppRectTranslator new];
    });

    it(@"returns CGSizeZero if no canonical size can be found", ^{
      id currentDeviceMock = [OCMockObject partialMockForObject:[UIDevice currentDevice]];
      [[[currentDeviceMock stub] andReturnValue:OCMOCK_VALUE(iphone)] userInterfaceIdiom];

      id touchUtilsMock = [OCMockObject mockForClass:[LPTouchUtils class]];
      [[[touchUtilsMock stub] andReturnValue:@(no)] isThreeAndAHalfInchDevice];
      [[[touchUtilsMock stub] andReturnValue:@(no)] is4InchDevice];

      actual = [translator canonicalScreenSizeForLegacyApp];
      expect(actual.height).to.equal(0);
      expect(actual.width).to.equal(0);
    });

    it(@"returns correct size for iPad", ^{
      id currentDeviceMock = [OCMockObject partialMockForObject:[UIDevice currentDevice]];
      [[[currentDeviceMock stub] andReturnValue:OCMOCK_VALUE(ipad)] userInterfaceIdiom];

      id touchUtilsMock = [OCMockObject mockForClass:[LPTouchUtils class]];
      [[[touchUtilsMock stub] andReturnValue:@(no)] isThreeAndAHalfInchDevice];
      [[[touchUtilsMock stub] andReturnValue:@(no)] is4InchDevice];

      actual = [translator canonicalScreenSizeForLegacyApp];
      expect(actual.height).to.equal(1024);
      expect(actual.width).to.equal(768);
    });

    it(@"returns correct size for iPhone 3in", ^{
      id currentDeviceMock = [OCMockObject partialMockForObject:[UIDevice currentDevice]];
      [[[currentDeviceMock stub] andReturnValue:OCMOCK_VALUE(iphone)] userInterfaceIdiom];

      id touchUtilsMock = [OCMockObject mockForClass:[LPTouchUtils class]];
      [[[touchUtilsMock stub] andReturnValue:@(yes)] isThreeAndAHalfInchDevice];
      [[[touchUtilsMock stub] andReturnValue:@(no)] is4InchDevice];

      actual = [translator canonicalScreenSizeForLegacyApp];
      expect(actual.height).to.equal(480);
      expect(actual.width).to.equal(320);
    });

    it(@"returns correct size for iPhone 4in", ^{
      id currentDeviceMock = [OCMockObject partialMockForObject:[UIDevice currentDevice]];
      [[[currentDeviceMock stub] andReturnValue:OCMOCK_VALUE(iphone)] userInterfaceIdiom];

      id touchUtilsMock = [OCMockObject mockForClass:[LPTouchUtils class]];
      [[[touchUtilsMock stub] andReturnValue:@(no)] isThreeAndAHalfInchDevice];
      [[[touchUtilsMock stub] andReturnValue:@(yes)] is4InchDevice];

      actual = [translator canonicalScreenSizeForLegacyApp];
      expect(actual.height).to.equal(568);
      expect(actual.width).to.equal(320);
    });
  });

  describe(@"#dictionaryAfterLegacyRectTranslation:", ^{
    __block NSDictionary *original;
    __block NSDictionary *expected;
    __block NSDictionary *actual;

    __block LPLegacyAppRectTranslator *translator;

    __block UIInterfaceOrientation left = UIInterfaceOrientationLandscapeLeft;
    __block UIInterfaceOrientation right = UIInterfaceOrientationLandscapeRight;
    __block UIInterfaceOrientation portrait = UIInterfaceOrientationPortrait;
    __block UIInterfaceOrientation upsideDown = UIInterfaceOrientationPortraitUpsideDown;

    __block UIUserInterfaceIdiom ipad = UIUserInterfaceIdiomPad;

    beforeEach(^{
      translator = [LPLegacyAppRectTranslator new];
      original = @{@"center_x" : @(345),
                   @"center_y" : @(512.5),
                   @"x" : @(325),
                   @"y" : @(223),
                   @"width" : @(40),
                   @"height" : @(579)};
    });

    it(@"returns nil if dictionary to translate is nil", ^{
      expect([translator dictionaryAfterLegacyRectTranslation:nil]).to.equal(nil);
    });

    it(@"returns the original dictionary if keys are missing", ^{
      NSDictionary *dict = @{@"a" : @"b", @"c" : @"d"};
      actual = [translator dictionaryAfterLegacyRectTranslation:dict];
      expect(actual).to.equal(dict);
    });

    it(@"does no translation if orientation is portrait", ^{
      id translatorMock = [OCMockObject partialMockForObject:translator];
      [[[translatorMock expect] andReturnValue:OCMOCK_VALUE(portrait)]
       statusBarOrientation];
      actual = [translatorMock dictionaryAfterLegacyRectTranslation:original];
      expect(actual).to.equal(original);
      [translatorMock verify];
    });

    it(@"translates when orientation is left", ^{
      expected = @{@"center_x" : @(511.5),
                   @"center_y" : @(345),
                   @"x" : @(325),
                   @"y" : @(223),
                   @"width" : @(40),
                   @"height" : @(579)};

      id translatorMock = [OCMockObject partialMockForObject:translator];
      [[[translatorMock expect] andReturnValue:OCMOCK_VALUE(left)]
       statusBarOrientation];

      id currentDeviceMock = [OCMockObject partialMockForObject:[UIDevice currentDevice]];
      [[[currentDeviceMock stub] andReturnValue:OCMOCK_VALUE(ipad)] userInterfaceIdiom];

      actual = [translatorMock dictionaryAfterLegacyRectTranslation:original];

      expect(actual[@"center_x"]).to.equal(expected[@"center_x"]);
      expect(actual[@"center_y"]).to.equal(expected[@"center_y"]);
      expect(actual[@"x"]).to.equal(expected[@"x"]);
      expect(actual[@"y"]).to.equal(expected[@"y"]);
      expect(actual[@"width"]).to.equal(expected[@"width"]);
      expect(actual[@"height"]).to.equal(expected[@"height" ]);
    });

    it(@"translates when orientation is right", ^{
      expected = @{@"center_x" : @(512.5),
                   @"center_y" : @(423),
                   @"x" : @(325),
                   @"y" : @(223),
                   @"width" : @(40),
                   @"height" : @(579)};

      id translatorMock = [OCMockObject partialMockForObject:translator];
      [[[translatorMock expect] andReturnValue:OCMOCK_VALUE(right)]
       statusBarOrientation];

      id currentDeviceMock = [OCMockObject partialMockForObject:[UIDevice currentDevice]];
      [[[currentDeviceMock stub] andReturnValue:OCMOCK_VALUE(ipad)] userInterfaceIdiom];

      actual = [translatorMock dictionaryAfterLegacyRectTranslation:original];

      expect(actual[@"center_x"]).to.equal(expected[@"center_x"]);
      expect(actual[@"center_y"]).to.equal(expected[@"center_y"]);
      expect(actual[@"x"]).to.equal(expected[@"x"]);
      expect(actual[@"y"]).to.equal(expected[@"y"]);
      expect(actual[@"width"]).to.equal(expected[@"width"]);
      expect(actual[@"height"]).to.equal(expected[@"height" ]);

    });

    it(@"translates when orientation is upside down", ^{
      expected = @{@"center_x" : @(423),
                   @"center_y" : @(511.5),
                   @"x" : @(325),
                   @"y" : @(223),
                   @"width" : @(40),
                   @"height" : @(579)};

      id translatorMock = [OCMockObject partialMockForObject:translator];
      [[[translatorMock expect] andReturnValue:OCMOCK_VALUE(upsideDown)]
       statusBarOrientation];

      id currentDeviceMock = [OCMockObject partialMockForObject:[UIDevice currentDevice]];
      [[[currentDeviceMock stub] andReturnValue:OCMOCK_VALUE(ipad)] userInterfaceIdiom];

      actual = [translatorMock dictionaryAfterLegacyRectTranslation:original];

      expect(actual[@"center_x"]).to.equal(expected[@"center_x"]);
      expect(actual[@"center_y"]).to.equal(expected[@"center_y"]);
      expect(actual[@"x"]).to.equal(expected[@"x"]);
      expect(actual[@"y"]).to.equal(expected[@"y"]);
      expect(actual[@"width"]).to.equal(expected[@"width"]);
      expect(actual[@"height"]).to.equal(expected[@"height" ]);

    });
  });
});

SpecEnd
