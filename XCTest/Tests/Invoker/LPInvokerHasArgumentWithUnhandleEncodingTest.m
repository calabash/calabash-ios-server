#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPInvoker.h"
#import "InvokerFactory.h"

@interface LPInvokerHasArgumentWithUnhandleEncodingTest : XCTestCase

@property(nonatomic, strong) LPInvoker *invoker;

@end

@implementation LPInvokerHasArgumentWithUnhandleEncodingTest

- (void)setUp {
  [super setUp];
}

- (void)tearDown {
  self.invoker = nil;
  [super tearDown];
}

#pragma mark - Handled

- (void) testArgBOOL_YES {
  self.invoker = [InvokerFactory invokerWithArgmentValue:@"BOOL YES"];
  BOOL actual = [self.invoker selectorHasArgumentWithUnhandledEncoding];
  expect(actual).to.equal(NO);
}

- (void) testArgBOOL_NO {
  self.invoker = [InvokerFactory invokerWithArgmentValue:@"BOOL NO"];
  BOOL actual = [self.invoker selectorHasArgumentWithUnhandledEncoding];
  expect(actual).to.equal(NO);
}

- (void) testArgBool_true {
  self.invoker = [InvokerFactory invokerWithArgmentValue:@"bool true"];
  BOOL actual = [self.invoker selectorHasArgumentWithUnhandledEncoding];
  expect(actual).to.equal(NO);
}

- (void) testArgBool_false {
  self.invoker = [InvokerFactory invokerWithArgmentValue:@"bool false"];
  BOOL actual = [self.invoker selectorHasArgumentWithUnhandledEncoding];
  expect(actual).to.equal(NO);
}

- (void) testArgNSInteger {
  self.invoker = [InvokerFactory invokerWithArgmentValue:@"NSInteger"];
  BOOL actual = [self.invoker selectorHasArgumentWithUnhandledEncoding];
  expect(actual).to.equal(NO);
}

- (void) testArgNSUInteger {
  self.invoker = [InvokerFactory invokerWithArgmentValue:@"NSUInteger"];
  BOOL actual = [self.invoker selectorHasArgumentWithUnhandledEncoding];
  expect(actual).to.equal(NO);
}

- (void) testArgShort {
  self.invoker = [InvokerFactory invokerWithArgmentValue:@"short"];
  BOOL actual = [self.invoker selectorHasArgumentWithUnhandledEncoding];
  expect(actual).to.equal(NO);
}

- (void) testArgUnsignedShort {
  self.invoker = [InvokerFactory invokerWithArgmentValue:@"unsigned short"];
  BOOL actual = [self.invoker selectorHasArgumentWithUnhandledEncoding];
  expect(actual).to.equal(NO);
}

- (void) testArgCGFloat {
  self.invoker = [InvokerFactory invokerWithArgmentValue:@"CGFloat"];
  BOOL actual = [self.invoker selectorHasArgumentWithUnhandledEncoding];
  expect(actual).to.equal(NO);
}

- (void) testArgDouble {
  self.invoker = [InvokerFactory invokerWithArgmentValue:@"double"];
  BOOL actual = [self.invoker selectorHasArgumentWithUnhandledEncoding];
  expect(actual).to.equal(NO);
}

- (void) testArgFloat {
  self.invoker = [InvokerFactory invokerWithArgmentValue:@"float"];
  BOOL actual = [self.invoker selectorHasArgumentWithUnhandledEncoding];
  expect(actual).to.equal(NO);
}

- (void) testArgChar {
  self.invoker = [InvokerFactory invokerWithArgmentValue:@"char"];
  BOOL actual = [self.invoker selectorHasArgumentWithUnhandledEncoding];
  expect(actual).to.equal(NO);
}

- (void) testArgCharStar {
  self.invoker = [InvokerFactory invokerWithArgmentValue:@"char *"];
  BOOL actual = [self.invoker selectorHasArgumentWithUnhandledEncoding];
  expect(actual).to.equal(NO);
}

- (void) testArgConstCharStar {
  self.invoker = [InvokerFactory invokerWithArgmentValue:@"const char *"];
  BOOL actual = [self.invoker selectorHasArgumentWithUnhandledEncoding];
  expect(actual).to.equal(NO);
}

- (void) testArgUnsignedChar {
  self.invoker = [InvokerFactory invokerWithArgmentValue:@"unsigned char"];
  BOOL actual = [self.invoker selectorHasArgumentWithUnhandledEncoding];
  expect(actual).to.equal(NO);
}

- (void) testArgLong {
  self.invoker = [InvokerFactory invokerWithArgmentValue:@"long"];
  BOOL actual = [self.invoker selectorHasArgumentWithUnhandledEncoding];
  expect(actual).to.equal(NO);
}

- (void) testArgUnsignedLong {
  self.invoker = [InvokerFactory invokerWithArgmentValue:@"unsigned long"];
  BOOL actual = [self.invoker selectorHasArgumentWithUnhandledEncoding];
  expect(actual).to.equal(NO);
}

- (void) testArgLongLong {
  self.invoker = [InvokerFactory invokerWithArgmentValue:@"long long"];
  BOOL actual = [self.invoker selectorHasArgumentWithUnhandledEncoding];
  expect(actual).to.equal(NO);
}

- (void) testArgUnsignedLongLong {
  self.invoker = [InvokerFactory invokerWithArgmentValue:@"unsigned long long"];
  BOOL actual = [self.invoker selectorHasArgumentWithUnhandledEncoding];
  expect(actual).to.equal(NO);
}

- (void) testArgCGPoint {
  self.invoker = [InvokerFactory invokerWithArgmentValue:@"CGPoint"];
  BOOL actual = [self.invoker selectorHasArgumentWithUnhandledEncoding];
  expect(actual).to.equal(NO);
}

- (void) testArgCGRect {
  self.invoker = [InvokerFactory invokerWithArgmentValue:@"CGRect"];
  BOOL actual = [self.invoker selectorHasArgumentWithUnhandledEncoding];
  expect(actual).to.equal(NO);
}

- (void) testArgClass {
  self.invoker = [InvokerFactory invokerWithArgmentValue:@"Class"];
  BOOL actual = [self.invoker selectorHasArgumentWithUnhandledEncoding];
  expect(actual).to.equal(NO);
}

- (void) testArgId {
  self.invoker = [InvokerFactory invokerWithArgmentValue:@"BOOL YES"];
  BOOL actual = [self.invoker selectorHasArgumentWithUnhandledEncoding];
  expect(actual).to.equal(NO);
}

#pragma mark - Unhandled

- (void) testArgVoidStar {
  self.invoker = [InvokerFactory invokerWithArgmentValue:@"void *"];
  BOOL actual = [self.invoker selectorHasArgumentWithUnhandledEncoding];
  expect(actual).to.equal(YES);
}

- (void) testArgFloatStar {
  self.invoker = [InvokerFactory invokerWithArgmentValue:@"float *"];
  BOOL actual = [self.invoker selectorHasArgumentWithUnhandledEncoding];
  expect(actual).to.equal(YES);
}

- (void) testArgObjectStarStar {
  self.invoker = [InvokerFactory invokerWithArgmentValue:@"NSError **"];
  BOOL actual = [self.invoker selectorHasArgumentWithUnhandledEncoding];
  expect(actual).to.equal(YES);
}

- (void) testArgSelector {
  self.invoker = [InvokerFactory invokerWithArgmentValue:@"SEL"];
  BOOL actual = [self.invoker selectorHasArgumentWithUnhandledEncoding];
  expect(actual).to.equal(YES);
}

- (void) testArgPrimativeArray {
  self.invoker = [InvokerFactory invokerWithArgmentValue:@"int []"];
  BOOL actual = [self.invoker selectorHasArgumentWithUnhandledEncoding];
  expect(actual).to.equal(YES);
}

- (void) testArgStruct {
  self.invoker = [InvokerFactory invokerWithArgmentValue:@"struct"];
  BOOL actual = [self.invoker selectorHasArgumentWithUnhandledEncoding];
  expect(actual).to.equal(YES);
}

@end
