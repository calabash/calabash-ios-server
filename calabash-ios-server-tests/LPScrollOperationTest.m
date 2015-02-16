#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import <XCTest/XCTest.h>
#import "LPScrollOperation.h"

static const CGFloat kScrollViewWidth   = 320.f;
static const CGFloat kScrollViewHeight  = 480.f;
static const CGFloat kContentInsetValue = 40.f;

@interface LPScrollOperationTest : XCTestCase
@end

@implementation LPScrollOperationTest

#pragma mark - performWithTarget:error: on ScrollView 
#pragma mark - Test scroll down

- (void)testScrollDownWhenThereIsEnoughContentAtTheBottom {
  LPScrollOperation *scrollOperation = [[LPScrollOperation alloc] initWithOperation:@{@"arguments": @[@"down"]}];
  UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, kScrollViewWidth, kScrollViewHeight)];
  scrollView.contentSize = CGSizeMake(kScrollViewWidth, 2*kScrollViewHeight); //No horizontal scrolling
  
  NSError *error = nil;
  [scrollOperation performWithTarget:scrollView error:&error];
  
  XCTAssertTrue(scrollView.contentOffset.y == kScrollViewHeight/2);
}

- (void)testScrollDownWhenThereIsEnoughContentAtTheBottomInPagedScrollView {
  LPScrollOperation *scrollOperation = [[LPScrollOperation alloc] initWithOperation:@{@"arguments": @[@"down"]}];
  UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, kScrollViewWidth, kScrollViewHeight)];
  scrollView.contentSize = CGSizeMake(kScrollViewWidth, 2*kScrollViewHeight); //No horizontal scrolling
  scrollView.pagingEnabled = YES;
  
  NSError *error = nil;
  [scrollOperation performWithTarget:scrollView error:&error];
  
  XCTAssertTrue(scrollView.contentOffset.y == kScrollViewHeight);
}

- (void)testScrollDownWhenThereIsNotEnoughContentAtTheBottom {
  LPScrollOperation *scrollOperation = [[LPScrollOperation alloc] initWithOperation:@{@"arguments": @[@"down"]}];
  UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, kScrollViewWidth, kScrollViewHeight)];
  scrollView.contentSize = CGSizeMake(kScrollViewWidth, 2*kScrollViewHeight); //No horizontal scrolling
  scrollView.contentOffset = CGPointMake(0, kScrollViewHeight - 100);

  
  NSError *error = nil;
  [scrollOperation performWithTarget:scrollView error:&error];
  
  XCTAssertTrue(scrollView.contentOffset.y == kScrollViewHeight);
}

- (void)testScrollDownWhenThereIsNotEnoughContentAtTheBottomWithBottomContentInset {
  LPScrollOperation *scrollOperation = [[LPScrollOperation alloc] initWithOperation:@{@"arguments": @[@"down"]}];
  UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, kScrollViewWidth, kScrollViewHeight)];
  scrollView.contentInset = UIEdgeInsetsMake(0, 0, kContentInsetValue, 0);
  scrollView.contentSize = CGSizeMake(kScrollViewWidth, 2*kScrollViewHeight); //No horizontal scrolling
  scrollView.contentOffset = CGPointMake(0, kScrollViewHeight - 100);
  
  
  NSError *error = nil;
  [scrollOperation performWithTarget:scrollView error:&error];
  
  XCTAssertTrue(scrollView.contentOffset.y == kScrollViewHeight + kContentInsetValue);
}

- (void)testScrollDownWhenThereIsNotEnoughContentAtTheBottomInPagedScrollView {
  LPScrollOperation *scrollOperation = [[LPScrollOperation alloc] initWithOperation:@{@"arguments": @[@"down"]}];
  UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, kScrollViewWidth, kScrollViewHeight)];
  scrollView.contentSize = CGSizeMake(kScrollViewWidth, 2*kScrollViewHeight); //No horizontal scrolling
  scrollView.contentOffset = CGPointMake(0, kScrollViewHeight);
  scrollView.pagingEnabled = YES;
  
  NSError *error = nil;
  [scrollOperation performWithTarget:scrollView error:&error];
  
  XCTAssertTrue(scrollView.contentOffset.y == kScrollViewHeight);
}

- (void)testScrollDownWhenThereIsNotEnoughContentAtTheBottomInPagedScrollViewWithBottomContentInset {
  LPScrollOperation *scrollOperation = [[LPScrollOperation alloc] initWithOperation:@{@"arguments": @[@"down"]}];
  UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, kScrollViewWidth, kScrollViewHeight)];
  scrollView.contentInset = UIEdgeInsetsMake(0, 0, kContentInsetValue, 0);
  scrollView.contentSize = CGSizeMake(kScrollViewWidth, 2*kScrollViewHeight); //No horizontal scrolling
  scrollView.contentOffset = CGPointMake(0, kScrollViewHeight);
  scrollView.pagingEnabled = YES;
  
  NSError *error = nil;
  [scrollOperation performWithTarget:scrollView error:&error];
  
  XCTAssertTrue(scrollView.contentOffset.y == kScrollViewHeight + kContentInsetValue);
}

#pragma mark - Test scroll up

- (void)testScrollUpWhenThereIsEnoughContentAtTheTop {
  LPScrollOperation *scrollOperation = [[LPScrollOperation alloc] initWithOperation:@{@"arguments": @[@"up"]}];
  UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, kScrollViewWidth, kScrollViewHeight)];
  scrollView.contentSize = CGSizeMake(kScrollViewWidth, 2*kScrollViewHeight); //No horizontal scrolling
  scrollView.contentOffset = CGPointMake(0, kScrollViewHeight);
  
  NSError *error = nil;
  [scrollOperation performWithTarget:scrollView error:&error];
  
  XCTAssertTrue(scrollView.contentOffset.y == kScrollViewHeight/2);
}

- (void)testScrollUpWhenThereIsEnoughContentAtTheTopInPagedScrollView {
  LPScrollOperation *scrollOperation = [[LPScrollOperation alloc] initWithOperation:@{@"arguments": @[@"up"]}];
  UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, kScrollViewWidth, kScrollViewHeight)];
  scrollView.contentSize = CGSizeMake(kScrollViewWidth, 2*kScrollViewHeight); //No horizontal scrolling
  scrollView.contentOffset = CGPointMake(0, kScrollViewHeight);
  scrollView.pagingEnabled = YES;

  NSError *error = nil;
  [scrollOperation performWithTarget:scrollView error:&error];
  
  XCTAssertTrue(scrollView.contentOffset.y == 0);
}

- (void)testScrollUpWhenThereIsNotEnoughContentAtTheTop {
  LPScrollOperation *scrollOperation = [[LPScrollOperation alloc] initWithOperation:@{@"arguments": @[@"up"]}];
  UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, kScrollViewWidth, kScrollViewHeight)];
  scrollView.contentSize = CGSizeMake(kScrollViewWidth, 2*kScrollViewHeight); //No horizontal scrolling
  scrollView.contentOffset = CGPointMake(0, kScrollViewHeight/4);
  
  NSError *error = nil;
  [scrollOperation performWithTarget:scrollView error:&error];
  
  XCTAssertTrue(scrollView.contentOffset.y == 0);
}

- (void)testScrollUpWhenThereIsNotEnoughContentAtTheTopWithTopContentInset {
  LPScrollOperation *scrollOperation = [[LPScrollOperation alloc] initWithOperation:@{@"arguments": @[@"up"]}];
  UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, kScrollViewWidth, kScrollViewHeight)];
  scrollView.contentInset = UIEdgeInsetsMake(kContentInsetValue, 0, 0, 0);
  scrollView.contentSize = CGSizeMake(kScrollViewWidth, 2*kScrollViewHeight); //No horizontal scrolling
  scrollView.contentOffset = CGPointMake(0, kScrollViewHeight/4);
  
  NSError *error = nil;
  [scrollOperation performWithTarget:scrollView error:&error];
  
  XCTAssertTrue(scrollView.contentOffset.y == -kContentInsetValue); //minus top inset
}

- (void)testScrollUpWhenThereIsNotEnoughContentAtTheTopInPagedScrollView {
  LPScrollOperation *scrollOperation = [[LPScrollOperation alloc] initWithOperation:@{@"arguments": @[@"up"]}];
  UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, kScrollViewWidth, kScrollViewHeight)];
  scrollView.contentSize = CGSizeMake(kScrollViewWidth, 2*kScrollViewHeight); //No horizontal scrolling
  scrollView.pagingEnabled = YES;
  
  NSError *error = nil;
  [scrollOperation performWithTarget:scrollView error:&error];
  
  XCTAssertTrue(scrollView.contentOffset.y == 0);
}

- (void)testScrollUpWhenThereIsNotEnoughContentAtTheTopInPagedScrollViewWithTopContentInset {
  LPScrollOperation *scrollOperation = [[LPScrollOperation alloc] initWithOperation:@{@"arguments": @[@"up"]}];
  UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, kScrollViewWidth, kScrollViewHeight)];
  scrollView.contentInset = UIEdgeInsetsMake(kContentInsetValue, 0, 0, 0);
  scrollView.contentSize = CGSizeMake(kScrollViewWidth, 2*kScrollViewHeight); //No horizontal scrolling
  scrollView.pagingEnabled = YES;
  
  NSError *error = nil;
  [scrollOperation performWithTarget:scrollView error:&error];
  
  XCTAssertTrue(scrollView.contentOffset.y == -kContentInsetValue); //minus top inset
}

#pragma mark - Test scroll right

- (void)testScrollRightWhenThereIsEnoughContentAtTheRight {
  LPScrollOperation *scrollOperation = [[LPScrollOperation alloc] initWithOperation:@{@"arguments": @[@"right"]}];
  UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, kScrollViewWidth, kScrollViewHeight)];
  scrollView.contentSize = CGSizeMake(2*kScrollViewWidth, kScrollViewHeight); //No vertical scrolling
  
  NSError *error = nil;
  [scrollOperation performWithTarget:scrollView error:&error];
  
  XCTAssertTrue(scrollView.contentOffset.x == kScrollViewWidth/2);
}

- (void)testScrollRightWhenThereIsEnoughContentAtTheRightInPagedScrollView {
  LPScrollOperation *scrollOperation = [[LPScrollOperation alloc] initWithOperation:@{@"arguments": @[@"right"]}];
  UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, kScrollViewWidth, kScrollViewHeight)];
  scrollView.contentSize = CGSizeMake(2*kScrollViewWidth, kScrollViewHeight); //No vertical scrolling
  scrollView.pagingEnabled = YES;
  
  NSError *error = nil;
  [scrollOperation performWithTarget:scrollView error:&error];
  
  XCTAssertTrue(scrollView.contentOffset.x == kScrollViewWidth);
}

- (void)testScrollRightWhenThereIsNotEnoughContentAtTheRight {
  LPScrollOperation *scrollOperation = [[LPScrollOperation alloc] initWithOperation:@{@"arguments": @[@"right"]}];
  UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, kScrollViewWidth, kScrollViewHeight)];
  scrollView.contentSize = CGSizeMake(2*kScrollViewWidth, kScrollViewHeight); //No vertical scrolling
  scrollView.contentOffset = CGPointMake(kScrollViewWidth - 40, 0);
  
  NSError *error = nil;
  [scrollOperation performWithTarget:scrollView error:&error];
  
  XCTAssertTrue(scrollView.contentOffset.x == kScrollViewWidth);
}

- (void)testScrollRightWhenThereIsNotEnoughContentAtTheRightWithRightContentInset {
  LPScrollOperation *scrollOperation = [[LPScrollOperation alloc] initWithOperation:@{@"arguments": @[@"right"]}];
  UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, kScrollViewWidth, kScrollViewHeight)];
  scrollView.contentInset = UIEdgeInsetsMake(0, 0, 0, kContentInsetValue);
  scrollView.contentSize = CGSizeMake(2*kScrollViewWidth, kScrollViewHeight); //No vertical scrolling
  scrollView.contentOffset = CGPointMake(kScrollViewWidth - 40, 0);
  
  NSError *error = nil;
  [scrollOperation performWithTarget:scrollView error:&error];
  
  XCTAssertTrue(scrollView.contentOffset.x == kScrollViewWidth + kContentInsetValue);
}

- (void)testScrollRightWhenThereIsNotEnoughContentAtTheRightInPagedScrollView {
  LPScrollOperation *scrollOperation = [[LPScrollOperation alloc] initWithOperation:@{@"arguments": @[@"right"]}];
  UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, kScrollViewWidth, kScrollViewHeight)];
  scrollView.contentSize = CGSizeMake(2*kScrollViewWidth, kScrollViewHeight); //No vertical scrolling
  scrollView.contentOffset = CGPointMake(kScrollViewWidth, 0);
  scrollView.pagingEnabled = YES;
  
  NSError *error = nil;
  [scrollOperation performWithTarget:scrollView error:&error];
  
  XCTAssertTrue(scrollView.contentOffset.x == kScrollViewWidth);
}

- (void)testScrollRightWhenThereIsNotEnoughContentAtTheRightInPagedScrollViewWithRightContentInset {
  LPScrollOperation *scrollOperation = [[LPScrollOperation alloc] initWithOperation:@{@"arguments": @[@"right"]}];
  UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, kScrollViewWidth, kScrollViewHeight)];
  scrollView.contentInset = UIEdgeInsetsMake(0, 0, 0, kContentInsetValue);
  scrollView.contentSize = CGSizeMake(2*kScrollViewWidth, kScrollViewHeight); //No vertical scrolling
  scrollView.contentOffset = CGPointMake(kScrollViewWidth, 0);
  scrollView.pagingEnabled = YES;
  
  NSError *error = nil;
  [scrollOperation performWithTarget:scrollView error:&error];
  
  XCTAssertTrue(scrollView.contentOffset.x == kScrollViewWidth + kContentInsetValue);
}

#pragma mark - Test scroll left

- (void)testScrollLeftWhenThereIsEnoughContentAtTheLeft {
  LPScrollOperation *scrollOperation = [[LPScrollOperation alloc] initWithOperation:@{@"arguments": @[@"left"]}];
  UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, kScrollViewWidth, kScrollViewHeight)];
  scrollView.contentSize = CGSizeMake(2*kScrollViewWidth, kScrollViewHeight); //No vertical scrolling
  scrollView.contentOffset = CGPointMake(kScrollViewWidth, 0);
  
  NSError *error = nil;
  [scrollOperation performWithTarget:scrollView error:&error];
  
  XCTAssertTrue(scrollView.contentOffset.x == kScrollViewWidth/2);
}

- (void)testScrollLeftWhenThereIsEnoughContentAtTheLeftInPagedScrollView {
  LPScrollOperation *scrollOperation = [[LPScrollOperation alloc] initWithOperation:@{@"arguments": @[@"left"]}];
  UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, kScrollViewWidth, kScrollViewHeight)];
  scrollView.contentSize = CGSizeMake(2*kScrollViewWidth, kScrollViewHeight); //No vertical scrolling
  scrollView.contentOffset = CGPointMake(kScrollViewWidth, 0);
  scrollView.pagingEnabled = YES;
  
  NSError *error = nil;
  [scrollOperation performWithTarget:scrollView error:&error];
  
  XCTAssertTrue(scrollView.contentOffset.x == 0);
}

- (void)testScrollLeftWhenThereIsNotEnoughContentAtTheLeft {
  LPScrollOperation *scrollOperation = [[LPScrollOperation alloc] initWithOperation:@{@"arguments": @[@"left"]}];
  UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, kScrollViewWidth, kScrollViewHeight)];
  scrollView.contentSize = CGSizeMake(2*kScrollViewWidth, kScrollViewHeight); //No vertical scrolling
  scrollView.contentOffset = CGPointMake(kScrollViewWidth/4, 0);
  
  NSError *error = nil;
  [scrollOperation performWithTarget:scrollView error:&error];
  
  XCTAssertTrue(scrollView.contentOffset.x == 0);
}

- (void)testScrollLeftWhenThereIsNotEnoughContentAtTheLeftWithLeftContentInset {
  LPScrollOperation *scrollOperation = [[LPScrollOperation alloc] initWithOperation:@{@"arguments": @[@"left"]}];
  UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, kScrollViewWidth, kScrollViewHeight)];
    scrollView.contentInset = UIEdgeInsetsMake(0, kContentInsetValue, 0, 0);
  scrollView.contentSize = CGSizeMake(2*kScrollViewWidth, kScrollViewHeight); //No vertical scrolling
  scrollView.contentOffset = CGPointMake(kScrollViewWidth/4, 0);
  
  NSError *error = nil;
  [scrollOperation performWithTarget:scrollView error:&error];
  
  XCTAssertTrue(scrollView.contentOffset.x == -kContentInsetValue); //minus left inset
}

- (void)testScrollLeftWhenThereIsNotEnoughContentAtTheLeftInPagedScrollView {
  LPScrollOperation *scrollOperation = [[LPScrollOperation alloc] initWithOperation:@{@"arguments": @[@"left"]}];
  UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, kScrollViewWidth, kScrollViewHeight)];
  scrollView.contentSize = CGSizeMake(2*kScrollViewWidth, kScrollViewHeight); //No vertical scrolling
  scrollView.pagingEnabled = YES;
  
  NSError *error = nil;
  [scrollOperation performWithTarget:scrollView error:&error];
  
  XCTAssertTrue(scrollView.contentOffset.x == 0);
}

- (void)testScrollLeftWhenThereIsNotEnoughContentAtTheLeftInPagedScrollViewWithLeftContentInset {
  LPScrollOperation *scrollOperation = [[LPScrollOperation alloc] initWithOperation:@{@"arguments": @[@"left"]}];
  UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, kScrollViewWidth, kScrollViewHeight)];
    scrollView.contentInset = UIEdgeInsetsMake(0, kContentInsetValue, 0, 0);
  scrollView.contentSize = CGSizeMake(2*kScrollViewWidth, kScrollViewHeight); //No vertical scrolling
  scrollView.pagingEnabled = YES;
  
  NSError *error = nil;
  [scrollOperation performWithTarget:scrollView error:&error];
  
  XCTAssertTrue(scrollView.contentOffset.x == -kContentInsetValue); //minus left inset
}

@end
