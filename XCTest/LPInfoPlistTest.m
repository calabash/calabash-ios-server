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

  beforeEach(^{
    infoPlist = [LPInfoPlist new];
    mainBundleMock = [OCMockObject partialMockForObject:[NSBundle mainBundle]];
  });

  afterEach(^{
    [mainBundleMock verify];
    [mainBundleMock stopMocking];
  });

  it(@"DTSDKName", ^{
    [[[mainBundleMock expect]
      andReturn:@{@"DTSDKName" : @"foo"}] infoDictionary];
    expect([infoPlist stringForDTSDKName]).to.equal(@"foo");
  });

});

SpecEnd
