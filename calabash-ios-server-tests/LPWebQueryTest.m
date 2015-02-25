#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPWebQuery.h"


@interface LPWebQuery (LPXCTTEST)

+ (CGPoint) pointByAdjustingOffsetForScrollPostionOfWebView:(UIWebView *) webView;

@end

@interface LPWebQueryTest : XCTestCase

@end

@implementation LPWebQueryTest

- (void) setUp {
  [super setUp];
}

- (void) tearDown {
  [super tearDown];
}

#pragma mark - Convenience

- (CGRect) iphone4sFrame {
  return CGRectMake(0, 0, 320, 480);
}

- (UIWebView *) webviewWithFrame:(CGRect) frame {
  return [[UIWebView alloc] initWithFrame:frame];
}

#pragma mark - Mocking

- (id) webViewMockWithScrollViewOffset:(CGPoint) scrollViewOffset
                           pageYOffset:(NSString *) pageViewOffset {
  UIWebView *webView = [self webviewWithFrame:[self iphone4sFrame]];

  id mockedScrollView = [OCMockObject partialMockForObject:webView.scrollView];
  CGPoint mockedOffest = scrollViewOffset;
  [[[mockedScrollView expect] andReturnValue:OCMOCK_VALUE(mockedOffest)] contentOffset];

  id mockedWebView = [OCMockObject partialMockForObject:webView];
  [[[mockedWebView expect] andReturn:mockedScrollView] scrollView];
  [[[mockedWebView expect] andReturn:pageViewOffset] stringByEvaluatingJavaScriptFromString:@"window.pageYOffset"];

  return mockedWebView;
}

#pragma mark - pointByAdjustingOffsetForScrollPostionOfWebView:

- (void) testPointByAdjustingOffsetForScrollPositionOfWebViewHappyPath {
  CGFloat scrollViewYOffset = 20;
  CGPoint scrollViewOffset = CGPointMake(0, scrollViewYOffset);

  CGFloat pageYOffsetFloat = 200;
  NSString *pageYOffset = [NSString stringWithFormat:@"%@", @(pageYOffsetFloat)];

  id webView = [self webViewMockWithScrollViewOffset:scrollViewOffset
                                         pageYOffset:pageYOffset];

  CGPoint actual = [LPWebQuery pointByAdjustingOffsetForScrollPostionOfWebView:webView];
  CGPoint expected = CGPointMake(0, pageYOffsetFloat - scrollViewYOffset);
  XCTAssertEqualObjects(NSStringFromCGPoint(actual),
                        NSStringFromCGPoint(expected));
  [webView verify];
}

- (void) testPointByAdjustingOffsetForScrollPositionOfWebViewJavaScriptEvalsNonFloat {
  CGFloat scrollViewYOffset = 20;
  CGPoint scrollViewOffset = CGPointMake(0, scrollViewYOffset);

  NSString *pageYOffset = @"not a number";

  id webView = [self webViewMockWithScrollViewOffset:scrollViewOffset
                                         pageYOffset:pageYOffset];

  CGPoint actual = [LPWebQuery pointByAdjustingOffsetForScrollPostionOfWebView:webView];
  CGPoint expected = CGPointMake(0, (-1.0 * scrollViewYOffset));
  XCTAssertEqualObjects(NSStringFromCGPoint(actual),
                        NSStringFromCGPoint(expected));
  [webView verify];
}


#pragma mark - arrayByEvaluatingQuery:Type:webView:includeInvisible:

- (void) testArrayByEvaluatingQueryUnknownType {
  NSArray *actual = [LPWebQuery arrayByEvaluatingQuery:nil
                                                  type:NSNotFound
                                               webView:nil
                                      includeInvisible:NO];
  XCTAssertNil(actual);
}

@end
