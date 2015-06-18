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
  describe(@"rounding CGFloat", ^{
    it(@"rounds to 2 decimal places by default", ^{

    });

    it(@"can round to an scale", ^{

    });
  });
});
SpecEnd
