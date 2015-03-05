#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPInfoPlist.h"

@interface LPInfoPlist (LPTesting)

- (NSDictionary *) infoDictionary;

@end

@interface LPInfoPlistTest : XCTestCase

@property (strong, nonatomic) LPInfoPlist *infoPlist;

@end

@implementation LPInfoPlistTest

- (void) setUp {
  [super setUp];
  self.infoPlist = [LPInfoPlist new];
}

- (void) tearDown {
  self.infoPlist = nil;
  [super tearDown];
}

- (void) testServerPortIsDefaultWhenNoInfoPlistKeyExists {
  XCTAssertEqual([self.infoPlist serverPort], 37265);
}

- (void) testServerPortInfoPlistKeyExists {
  NSUInteger expectedPort = 322;
  id mainBundleMock = [OCMockObject partialMockForObject:[NSBundle mainBundle]];
  NSDictionary *plistDictionary = @{@"CalabashServerPort" : @(expectedPort)};
  [[[mainBundleMock stub] andReturn:plistDictionary] infoDictionary];
  XCTAssertEqual([self.infoPlist serverPort], expectedPort);
}

@end

SpecBegin(LPInfoPlist)

describe(@"LPInfoPlist", ^{
  __block LPInfoPlist *infoPlist;

  beforeEach(^{
    infoPlist = [LPInfoPlist new];
  });

  it(@"#infoDictionary", ^{
    id mainBundleMock = [OCMockObject partialMockForObject:[NSBundle mainBundle]];
    [[[mainBundleMock expect] andReturn:@{@"key" : @"value"}] infoDictionary];
    NSDictionary *actual = [infoPlist infoDictionary];
    expect(actual[@"key"]).to.equal(@"value");
    [mainBundleMock verify];
    [mainBundleMock stopMocking];
  });

  describe(@"Accessing Info.plist Keys", ^{
    __block id infoMock;
    __block NSDictionary *mockedPlist;

    beforeEach(^{
      infoMock = [OCMockObject partialMockForObject:infoPlist];
    });

    afterEach(^{
      [infoMock verify];
      [infoMock stopMocking];
    });

    describe(@"DTSDKName", ^{
      it(@"value exists", ^{
        [[[infoMock expect] andReturn:@{@"DTSDKName" : @"foo"}] infoDictionary];
        expect([infoMock stringForDTSDKName]).to.equal(@"foo");
      });

      it(@"value does not exist", ^{
        [[[infoMock expect] andReturn:@{}] infoDictionary];
        expect([infoMock stringForDTSDKName]).to.beEmpty();
      });
    });

    describe(@"CFBundleDisplayName", ^{
      it(@"value exists", ^{
        mockedPlist = @{@"CFBundleDisplayName" : @"foo"};
        [[[infoMock expect] andReturn:mockedPlist] infoDictionary];
        expect([infoMock stringForDisplayName]).to.equal(@"foo");
      });

      it(@"value does not exist", ^{
        [[[infoMock expect] andReturn:@{}] infoDictionary];
        expect([infoMock stringForDisplayName]).to.beEmpty();
      });
    });

    describe(@"CFBundleIdentifier", ^{
      it(@"value exists", ^{
        mockedPlist = @{@"CFBundleIdentifier" : @"foo"};
        [[[infoMock expect] andReturn:mockedPlist] infoDictionary];
        expect([infoMock stringForIdentifier]).to.equal(@"foo");
      });

      it(@"value does not exist", ^{
        [[[infoMock expect] andReturn:@{}] infoDictionary];
        expect([infoMock stringForIdentifier]).to.beEmpty();
      });
    });

    describe(@"CFBundleVersion", ^{
      it(@"value exists", ^{
        mockedPlist = @{@"CFBundleVersion" : @"foo"};
        [[[infoMock expect] andReturn:mockedPlist] infoDictionary];
        expect([infoMock stringForVersion]).to.equal(@"foo");
      });

      it(@"value does not exist", ^{
        [[[infoMock expect] andReturn:@{}] infoDictionary];
        expect([infoMock stringForVersion]).to.beEmpty();
      });
    });

    describe(@"CFBundleShortVersionString", ^{
      it(@"value exists", ^{
        mockedPlist = @{@"CFBundleShortVersionString" : @"foo"};
        [[[infoMock expect] andReturn:mockedPlist] infoDictionary];
        expect([infoMock stringForShortVersion]).to.equal(@"foo");
      });

      it(@"value does not exist", ^{
        [[[infoMock expect] andReturn:@{}] infoDictionary];
        expect([infoMock stringForShortVersion]).to.beEmpty();
      });
    });
  });
});

SpecEnd
