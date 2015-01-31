#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "LPInvoker.h"
#import <OCMock/OCMock.h>

@interface LPInvokerTest : XCTestCase

@end

@implementation LPInvokerTest

- (void)setUp {
  [super setUp];
}

- (void)tearDown {
  [super tearDown];
}

#pragma mark - init

- (void) testInitThrowsException {
  XCTAssertThrows([LPInvoker new]);
}

#pragma mark - initWithSelector:receiver

- (void) testDesignatedInitializer {
  NSString *receiver = @"string";
  SEL selector = @selector(length);
  LPInvoker *invoker = [[LPInvoker alloc] initWithSelector:selector
                                                  receiver:receiver];
  XCTAssertEqual(invoker.selector, selector);
  XCTAssertEqualObjects(invoker.receiver, receiver);
}

#pragma mark - receiverRespondsToSelector

- (void) testReceiverRespondsToSelectorYES {
  NSString *receiver = @"string";
  SEL selector = @selector(length);
  LPInvoker *invoker = [[LPInvoker alloc] initWithSelector:selector
                                                  receiver:receiver];
  XCTAssertTrue([invoker receiverRespondsToSelector]);
}

- (void) testReceiverRespondsToSelectorNO {
  NSString *receiver = @"string";
  SEL selector = NSSelectorFromString(@"obviouslyUnknownSelector");
  LPInvoker *invoker = [[LPInvoker alloc] initWithSelector:selector
                                                  receiver:receiver];
  XCTAssertFalse([invoker receiverRespondsToSelector]);
}

#pragma mark - encoding

- (void) testEncoding {
  NSString *receiver = @"string";
  SEL selector = @selector(length);
  LPInvoker *invoker = [[LPInvoker alloc] initWithSelector:selector
                                                  receiver:receiver];
  NSString *actual = [invoker encoding];
  XCTAssertEqualObjects(actual, @"I");
}

- (void) testEncodingDoesNotRespondToSelector {
  NSString *receiver = @"string";
  SEL selector = NSSelectorFromString(@"obviouslyUnknownSelector");
  LPInvoker *invoker = [[LPInvoker alloc] initWithSelector:selector
                                                  receiver:receiver];
  NSString *actual = [invoker encoding];
  XCTAssertEqualObjects(actual, LPReceiverDoesNotRespondToSelectorEncoding);
}

#pragma mark - encodingIsUnhandled

- (id) mockInvokerEncoding:(NSString *) mockEncoding {
  LPInvoker *invoker = [[LPInvoker alloc] initWithSelector:@selector(length)
                                                  receiver:@"string"];
  id mock = [OCMockObject partialMockForObject:invoker];
  [[[mock expect] andReturn:mockEncoding] encoding];
  return mock;
}

- (void) testUnhandledEncodingVoidStar {
  NSString *encoding = @(@encode(void *));
  id mock = [self mockInvokerEncoding:encoding];
  XCTAssertTrue([mock encodingIsUnhandled]);
  [mock verify];
}

- (void) testUnhandledEncodingTypeStar {
  NSString *encoding = @(@encode(float *));
  id mock = [self mockInvokerEncoding:encoding];
  XCTAssertTrue([mock encodingIsUnhandled]);
  [mock verify];
}

- (void) testUnhandledEncodingNSObjectStarStar {
  NSString *encoding = @(@encode(typeof(NSObject **)));
  id mock = [self mockInvokerEncoding:encoding];
  XCTAssertTrue([mock encodingIsUnhandled]);
  [mock verify];
}

- (void) testUnhandledEncodingClassObject {
  NSString *encoding = @(@encode(typeof(NSObject)));
  id mock = [self mockInvokerEncoding:encoding];
  XCTAssertTrue([mock encodingIsUnhandled]);
  [mock verify];
}

- (void) testUnhandledEncodingClassInstance {
  NSString *encoding = @(@encode(typeof(NSObject)));
  id mock = [self mockInvokerEncoding:encoding];
  XCTAssertTrue([mock encodingIsUnhandled]);
  [mock verify];
}

- (void) testUnhandledEncodingStruct {
  typedef struct _struct {
    short a;
    long long b;
    unsigned long long c;
  } Struct;
  NSString *encoding = @(@encode(typeof(Struct)));
  id mock = [self mockInvokerEncoding:encoding];
  XCTAssertTrue([mock encodingIsUnhandled]);
  [mock verify];
}

- (void) testUnhandledEncodingCArray {
  int arr[5] = {1, 2, 3, 4, 5};
  NSString *encoding = @(@encode(typeof(arr)));
  id mock = [self mockInvokerEncoding:encoding];
  XCTAssertTrue([mock encodingIsUnhandled]);
  [mock verify];
}

- (void) testUnhandledEncodingSelector {
  NSString *encoding = @(@encode(typeof(@selector(length))));
  id mock = [self mockInvokerEncoding:encoding];
  XCTAssertTrue([mock encodingIsUnhandled]);
  [mock verify];
}

- (void) testUnhandledEncodingUnion {

  typedef union _myunion {
    double PI;
    int B;
  } MyUnion;

  NSString *encoding = @(@encode(typeof(MyUnion)));
  id mock = [self mockInvokerEncoding:encoding];
  XCTAssertTrue([mock encodingIsUnhandled]);
  [mock verify];
}

- (void) testUnhandledEncodingBitField {

  struct {
    unsigned int age : 3;
  } Age;

  NSString *encoding = @(@encode(typeof(Age)));
  id mock = [self mockInvokerEncoding:encoding];
  XCTAssertTrue([mock encodingIsUnhandled]);
  [mock verify];
}

- (void) testUnhandledUnknown {
  NSString *encoding = @"?";
  id mock = [self mockInvokerEncoding:encoding];
  XCTAssertTrue([mock encodingIsUnhandled]);
  [mock verify];
}

@end
