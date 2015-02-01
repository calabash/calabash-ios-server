#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "LPJSONUtils.h"
#import <OCMock/OCMock.h>

// TODO:  UIBarButton
// TODO:  UINavigationBarButton
// TODO:  UITabBarButton
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
  XCTAssertEqualObjects(dict[@"frame"][@"x"], @(CGRectGetMinX([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"y"], @(CGRectGetMinY([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"width"], @(CGRectGetWidth([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"height"], @(CGRectGetHeight([view frame])));
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
  XCTAssertEqualObjects(dict[@"frame"][@"x"], @(CGRectGetMinX([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"y"], @(CGRectGetMinY([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"width"], @(CGRectGetWidth([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"height"], @(CGRectGetHeight([view frame])));
  XCTAssertEqualObjects(dict[@"id"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"label"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"selected"], @(0));
  XCTAssertEqualObjects(dict[@"value"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"visible"], @(1));
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
  XCTAssertEqualObjects(dict[@"frame"][@"x"], @(CGRectGetMinX([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"y"], @(CGRectGetMinY([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"width"], @(CGRectGetWidth([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"height"], @(CGRectGetHeight([view frame])));
  XCTAssertEqualObjects(dict[@"id"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"label"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"value"], @"");
  XCTAssertEqualObjects(dict[@"visible"], @(1));
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
  XCTAssertEqualObjects(dict[@"frame"][@"x"], @(CGRectGetMinX([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"y"], @(CGRectGetMinY([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"width"], @(CGRectGetWidth([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"height"], @(CGRectGetHeight([view frame])));
  XCTAssertEqualObjects(dict[@"id"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"label"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"value"], @"");
  XCTAssertEqualObjects(dict[@"visible"], @(1));
  XCTAssertEqualObjects(dict[@"text"], @"");
  XCTAssertEqual([dict count], 11);
}

- (void) testJsonifyViewUISlider {
  CGRect frame = {20, 64, 88, 44};
  UISlider *view = [[UISlider alloc] initWithFrame:frame];
  NSDictionary *dict = [LPJSONUtils jsonifyView:view];

  NSLog(@"%@", dict);
  XCTAssertEqualObjects(dict[@"accessibilityElement"], @(0));
  XCTAssertEqualObjects(dict[@"alpha"], @(1));
  XCTAssertEqualObjects(dict[@"class"], NSStringFromClass([view class]));
  XCTAssertEqualObjects(dict[@"description"], [view description]);
  XCTAssertEqualObjects(dict[@"enabled"], @(1));
  XCTAssertEqualObjects(dict[@"frame"][@"x"], @(CGRectGetMinX([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"y"], @(CGRectGetMinY([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"width"], @(CGRectGetWidth([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"height"], @(CGRectGetHeight([view frame])));
  XCTAssertEqualObjects(dict[@"id"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"label"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"selected"], @(0));
  XCTAssertEqualObjects(dict[@"value"], @(0));
  XCTAssertEqualObjects(dict[@"visible"], @(1));
  XCTAssertEqual([dict count], 11);
}

- (void) testJsonifyViewUISwitch {
  CGRect frame = {20, 64, 88, 44};
  UISwitch *view = [[UISwitch alloc] initWithFrame:frame];
  NSDictionary *dict = [LPJSONUtils jsonifyView:view];

  NSLog(@"%@", dict);
  XCTAssertEqualObjects(dict[@"accessibilityElement"], @(0));
  XCTAssertEqualObjects(dict[@"alpha"], @(1));
  XCTAssertEqualObjects(dict[@"class"], NSStringFromClass([view class]));
  XCTAssertEqualObjects(dict[@"description"], [view description]);
  XCTAssertEqualObjects(dict[@"enabled"], @(1));
  XCTAssertEqualObjects(dict[@"frame"][@"x"], @(CGRectGetMinX([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"y"], @(CGRectGetMinY([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"width"], @(CGRectGetWidth([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"height"], @(CGRectGetHeight([view frame])));
  XCTAssertEqualObjects(dict[@"id"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"label"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"selected"], @(0));
  XCTAssertEqualObjects(dict[@"visible"], @(1));
  XCTAssertEqual([dict count], 11);
}

- (void) testJsonifyViewUIButton {
  CGRect frame = {20, 64, 88, 44};
  UIButton *view = [[UIButton alloc] initWithFrame:frame];
  NSDictionary *dict = [LPJSONUtils jsonifyView:view];

  NSLog(@"%@", dict);
  XCTAssertEqualObjects(dict[@"accessibilityElement"], @(0));
  XCTAssertEqualObjects(dict[@"alpha"], @(1));
  XCTAssertEqualObjects(dict[@"class"], NSStringFromClass([view class]));
  XCTAssertEqualObjects(dict[@"description"], [view description]);
  XCTAssertEqualObjects(dict[@"enabled"], @(1));
  XCTAssertEqualObjects(dict[@"frame"][@"x"], @(CGRectGetMinX([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"y"], @(CGRectGetMinY([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"width"], @(CGRectGetWidth([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"height"], @(CGRectGetHeight([view frame])));
  XCTAssertEqualObjects(dict[@"id"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"label"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"visible"], @(1));
  XCTAssertEqual([dict count], 11);
}

- (void) testJsonifyViewUIScrollView {
  CGRect frame = {20, 64, 88, 44};
  UIScrollView *view = [[UIScrollView alloc] initWithFrame:frame];
  NSDictionary *dict = [LPJSONUtils jsonifyView:view];

  NSLog(@"%@", dict);
  XCTAssertEqualObjects(dict[@"accessibilityElement"], @(0));
  XCTAssertEqualObjects(dict[@"alpha"], @(1));
  XCTAssertEqualObjects(dict[@"class"], NSStringFromClass([view class]));
  XCTAssertEqualObjects(dict[@"description"], [view description]);
  XCTAssertEqualObjects(dict[@"enabled"], @(1));
  XCTAssertEqualObjects(dict[@"frame"][@"x"], @(CGRectGetMinX([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"y"], @(CGRectGetMinY([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"width"], @(CGRectGetWidth([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"height"], @(CGRectGetHeight([view frame])));
  XCTAssertEqualObjects(dict[@"id"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"label"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"visible"], @(1));
  XCTAssertEqual([dict count], 10);
}

- (void) testJsonifyViewUITableView {
  CGRect frame = {20, 64, 88, 44};
  UITableView *view = [[UITableView alloc] initWithFrame:frame];
  NSDictionary *dict = [LPJSONUtils jsonifyView:view];

  NSLog(@"%@", dict);
  XCTAssertEqualObjects(dict[@"accessibilityElement"], @(0));
  XCTAssertEqualObjects(dict[@"alpha"], @(1));
  XCTAssertEqualObjects(dict[@"class"], NSStringFromClass([view class]));
  XCTAssertEqualObjects(dict[@"description"], [view description]);
  XCTAssertEqualObjects(dict[@"enabled"], @(1));
  XCTAssertEqualObjects(dict[@"frame"][@"x"], @(CGRectGetMinX([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"y"], @(CGRectGetMinY([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"width"], @(CGRectGetWidth([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"height"], @(CGRectGetHeight([view frame])));
  XCTAssertEqualObjects(dict[@"id"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"label"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"visible"], @(1));
  XCTAssertEqual([dict count], 10);
}

- (void) testJsonifyViewUITableViewCell {
  UITableViewCell *view = [[UITableViewCell alloc]
                       initWithStyle:UITableViewCellStyleDefault
                       reuseIdentifier:@"identifier"];

  NSDictionary *dict = [LPJSONUtils jsonifyView:view];

  NSLog(@"%@", dict);
  XCTAssertEqualObjects(dict[@"accessibilityElement"], @(0));
  XCTAssertEqualObjects(dict[@"alpha"], @(1));
  XCTAssertEqualObjects(dict[@"class"], NSStringFromClass([view class]));
  XCTAssertEqualObjects(dict[@"description"], [view description]);
  XCTAssertEqualObjects(dict[@"enabled"], @(1));
  XCTAssertEqualObjects(dict[@"frame"][@"x"], @(CGRectGetMinX([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"y"], @(CGRectGetMinY([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"width"], @(CGRectGetWidth([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"height"], @(CGRectGetHeight([view frame])));
  XCTAssertEqualObjects(dict[@"id"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"label"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"text"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"value"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"visible"], @(1));
  XCTAssertEqual([dict count], 12);
}

- (void) testJsonifyViewUICollectionView {
  CGRect frame = {20, 64, 88, 44};
  UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
  UICollectionView *view = [[UICollectionView alloc] initWithFrame:frame
                                              collectionViewLayout:layout];
  NSDictionary *dict = [LPJSONUtils jsonifyView:view];

  NSLog(@"%@", dict);
  XCTAssertEqualObjects(dict[@"accessibilityElement"], @(0));
  XCTAssertEqualObjects(dict[@"alpha"], @(1));
  XCTAssertEqualObjects(dict[@"class"], NSStringFromClass([view class]));
  XCTAssertEqualObjects(dict[@"description"], [view description]);
  XCTAssertEqualObjects(dict[@"enabled"], @(1));
  XCTAssertEqualObjects(dict[@"frame"][@"x"], @(CGRectGetMinX([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"y"], @(CGRectGetMinY([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"width"], @(CGRectGetWidth([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"height"], @(CGRectGetHeight([view frame])));
  XCTAssertEqualObjects(dict[@"id"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"label"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"visible"], @(1));
  XCTAssertEqual([dict count], 10);
}

- (void) testJsonifyViewUICollectionViewCell {
  CGRect frame = {20, 64, 88, 44};
  UICollectionViewCell *view = [[UICollectionViewCell alloc] initWithFrame:frame];

  NSDictionary *dict = [LPJSONUtils jsonifyView:view];

  NSLog(@"%@", dict);
  XCTAssertEqualObjects(dict[@"accessibilityElement"], @(0));
  XCTAssertEqualObjects(dict[@"alpha"], @(1));
  XCTAssertEqualObjects(dict[@"class"], NSStringFromClass([view class]));
  XCTAssertEqualObjects(dict[@"description"], [view description]);
  XCTAssertEqualObjects(dict[@"enabled"], @(1));
  XCTAssertEqualObjects(dict[@"frame"][@"x"], @(CGRectGetMinX([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"y"], @(CGRectGetMinY([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"width"], @(CGRectGetWidth([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"height"], @(CGRectGetHeight([view frame])));
  XCTAssertEqualObjects(dict[@"id"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"label"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"value"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"visible"], @(1));
  XCTAssertEqual([dict count], 11);
}

- (void) testJsonifyViewUISegmentedControl {
  CGRect frame = {20, 64, 88, 44};
  UISegmentedControl *view = [[UISegmentedControl alloc] initWithFrame:frame];

  NSDictionary *dict = [LPJSONUtils jsonifyView:view];

  NSLog(@"%@", dict);
  XCTAssertEqualObjects(dict[@"accessibilityElement"], @(0));
  XCTAssertEqualObjects(dict[@"alpha"], @(1));
  XCTAssertEqualObjects(dict[@"class"], NSStringFromClass([view class]));
  XCTAssertEqualObjects(dict[@"description"], [view description]);
  XCTAssertEqualObjects(dict[@"enabled"], @(1));
  XCTAssertEqualObjects(dict[@"frame"][@"x"], @(CGRectGetMinX([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"y"], @(CGRectGetMinY([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"width"], @(CGRectGetWidth([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"height"], @(CGRectGetHeight([view frame])));
  XCTAssertEqualObjects(dict[@"id"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"label"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"value"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"visible"], @(1));
  XCTAssertEqual([dict count], 11);
}

- (void) testJsonifyViewUIPickerView {
  CGRect frame = {20, 64, 88, 44};
  UIPickerView *view = [[UIPickerView alloc] initWithFrame:frame];

  NSDictionary *dict = [LPJSONUtils jsonifyView:view];

  NSLog(@"%@", dict);
  XCTAssertEqualObjects(dict[@"accessibilityElement"], @(0));
  XCTAssertEqualObjects(dict[@"alpha"], @(1));
  XCTAssertEqualObjects(dict[@"class"], NSStringFromClass([view class]));
  XCTAssertEqualObjects(dict[@"description"], [view description]);
  XCTAssertEqualObjects(dict[@"enabled"], @(1));
  XCTAssertEqualObjects(dict[@"frame"][@"x"], @(CGRectGetMinX([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"y"], @(CGRectGetMinY([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"width"], @(CGRectGetWidth([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"height"], @(CGRectGetHeight([view frame])));
  XCTAssertEqualObjects(dict[@"id"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"label"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"value"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"visible"], @(1));
  XCTAssertEqual([dict count], 10);
}

- (void) testJsonifyViewUIDatePicker {
  CGRect frame = {20, 64, 88, 44};
  UIDatePicker *view = [[UIDatePicker alloc] initWithFrame:frame];

  NSDictionary *dict = [LPJSONUtils jsonifyView:view];

  NSLog(@"%@", dict);
  XCTAssertEqualObjects(dict[@"accessibilityElement"], @(0));
  XCTAssertEqualObjects(dict[@"alpha"], @(1));
  XCTAssertEqualObjects(dict[@"class"], NSStringFromClass([view class]));
  XCTAssertEqualObjects(dict[@"description"], [view description]);
  XCTAssertEqualObjects(dict[@"enabled"], @(1));
  XCTAssertEqualObjects(dict[@"frame"][@"x"], @(CGRectGetMinX([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"y"], @(CGRectGetMinY([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"width"], @(CGRectGetWidth([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"height"], @(CGRectGetHeight([view frame])));
  XCTAssertEqualObjects(dict[@"id"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"label"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"value"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"visible"], @(1));
  XCTAssertEqual([dict count], 11);
}


- (void) testJsonifyViewUITabBar {
  CGRect frame = {20, 64, 88, 44};
  UITabBar *view = [[UITabBar alloc] initWithFrame:frame];

  NSDictionary *dict = [LPJSONUtils jsonifyView:view];

  NSLog(@"%@", dict);
  XCTAssertEqualObjects(dict[@"accessibilityElement"], @(0));
  XCTAssertEqualObjects(dict[@"alpha"], @(1));
  XCTAssertEqualObjects(dict[@"class"], NSStringFromClass([view class]));
  XCTAssertEqualObjects(dict[@"description"], [view description]);
  XCTAssertEqualObjects(dict[@"enabled"], @(1));
  XCTAssertEqualObjects(dict[@"frame"][@"x"], @(CGRectGetMinX([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"y"], @(CGRectGetMinY([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"width"], @(CGRectGetWidth([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"height"], @(CGRectGetHeight([view frame])));
  XCTAssertEqualObjects(dict[@"id"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"label"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"value"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"visible"], @(1));
  XCTAssertEqual([dict count], 10);
}

- (void) testJsonifyViewUINavigationBar {
  CGRect frame = {20, 64, 88, 44};
  UINavigationBar *view = [[UINavigationBar alloc] initWithFrame:frame];

  NSDictionary *dict = [LPJSONUtils jsonifyView:view];

  NSLog(@"%@", dict);
  XCTAssertEqualObjects(dict[@"accessibilityElement"], @(0));
  XCTAssertEqualObjects(dict[@"alpha"], @(1));
  XCTAssertEqualObjects(dict[@"class"], NSStringFromClass([view class]));
  XCTAssertEqualObjects(dict[@"description"], [view description]);
  XCTAssertEqualObjects(dict[@"enabled"], @(1));
  XCTAssertEqualObjects(dict[@"frame"][@"x"], @(CGRectGetMinX([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"y"], @(CGRectGetMinY([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"width"], @(CGRectGetWidth([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"height"], @(CGRectGetHeight([view frame])));
  XCTAssertEqualObjects(dict[@"id"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"label"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"value"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"visible"], @(1));
  XCTAssertEqual([dict count], 10);
}

- (void) testJsonifyViewUIToolbar {
  CGRect frame = {20, 64, 88, 44};
  UIToolbar *view = [[UIToolbar alloc] initWithFrame:frame];

  NSDictionary *dict = [LPJSONUtils jsonifyView:view];

  NSLog(@"%@", dict);
  XCTAssertEqualObjects(dict[@"accessibilityElement"], @(0));
  XCTAssertEqualObjects(dict[@"alpha"], @(1));
  XCTAssertEqualObjects(dict[@"class"], NSStringFromClass([view class]));
  XCTAssertEqualObjects(dict[@"description"], [view description]);
  XCTAssertEqualObjects(dict[@"enabled"], @(1));
  XCTAssertEqualObjects(dict[@"frame"][@"x"], @(CGRectGetMinX([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"y"], @(CGRectGetMinY([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"width"], @(CGRectGetWidth([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"height"], @(CGRectGetHeight([view frame])));
  XCTAssertEqualObjects(dict[@"id"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"label"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"value"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"visible"], @(1));
  XCTAssertEqual([dict count], 10);
}

@end
