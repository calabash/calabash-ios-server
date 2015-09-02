#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPInvoker.h"

@interface LPInvoker (LPXCTEST)

+ (BOOL) canHandleArgumentEncoding:(NSString *) encoding;

@end

@interface LPInvokerArgumentEncodingIsHandledTest : XCTestCase

@end

@implementation LPInvokerArgumentEncodingIsHandledTest

- (void)setUp {
  [super setUp];
}

- (void)tearDown {
  [super tearDown];
}

- (void) testVoidStar {
  NSString *encoding = @(@encode(void *));
  BOOL actual = [LPInvoker canHandleArgumentEncoding:encoding];
  expect(actual).to.equal(NO);
}

- (void) testTypeStar {
  NSString *encoding = @(@encode(float *));
  BOOL actual = [LPInvoker canHandleArgumentEncoding:encoding];
  expect(actual).to.equal(NO);
}

- (void) testNSObjectStarStar {
  NSString *encoding = @(@encode(typeof(NSObject **)));
  BOOL actual = [LPInvoker canHandleArgumentEncoding:encoding];
  expect(actual).to.equal(NO);
}

- (void) testClassObject {
  NSString *encoding = @(@encode(typeof([NSObject class])));
  BOOL actual = [LPInvoker canHandleArgumentEncoding:encoding];
  expect(actual).to.equal(YES);
}

- (void) testClassInstance {
  NSString *encoding = @(@encode(typeof(NSObject)));
  BOOL actual = [LPInvoker canHandleArgumentEncoding:encoding];
  expect(actual).to.equal(NO);
}

- (void) testStruct {
  typedef struct _struct {
    short a;
    long long b;
    unsigned long long c;
  } Struct;

  NSString *encoding = @(@encode(typeof(Struct)));
  BOOL actual = [LPInvoker canHandleArgumentEncoding:encoding];
  expect(actual).to.equal(NO);
}

- (void) testCArray {
  int __unused arr[5] = {1, 2, 3, 4, 5};
  NSString *encoding = @(@encode(typeof(arr)));
  BOOL actual = [LPInvoker canHandleArgumentEncoding:encoding];
  expect(actual).to.equal(NO);
}

- (void) testSelector {
  NSString *encoding = @(@encode(typeof(@selector(length))));
  BOOL actual = [LPInvoker canHandleArgumentEncoding:encoding];
  expect(actual).to.equal(NO);
}

- (void) testUnion {

  typedef union _myunion {
    double PI;
    int B;
  } MyUnion;

  NSString *encoding = @(@encode(typeof(MyUnion)));
  BOOL actual = [LPInvoker canHandleArgumentEncoding:encoding];
  expect(actual).to.equal(NO);
}

- (void) testBitField {
  // Don't know how to create a bitfield
  NSString *encoding = @"b5";
  BOOL actual = [LPInvoker canHandleArgumentEncoding:encoding];
  expect(actual).to.equal(NO);
}

- (void) testUnknown {
  NSString *encoding = @"?";
  BOOL actual = [LPInvoker canHandleArgumentEncoding:encoding];
  expect(actual).to.equal(NO);
}

- (void) testCGPoint {
  NSString *encoding = @(@encode(typeof(CGPointZero)));
  BOOL actual = [LPInvoker canHandleArgumentEncoding:encoding];
  expect(actual).to.equal(YES);
}

- (void) testCGRect {
  NSString *encoding = @(@encode(typeof(CGRectZero)));
  BOOL actual = [LPInvoker canHandleArgumentEncoding:encoding];
  expect(actual).to.equal(YES);
}

- (void) testConstCharStar {
  NSString *encoding = @(@encode(typeof(const char *)));
  BOOL actual = [LPInvoker canHandleArgumentEncoding:encoding];
  expect(actual).to.equal(YES);
}

- (void) testConstEncoding {
  NSString *encoding = @"r";
  BOOL actual = [LPInvoker canHandleArgumentEncoding:encoding];
  expect(actual).to.equal(NO);

  encoding = @"r?";
  actual = [LPInvoker canHandleArgumentEncoding:encoding];
  expect(actual).to.equal(NO);
}

@end
