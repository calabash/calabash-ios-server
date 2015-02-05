#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "LPJSONUtils.h"
#import <OCMock/OCMock.h>
#import "LPTouchUtils.h"
#import "objc/runtime.h"

@interface LPXCTestSliderWithText : UISlider

@property(copy, nonatomic) NSString *text;

@end

@implementation LPXCTestSliderWithText

@end

@interface LPObjectRetunsFrame : NSObject

@property(copy, nonatomic) NSString *frame;

@end

@implementation LPObjectRetunsFrame

@end

// TODO:  UIBarButton
// TODO:  UINavigationBarButton
// TODO:  UITabBarButton
@interface LPJSONUtils (LPXCTTEST)

+ (void) dictionary:(NSMutableDictionary *) dictionary
    setObjectforKey:(NSString *) key
         whenTarget:(id) target
         respondsTo:(SEL) selector;

+ (NSMutableDictionary *) jsonifyView:(id) view;

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

#pragma mark - jsonifyView:  called on an object that is not a UIView

- (void) testJsonifyViewPassedAString {
  NSString *string = @"string";

  NSDictionary *dict = [LPJSONUtils jsonifyView:string];
  NSLog(@"%@", dict);

  XCTAssertEqualObjects(dict[@"accessibilityElement"], @(0));
  XCTAssertEqualObjects(dict[@"class"], NSStringFromClass([string class]));
  XCTAssertEqualObjects(dict[@"description"], string);
  XCTAssertEqualObjects(dict[@"id"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"label"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"value"], [NSNull null]);
  XCTAssertEqual([dict count], 6);
}

- (void) testJsonifyViewPassedAnNonViewObjectThatRespondsToFrame {
  LPObjectRetunsFrame *framer = [LPObjectRetunsFrame new];
  framer.frame = @"a frame";

  NSDictionary *dict = [LPJSONUtils jsonifyView:framer];

  XCTAssertEqualObjects(dict[@"accessibilityElement"], @(0));
  XCTAssertEqualObjects(dict[@"class"],
                        NSStringFromClass([LPObjectRetunsFrame class]));
  XCTAssertEqualObjects(dict[@"description"], [framer description]);
  XCTAssertEqualObjects(dict[@"id"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"label"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"value"], [NSNull null]);
  XCTAssertEqual([dict count], 6);
}

// Is UISlider the only UIView with value selector?
- (void) testJsonfiyViewValueSettingHasValueTextAccessibilityValue {
  CGRect frame = CGRectMake(20, 64.5, 88, 44.5);

  LPXCTestSliderWithText *view = [[LPXCTestSliderWithText alloc]
                                  initWithFrame:frame];
  view.accessibilityValue = @"ACCESSIBILITY VALUE!";

  float expected = 0.5f;
  view.value = expected;

  NSString *text = @"TEXT!";
  view.text = text;

  NSDictionary *dict = [LPJSONUtils jsonifyView:view];

  XCTAssertEqualObjects(dict[@"accessibilityElement"], @(0));
  XCTAssertEqualObjects(dict[@"alpha"], @(1));
  XCTAssertEqualObjects(dict[@"class"], NSStringFromClass([view class]));
  XCTAssertEqualObjects(dict[@"description"], [view description]);
  XCTAssertEqualObjects(dict[@"enabled"], @(1));
  XCTAssertEqual(((NSDictionary *)[dict objectForKey:@"frame"]).count, 4);
  XCTAssertEqualObjects(dict[@"frame"][@"x"], @(CGRectGetMinX([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"y"], @(CGRectGetMinY([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"width"], @(CGRectGetWidth([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"height"], @(CGRectGetHeight([view frame])));
  XCTAssertEqualObjects(dict[@"id"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"label"], text);
  XCTAssertEqualObjects(dict[@"selected"], @(0));
  XCTAssertEqualObjects(dict[@"text"], text);
  XCTAssertEqualObjects(dict[@"value"], @(expected));
  XCTAssertEqualObjects(dict[@"visible"], @(1));
  XCTAssertEqual([dict count], 12);
}

- (void) testJsonfiyViewValueSettingHasTextAccessibilityValue {
  CGRect frame = CGRectMake(20, 64.5, 88, 44.5);

  UITextField *view = [[UITextField alloc] initWithFrame:frame];
  view.accessibilityValue = @"ACCESSIBILITY VALUE!";
  NSString *text = @"TEXT!";
  view.text = text;

  NSDictionary *dict = [LPJSONUtils jsonifyView:view];

  XCTAssertEqualObjects(dict[@"accessibilityElement"], @(0));
  XCTAssertEqualObjects(dict[@"alpha"], @(1));
  XCTAssertEqualObjects(dict[@"class"], NSStringFromClass([view class]));
  XCTAssertEqualObjects(dict[@"description"], [view description]);
  XCTAssertEqualObjects(dict[@"enabled"], @(1));
  XCTAssertEqual(((NSDictionary *)[dict objectForKey:@"frame"]).count, 4);
  XCTAssertEqualObjects(dict[@"frame"][@"x"], @(CGRectGetMinX([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"y"], @(CGRectGetMinY([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"width"], @(CGRectGetWidth([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"height"], @(CGRectGetHeight([view frame])));
  XCTAssertEqualObjects(dict[@"id"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"label"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"selected"], @(0));
  XCTAssertEqualObjects(dict[@"text"], text);
  XCTAssertEqualObjects(dict[@"value"], text);
  XCTAssertEqualObjects(dict[@"visible"], @(1));
  XCTAssertEqual([dict count], 12);
}

- (void) testJsonfiyViewValueSettingHasAccessibilityValue {
  CGRect frame = CGRectMake(20, 64.5, 88, 44.5);

  UIView *view = [[UIView alloc] initWithFrame:frame];
  NSString *value = @"ACCESSIBILITY VALUE!";
  view.accessibilityValue = value;

  NSDictionary *dict = [LPJSONUtils jsonifyView:view];

  XCTAssertEqualObjects(dict[@"accessibilityElement"], @(0));
  XCTAssertEqualObjects(dict[@"alpha"], @(1));
  XCTAssertEqualObjects(dict[@"class"], NSStringFromClass([view class]));
  XCTAssertEqualObjects(dict[@"description"], [view description]);
  XCTAssertEqualObjects(dict[@"enabled"], @(1));
  XCTAssertEqual(((NSDictionary *)[dict objectForKey:@"frame"]).count, 4);
  XCTAssertEqualObjects(dict[@"frame"][@"x"], @(CGRectGetMinX([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"y"], @(CGRectGetMinY([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"width"], @(CGRectGetWidth([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"height"], @(CGRectGetHeight([view frame])));
  XCTAssertEqualObjects(dict[@"id"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"label"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"value"], value);
  XCTAssertEqualObjects(dict[@"visible"], @(1));
  XCTAssertEqual([dict count], 10);
}

#pragma mark - jsonifyView: when view is subview of a window

- (void) testJsonifyViewUIViewWithMockedWindow {
  CGRect frame = CGRectMake(20, 64.5, 88, 44.5);
  UIView *view = [[UIView alloc] initWithFrame:frame];

  CGRect applicationFrame = [[UIScreen mainScreen] applicationFrame];
  UIWindow *window = [[UIWindow alloc] initWithFrame:applicationFrame];
  [window addSubview:view];
  id mock = [OCMockObject mockForClass:[LPTouchUtils class]];
  [[[mock stub] andReturn:window] windowForView:view];

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
  XCTAssertEqual(((NSDictionary *)[dict objectForKey:@"frame"]).count, 4);
  XCTAssertEqualObjects(dict[@"id"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"label"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"frame"][@"x"], @(CGRectGetMinX([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"y"], @(CGRectGetMinY([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"width"], @(CGRectGetWidth([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"height"], @(CGRectGetHeight([view frame])));
  XCTAssertEqual(((NSDictionary *)[dict objectForKey:@"rect"]).count, 6);
  XCTAssertEqualObjects(dict[@"rect"][@"x"], @(CGRectGetMinX([view frame])));
  XCTAssertEqualObjects(dict[@"rect"][@"y"], @(CGRectGetMinY([view frame])));
  XCTAssertEqualObjects(dict[@"rect"][@"width"], @(CGRectGetWidth([view frame])));
  XCTAssertEqualObjects(dict[@"rect"][@"height"], @(CGRectGetHeight([view frame])));
  XCTAssertEqualObjects(dict[@"rect"][@"center_x"], @(CGRectGetMidX([view frame])));
  XCTAssertEqualObjects(dict[@"rect"][@"center_y"], @(106.75));
  XCTAssertEqualObjects(dict[@"value"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"visible"], @(0));
  XCTAssertEqual([dict count], 11);

  [mock verify];
}

- (void) testJsonifyViewUIViewWithApplicationWindow {
  CGRect frame = CGRectMake(20, 64.5, 88, 44.5);
  UIView *view = [[UIView alloc] initWithFrame:frame];

  UIApplication *app = [UIApplication sharedApplication];
  UIWindow *window = [[app delegate] window];
  XCTAssertNotNil(window);
  [window addSubview:view];

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
  XCTAssertEqual(((NSDictionary *)[dict objectForKey:@"frame"]).count, 4);
  XCTAssertEqualObjects(dict[@"id"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"label"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"frame"][@"x"], @(CGRectGetMinX([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"y"], @(CGRectGetMinY([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"width"], @(CGRectGetWidth([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"height"], @(CGRectGetHeight([view frame])));
  XCTAssertEqual(((NSDictionary *)[dict objectForKey:@"rect"]).count, 6);
  XCTAssertEqualObjects(dict[@"rect"][@"x"], @(CGRectGetMinX([view frame])));
  XCTAssertEqualObjects(dict[@"rect"][@"y"], @(CGRectGetMinY([view frame])));
  XCTAssertEqualObjects(dict[@"rect"][@"width"], @(CGRectGetWidth([view frame])));
  XCTAssertEqualObjects(dict[@"rect"][@"height"], @(CGRectGetHeight([view frame])));
  XCTAssertEqualObjects(dict[@"rect"][@"center_x"], @(CGRectGetMidX([view frame])));
  XCTAssertEqualObjects(dict[@"rect"][@"center_y"], @(CGRectGetMidY([view frame])));
  XCTAssertEqualObjects(dict[@"value"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"visible"], @(1));
  XCTAssertEqual([dict count], 11);
}

#pragma mark - jsonifyView:

- (void) testJsonifyViewUIView {
  CGRect frame = CGRectMake(20, 64.5, 88, 44.5);
  UIView *view = [[UIView alloc] initWithFrame:frame];
  NSDictionary *dict = [LPJSONUtils jsonifyView:view];

  XCTAssertEqualObjects(dict[@"accessibilityElement"], @(0));
  XCTAssertEqualObjects(dict[@"alpha"], @(1));
  XCTAssertEqualObjects(dict[@"class"], NSStringFromClass([view class]));
  XCTAssertEqualObjects(dict[@"description"], [view description]);
  XCTAssertEqualObjects(dict[@"enabled"], @(1));
  XCTAssertEqual(((NSDictionary *)[dict objectForKey:@"frame"]).count, 4);
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
  CGRect frame = CGRectMake(20, 64.5, 88, 44.5);
  UIControl *view = [[UIControl alloc] initWithFrame:frame];
  NSDictionary *dict = [LPJSONUtils jsonifyView:view];

  XCTAssertEqualObjects(dict[@"accessibilityElement"], @(0));
  XCTAssertEqualObjects(dict[@"alpha"], @(1));
  XCTAssertEqualObjects(dict[@"class"], NSStringFromClass([view class]));
  XCTAssertEqualObjects(dict[@"description"], [view description]);
  XCTAssertEqualObjects(dict[@"enabled"], @(1));
  XCTAssertEqual(((NSDictionary *)[dict objectForKey:@"frame"]).count, 4);
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
  CGRect frame = CGRectMake(20, 64.5, 88, 44.5);
  UITextField *view = [[UITextField alloc] initWithFrame:frame];
  NSDictionary *dict = [LPJSONUtils jsonifyView:view];

  XCTAssertEqualObjects(dict[@"accessibilityElement"], @(0));
  XCTAssertEqualObjects(dict[@"alpha"], @(1));
  XCTAssertEqualObjects(dict[@"class"], NSStringFromClass([view class]));
  XCTAssertEqualObjects(dict[@"description"], [view description]);
  XCTAssertEqualObjects(dict[@"enabled"], @(1));
  XCTAssertEqual(((NSDictionary *)[dict objectForKey:@"frame"]).count, 4);
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
  CGRect frame = CGRectMake(20, 64.5, 88, 44.5);
  UITextView *view = [[UITextView alloc] initWithFrame:frame];
  NSDictionary *dict = [LPJSONUtils jsonifyView:view];

  XCTAssertEqualObjects(dict[@"accessibilityElement"], @(1));
  XCTAssertEqualObjects(dict[@"alpha"], @(1));
  XCTAssertEqualObjects(dict[@"class"], NSStringFromClass([view class]));
  XCTAssertEqualObjects(dict[@"description"], [view description]);
  XCTAssertEqualObjects(dict[@"enabled"], @(1));
  XCTAssertEqual(((NSDictionary *)[dict objectForKey:@"frame"]).count, 4);
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
  CGRect frame = CGRectMake(20, 64.5, 88, 44.5);
  UISlider *view = [[UISlider alloc] initWithFrame:frame];
  NSDictionary *dict = [LPJSONUtils jsonifyView:view];

  XCTAssertEqualObjects(dict[@"accessibilityElement"], @(0));
  XCTAssertEqualObjects(dict[@"alpha"], @(1));
  XCTAssertEqualObjects(dict[@"class"], NSStringFromClass([view class]));
  XCTAssertEqualObjects(dict[@"description"], [view description]);
  XCTAssertEqualObjects(dict[@"enabled"], @(1));
  XCTAssertEqual(((NSDictionary *)[dict objectForKey:@"frame"]).count, 4);
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
  CGRect frame = CGRectMake(20, 64.5, 88, 44.5);
  UISwitch *view = [[UISwitch alloc] initWithFrame:frame];
  NSDictionary *dict = [LPJSONUtils jsonifyView:view];

  XCTAssertEqualObjects(dict[@"accessibilityElement"], @(1));
  XCTAssertEqualObjects(dict[@"alpha"], @(1));
  XCTAssertEqualObjects(dict[@"class"], NSStringFromClass([view class]));
  XCTAssertEqualObjects(dict[@"description"], [view description]);
  XCTAssertEqualObjects(dict[@"enabled"], @(1));
  XCTAssertEqual(((NSDictionary *)[dict objectForKey:@"frame"]).count, 4);
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
  CGRect frame = CGRectMake(20, 64.5, 88, 44.5);
  UIButton *view = [[UIButton alloc] initWithFrame:frame];
  NSDictionary *dict = [LPJSONUtils jsonifyView:view];

  XCTAssertEqualObjects(dict[@"accessibilityElement"], @(1));
  XCTAssertEqualObjects(dict[@"alpha"], @(1));
  XCTAssertEqualObjects(dict[@"class"], NSStringFromClass([view class]));
  XCTAssertEqualObjects(dict[@"description"], [view description]);
  XCTAssertEqualObjects(dict[@"enabled"], @(1));
  XCTAssertEqual(((NSDictionary *)[dict objectForKey:@"frame"]).count, 4);
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
  CGRect frame = CGRectMake(20, 64.5, 88, 44.5);
  UIScrollView *view = [[UIScrollView alloc] initWithFrame:frame];
  NSDictionary *dict = [LPJSONUtils jsonifyView:view];

  XCTAssertEqualObjects(dict[@"accessibilityElement"], @(0));
  XCTAssertEqualObjects(dict[@"alpha"], @(1));
  XCTAssertEqualObjects(dict[@"class"], NSStringFromClass([view class]));
  XCTAssertEqualObjects(dict[@"description"], [view description]);
  XCTAssertEqualObjects(dict[@"enabled"], @(1));
  XCTAssertEqual(((NSDictionary *)[dict objectForKey:@"frame"]).count, 4);
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
  CGRect frame = CGRectMake(20, 64.5, 88, 44.5);
  UITableView *view = [[UITableView alloc] initWithFrame:frame];
  NSDictionary *dict = [LPJSONUtils jsonifyView:view];

  XCTAssertEqualObjects(dict[@"accessibilityElement"], @(1));
  XCTAssertEqualObjects(dict[@"alpha"], @(1));
  XCTAssertEqualObjects(dict[@"class"], NSStringFromClass([view class]));
  XCTAssertEqualObjects(dict[@"description"], [view description]);
  XCTAssertEqualObjects(dict[@"enabled"], @(1));
  XCTAssertEqual(((NSDictionary *)[dict objectForKey:@"frame"]).count, 4);
  XCTAssertEqualObjects(dict[@"frame"][@"x"], @(CGRectGetMinX([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"y"], @(CGRectGetMinY([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"width"], @(CGRectGetWidth([view frame])));
  XCTAssertEqualObjects(dict[@"frame"][@"height"], @(CGRectGetHeight([view frame])));
  XCTAssertEqualObjects(dict[@"id"], [NSNull null]);
  XCTAssertEqualObjects(dict[@"label"], @"Empty list");
  XCTAssertEqualObjects(dict[@"visible"], @(1));
  XCTAssertEqual([dict count], 10);
}

- (void) testJsonifyViewUITableViewCell {
  UITableViewCell *view = [[UITableViewCell alloc]
                       initWithStyle:UITableViewCellStyleDefault
                       reuseIdentifier:@"identifier"];

  NSDictionary *dict = [LPJSONUtils jsonifyView:view];

  XCTAssertEqualObjects(dict[@"accessibilityElement"], @(0));
  XCTAssertEqualObjects(dict[@"alpha"], @(1));
  XCTAssertEqualObjects(dict[@"class"], NSStringFromClass([view class]));
  XCTAssertEqualObjects(dict[@"description"], [view description]);
  XCTAssertEqualObjects(dict[@"enabled"], @(1));
  XCTAssertEqual(((NSDictionary *)[dict objectForKey:@"frame"]).count, 4);
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
  CGRect frame = CGRectMake(20, 64.5, 88, 44.5);
  UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
  UICollectionView *view = [[UICollectionView alloc] initWithFrame:frame
                                              collectionViewLayout:layout];
  NSDictionary *dict = [LPJSONUtils jsonifyView:view];

  XCTAssertEqualObjects(dict[@"accessibilityElement"], @(0));
  XCTAssertEqualObjects(dict[@"alpha"], @(1));
  XCTAssertEqualObjects(dict[@"class"], NSStringFromClass([view class]));
  XCTAssertEqualObjects(dict[@"description"], [view description]);
  XCTAssertEqualObjects(dict[@"enabled"], @(1));
  XCTAssertEqual(((NSDictionary *)[dict objectForKey:@"frame"]).count, 4);
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
  CGRect frame = CGRectMake(20, 64.5, 88, 44.5);
  UICollectionViewCell *view = [[UICollectionViewCell alloc] initWithFrame:frame];

  NSDictionary *dict = [LPJSONUtils jsonifyView:view];

  XCTAssertEqualObjects(dict[@"accessibilityElement"], @(0));
  XCTAssertEqualObjects(dict[@"alpha"], @(1));
  XCTAssertEqualObjects(dict[@"class"], NSStringFromClass([view class]));
  XCTAssertEqualObjects(dict[@"description"], [view description]);
  XCTAssertEqualObjects(dict[@"enabled"], @(1));
  XCTAssertEqual(((NSDictionary *)[dict objectForKey:@"frame"]).count, 4);
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
  CGRect frame = CGRectMake(20, 64.5, 88, 44.5);
  UISegmentedControl *view = [[UISegmentedControl alloc] initWithFrame:frame];

  NSDictionary *dict = [LPJSONUtils jsonifyView:view];

  XCTAssertEqualObjects(dict[@"accessibilityElement"], @(0));
  XCTAssertEqualObjects(dict[@"alpha"], @(1));
  XCTAssertEqualObjects(dict[@"class"], NSStringFromClass([view class]));
  XCTAssertEqualObjects(dict[@"description"], [view description]);
  XCTAssertEqualObjects(dict[@"enabled"], @(1));
  XCTAssertEqual(((NSDictionary *)[dict objectForKey:@"frame"]).count, 4);
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
  CGRect frame = CGRectMake(20, 64.5, 88, 44.5);
  UIPickerView *view = [[UIPickerView alloc] initWithFrame:frame];

  NSDictionary *dict = [LPJSONUtils jsonifyView:view];

  XCTAssertEqualObjects(dict[@"accessibilityElement"], @(0));
  XCTAssertEqualObjects(dict[@"alpha"], @(1));
  XCTAssertEqualObjects(dict[@"class"], NSStringFromClass([view class]));
  XCTAssertEqualObjects(dict[@"description"], [view description]);
  XCTAssertEqualObjects(dict[@"enabled"], @(1));
  XCTAssertEqual(((NSDictionary *)[dict objectForKey:@"frame"]).count, 4);
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
  CGRect frame = CGRectMake(20, 64.5, 88, 44.5);
  UIDatePicker *view = [[UIDatePicker alloc] initWithFrame:frame];

  NSDictionary *dict = [LPJSONUtils jsonifyView:view];

  XCTAssertEqualObjects(dict[@"accessibilityElement"], @(0));
  XCTAssertEqualObjects(dict[@"alpha"], @(1));
  XCTAssertEqualObjects(dict[@"class"], NSStringFromClass([view class]));
  XCTAssertEqualObjects(dict[@"description"], [view description]);
  XCTAssertEqualObjects(dict[@"enabled"], @(1));
  XCTAssertEqual(((NSDictionary *)[dict objectForKey:@"frame"]).count, 4);
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
  CGRect frame = CGRectMake(20, 64.5, 88, 44.5);
  UITabBar *view = [[UITabBar alloc] initWithFrame:frame];

  NSDictionary *dict = [LPJSONUtils jsonifyView:view];

  XCTAssertEqualObjects(dict[@"accessibilityElement"], @(0));
  XCTAssertEqualObjects(dict[@"alpha"], @(1));
  XCTAssertEqualObjects(dict[@"class"], NSStringFromClass([view class]));
  XCTAssertEqualObjects(dict[@"description"], [view description]);
  XCTAssertEqualObjects(dict[@"enabled"], @(1));
  XCTAssertEqual(((NSDictionary *)[dict objectForKey:@"frame"]).count, 4);
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
  CGRect frame = CGRectMake(20, 64.5, 88, 44.5);
  UINavigationBar *view = [[UINavigationBar alloc] initWithFrame:frame];

  NSDictionary *dict = [LPJSONUtils jsonifyView:view];

  XCTAssertEqualObjects(dict[@"accessibilityElement"], @(0));
  XCTAssertEqualObjects(dict[@"alpha"], @(1));
  XCTAssertEqualObjects(dict[@"class"], NSStringFromClass([view class]));
  XCTAssertEqualObjects(dict[@"description"], [view description]);
  XCTAssertEqualObjects(dict[@"enabled"], @(1));
  XCTAssertEqual(((NSDictionary *)[dict objectForKey:@"frame"]).count, 4);
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
  CGRect frame = CGRectMake(20, 64.5, 88, 44.5);
  UIToolbar *view = [[UIToolbar alloc] initWithFrame:frame];

  NSDictionary *dict = [LPJSONUtils jsonifyView:view];

  XCTAssertEqualObjects(dict[@"accessibilityElement"], @(0));
  XCTAssertEqualObjects(dict[@"alpha"], @(1));
  XCTAssertEqualObjects(dict[@"class"], NSStringFromClass([view class]));
  XCTAssertEqualObjects(dict[@"description"], [view description]);
  XCTAssertEqualObjects(dict[@"enabled"], @(1));
  XCTAssertEqual(((NSDictionary *)[dict objectForKey:@"frame"]).count, 4);
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
