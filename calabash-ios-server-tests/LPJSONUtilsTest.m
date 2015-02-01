#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "LPJSONUtils.h"
#import <OCMock/OCMock.h>

@interface LPJSONUtils (LPXCTTEST)

+ (void) dictionary:(NSMutableDictionary *) dictionary
    setObjectforKey:(NSString *) key
         whenTarget:(id) target
         respondsTo:(SEL) selector;

+ (NSMutableDictionary *) jsonifyView:(UIView *) view;

@end

@interface LPJSONUtilsTest : XCTestCase

@end

@implementation LPJSONUtilsTest

- (void)setUp {
  [super setUp];
}

- (void)tearDown {
  [super tearDown];
}

#pragma mark - dictionary:setObject:forKey:whenTarget:respondsTo:

- (void) testDictionarySetObjectForKeyWhenTargetRespondsToYesAndNil {
  NSMutableDictionary *dict = [@{} mutableCopy];
  UIView *view = [[UIView alloc] init];
  SEL selector = @selector(accessibilityLabel);
  [LPJSONUtils dictionary:dict
          setObjectforKey:@"key"
               whenTarget:view
               respondsTo:selector];
  XCTAssertEqualObjects(dict[@"key"], [NSNull null]);
}

- (void) testDictionarySetObjectForKeyWhenTargetRespondsToYesAndNonNil {
  NSMutableDictionary *dict = [@{} mutableCopy];
  UIView *view = [[UIView alloc] init];
  SEL selector = @selector(accessibilityLabel);
  NSString *expected = @"Touch me";
  view.accessibilityLabel = expected;
  [LPJSONUtils dictionary:dict
          setObjectforKey:@"key"
               whenTarget:view
               respondsTo:selector];
  XCTAssertEqualObjects(dict[@"key"], expected);
}

- (void) testDictionarySetObjectForKeyWhenTargetRespondsToNo {
  NSMutableDictionary *dict = [@{} mutableCopy];
  UIView *view = [[UIView alloc] init];
  SEL selector = NSSelectorFromString(@"obviouslyUnknownSelector");
  [LPJSONUtils dictionary:dict
          setObjectforKey:@"key"
               whenTarget:view
               respondsTo:selector];
  XCTAssertEqualObjects(dict[@"key"], nil);
}

#pragma mark - jsonifyView

- (void) testJsonifyViewUIView {
  CGRect frame = {20, 64, 88, 44};
  UIView *view = [[UIView alloc] initWithFrame:frame];
  NSDictionary *dict = [LPJSONUtils jsonifyView:view];

  XCTAssertEqualObjects(dict[@"accessibilityElement"], @(0));
  XCTAssertEqualObjects(dict[@"alpha"], @(1));
  XCTAssertEqualObjects(dict[@"class"], NSStringFromClass([view class]));
  XCTAssertEqualObjects(dict[@"description"], [view description]);
  XCTAssertEqualObjects(dict[@"enabled"], @(1));
  XCTAssertEqualObjects(dict[@"frame"][@"x"], @(20));
  XCTAssertEqualObjects(dict[@"frame"][@"y"], @(64));
  XCTAssertEqualObjects(dict[@"frame"][@"width"], @(88));
  XCTAssertEqualObjects(dict[@"frame"][@"height"], @(44));
  XCTAssertEqualObjects(dict[@"id"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"label"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"value"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"visible"], @(1));
  XCTAssertEqual([dict count], 10);
}


- (void) testJsonifyViewUIControl {
  CGRect frame = {20, 64, 88, 44};
  UIControl *view = [[UIControl alloc] initWithFrame:frame];
  NSDictionary *dict = [LPJSONUtils jsonifyView:view];

  XCTAssertEqualObjects(dict[@"accessibilityElement"], @(0));
  XCTAssertEqualObjects(dict[@"alpha"], @(1));
  XCTAssertEqualObjects(dict[@"class"], NSStringFromClass([view class]));
  XCTAssertEqualObjects(dict[@"description"], [view description]);
  XCTAssertEqualObjects(dict[@"enabled"], @(1));
  XCTAssertEqualObjects(dict[@"frame"][@"x"], @(20));
  XCTAssertEqualObjects(dict[@"frame"][@"y"], @(64));
  XCTAssertEqualObjects(dict[@"frame"][@"width"], @(88));
  XCTAssertEqualObjects(dict[@"frame"][@"height"], @(44));
  XCTAssertEqualObjects(dict[@"id"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"label"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"value"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"visible"], @(1));
  XCTAssertEqualObjects(dict[@"selected"], @(0));
  XCTAssertEqual([dict count], 11);
}

- (void) testJsonifyViewUITextField {
  CGRect frame = {20, 64, 88, 44};
  UITextField *view = [[UITextField alloc] initWithFrame:frame];
  NSDictionary *dict = [LPJSONUtils jsonifyView:view];

  NSLog(@"%@", dict);
  XCTAssertEqualObjects(dict[@"accessibilityElement"], @(0));
  XCTAssertEqualObjects(dict[@"alpha"], @(1));
  XCTAssertEqualObjects(dict[@"class"], NSStringFromClass([view class]));
  XCTAssertEqualObjects(dict[@"description"], [view description]);
  XCTAssertEqualObjects(dict[@"enabled"], @(1));
  XCTAssertEqualObjects(dict[@"frame"][@"x"], @(20));
  XCTAssertEqualObjects(dict[@"frame"][@"y"], @(64));
  XCTAssertEqualObjects(dict[@"frame"][@"width"], @(88));
  XCTAssertEqualObjects(dict[@"frame"][@"height"], @(44));
  XCTAssertEqualObjects(dict[@"id"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"label"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"value"], @"");
  XCTAssertEqualObjects(dict[@"visible"], @(1));
  XCTAssertEqualObjects(dict[@"enabled"], @(1));
  XCTAssertEqualObjects(dict[@"selected"], @(0));
  XCTAssertEqualObjects(dict[@"text"], @"");
  XCTAssertEqual([dict count], 12);
}

- (void) testJsonifyViewUITextView {
  CGRect frame = {20, 64, 88, 44};
  UITextView *view = [[UITextView alloc] initWithFrame:frame];
  NSDictionary *dict = [LPJSONUtils jsonifyView:view];

  NSLog(@"%@", dict);
  XCTAssertEqualObjects(dict[@"accessibilityElement"], @(0));
  XCTAssertEqualObjects(dict[@"alpha"], @(1));
  XCTAssertEqualObjects(dict[@"class"], NSStringFromClass([view class]));
  XCTAssertEqualObjects(dict[@"description"], [view description]);
  XCTAssertEqualObjects(dict[@"enabled"], @(1));
  XCTAssertEqualObjects(dict[@"frame"][@"x"], @(20));
  XCTAssertEqualObjects(dict[@"frame"][@"y"], @(64));
  XCTAssertEqualObjects(dict[@"frame"][@"width"], @(88));
  XCTAssertEqualObjects(dict[@"frame"][@"height"], @(44));
  XCTAssertEqualObjects(dict[@"id"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"label"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"value"], @"");
  XCTAssertEqualObjects(dict[@"visible"], @(1));
  XCTAssertEqualObjects(dict[@"enabled"], @(1));
  XCTAssertEqualObjects(dict[@"text"], @"");
  XCTAssertEqual([dict count], 11);
}

@end
