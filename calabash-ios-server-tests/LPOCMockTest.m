#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

@interface LPOCMockTest : XCTestCase

@end

@implementation LPOCMockTest

- (void)setUp {
  [super setUp];
}

- (void)tearDown {
  [super tearDown];
}

- (void)testOCMockIsWorking {
  id actual;
  id mock = [OCMockObject mockForClass:[NSString class]];
  [[[mock expect] andReturn:@"megamock"] lowercaseString];
  actual = [mock lowercaseString];
  [mock verify];

  XCTAssertEqualObjects(actual, @"megamock", @"Should have returned stubbed value.");
}

@end
