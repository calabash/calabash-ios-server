#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPCoercion.h"

@interface LPCoercionTest : XCTestCase

@end

@implementation LPCoercionTest

@end

SpecBegin(LPCoercion)

__block LPCoercion *coercion;

it(@"coercionWithValue:", ^{
  coercion = [LPCoercion coercionWithValue:nil];
  expect(coercion.value).to.equal(nil);
  expect(coercion.failureMessage).to.equal(nil);

  coercion = [LPCoercion coercionWithValue:@"a value"];
  expect(coercion.value).to.equal(@"a value");
  expect(coercion.failureMessage).to.equal(nil);
});

it(@"coercionWithFailureMessage:", ^{
  coercion = [LPCoercion coercionWithFailureMessage:@"failure"];
  expect(coercion.value).to.equal(nil);
  expect(coercion.failureMessage).to.equal(@"failure");
});

describe(@"#wasSuccessful", ^{
  it(@"returns NO when value is nil", ^{
    coercion = [LPCoercion coercionWithValue:nil];
    expect([coercion wasSuccessful]).to.equal(NO);
  });

  it(@"returns YES when value is not nil", ^{
    coercion = [LPCoercion coercionWithValue:@"a value"];
    expect([coercion wasSuccessful]).to.equal(YES);
  });
});

SpecEnd
