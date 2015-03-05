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

    it(@"DTSDKName", ^{
      [[[infoMock expect] andReturn:@{@"DTSDKName" : @"foo"}] infoDictionary];
      expect([infoMock stringForDTSDKName]).to.equal(@"foo");
    });

    it(@"CFBundleDisplayName", ^{
      mockedPlist = @{@"CFBundleDisplayName" : @"foo"};
      [[[infoMock expect] andReturn:mockedPlist] infoDictionary];
      expect([infoMock stringForDisplayName]).to.equal(@"foo");
    });
  });
});

SpecEnd
