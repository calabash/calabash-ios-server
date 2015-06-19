#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPiOSVersionInlines.h"

@interface LPiOSVersionInlinesTest : XCTestCase

@end

@implementation LPiOSVersionInlinesTest

- (void)setUp {
  [super setUp];
}

- (void)tearDown {
  [super tearDown];
}

// Do inlining and dispatch_once help performance?  Yes.

// 0.133 seconds
//- (void)testPerformanceNotInlined {
//  // This is an example of a performance test case.
//  [self measureBlock:^{
//    for (NSInteger i = 0; i < 100000; i++) {
//      [[UIDevice currentDevice] systemVersion];
//    }
//  }];
//}

// 0.005 seconds
//- (void)testPerformanceInlined {
//  // This is an example of a performance test case.
//  [self measureBlock:^{
//    for (NSInteger i = 0; i < 100000; i++) {
//      lp_sys_version();
//    }
//  }];
//}

@end

SpecBegin(LPiOSVersionInlines)

describe(@"LPiOSVersionInlines", ^{
  it(@"iOS version", ^{
    expect(lp_sys_version()).notTo.equal(nil);
  });

  it(@"==", ^{
    expect(lp_ios_version_eql(@"some version")).to.equal(NO);
    expect(lp_ios_version_eql([[UIDevice currentDevice] systemVersion])).to.equal(YES);
  });

  it(@">", ^{
    expect(lp_ios_version_gt(@"1.0")).to.equal(YES);
    expect(lp_ios_version_gt(@"100.0")).to.equal(NO);
  });

  it(@">=", ^{
    expect(lp_ios_version_gte(@"1.0")).to.equal(YES);
    expect(lp_ios_version_gte(@"100.0")).to.equal(NO);
  });

  it(@"<", ^{
    expect(lp_ios_version_lt(@"100.0")).to.equal(YES);
    expect(lp_ios_version_lt(@"1.0")).to.equal(NO);
  });

  it(@"<=", ^{
    expect(lp_ios_version_lte(@"100.0")).to.equal(YES);
    expect(lp_ios_version_lte(@"1.0")).to.equal(NO);
  });
});

SpecEnd
