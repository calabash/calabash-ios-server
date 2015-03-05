#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPInfoPlist.h"

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
  __block id mainBundleMock;
  __block NSDictionary *plistDictionary;

  beforeEach(^{
    infoPlist = [LPInfoPlist new];
    mainBundleMock = [OCMockObject partialMockForObject:[NSBundle mainBundle]];
  });

  afterEach(^{
    [mainBundleMock stopMocking];
  });

  describe(@"stringForDTSDKName", ^{

    it(@"returns the DTSDKName if avaliable", ^{
      NSString *expected = @"foo";
      plistDictionary = @{@"DTSDKName" : expected};
      [[[mainBundleMock expect] andReturn:plistDictionary] infoDictionary];
      NSString *actual = [infoPlist stringForDTSDKName];
      expect(actual).to.equal(expected);
      [mainBundleMock verify];
    });

    it(@"returns nil if the DTSDName is not available", ^{
      plistDictionary = @{};
      [[[mainBundleMock expect] andReturn:plistDictionary] infoDictionary];
      NSString *actual = [infoPlist stringForDTSDKName];
      expect(actual).to.equal(nil);
      [mainBundleMock verify];
    });
  });

});

SpecEnd
