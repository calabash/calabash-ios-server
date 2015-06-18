#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPDecimalRounder.h"

@interface LPDecimalRounderTest : XCTestCase

@end

@implementation LPDecimalRounderTest

@end

SpecBegin(LPDecimalRounder)

describe(@"LPDecimalRounder", ^{

  __block LPDecimalRounder *rounder;
  __block CGFloat toRound;
  __block CGFloat rounded;

  before(^{
    rounder = [LPDecimalRounder new];
  });

  it(@"#round", ^{
    toRound = 44.445888;
    rounded = [rounder round:toRound];
    expect(rounded).to.beCloseToWithin(44.45, 0.001);

    toRound = 44.444888;
    rounded = [rounder round:toRound];
    expect(rounded).to.beCloseToWithin(44.44, 0.001);
  });

  it(@"#round:withScale:", ^{
    toRound = 44.445888;
    rounded = [rounder round:toRound withScale:1];
    expect(rounded).to.beCloseToWithin(44.4, 0.01);

    rounded = [rounder round:toRound withScale:3];
    expect(rounded).to.beCloseToWithin(44.446, 0.0001);

    rounded = [rounder round:toRound withScale:4];
    expect(rounded).to.beCloseToWithin(44.4459, 0.00001);
  });

});
SpecEnd
