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

@end
