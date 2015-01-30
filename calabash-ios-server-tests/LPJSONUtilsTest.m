#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif


#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "LPJSONUtils.h"

@interface LPJSONUtilsTest : XCTestCase

@end

@implementation LPJSONUtilsTest

- (void)setUp {
  [super setUp];
}

- (void)tearDown {
  [super tearDown];
}

#pragma mark - dictionary:setObject:forKey

- (void) testDictionarySetObjectCanSetAnNonNilObject {
  NSMutableDictionary *dict = [NSMutableDictionary dictionary];
  NSString *key = @"key";
  NSString *object = @"object";
  [LPJSONUtils dictionary:dict setObject:object forKey:key];
  id actual = [dict objectForKey:key];
  XCTAssertEqualObjects(actual, object);
}

- (void) testDictionarySetObjectCanSetAndNilObject {
  NSMutableDictionary *dict = [NSMutableDictionary dictionary];
  NSString *key = @"key";
  NSString *object = nil;
  [LPJSONUtils dictionary:dict setObject:object forKey:key];
  id actual = [dict objectForKey:key];
  XCTAssertEqualObjects(actual, [NSNull null]);
}

@end
