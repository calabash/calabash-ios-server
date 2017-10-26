#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPWebQuery.h"
#import "LPConstants.h"

@interface LPWebQuery (TEST)

+ (BOOL) point:(CGPoint) center isVisibleInWebview:(UIWebView *) webView;

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


- (CGRect) iphone4sFrame {
  return CGRectMake(0, 0, 320, 480);
}

- (UIWebView *) webViewWithFrame:(CGRect) frame {
  return [[UIWebView alloc] initWithFrame:frame];
}

#pragma mark - point:isVisibleInWebView:

- (void) testPointIsVisibleInWebViewYES {
  UIWebView *webView = [self webViewWithFrame:[self iphone4sFrame]];
  id mock = [OCMockObject partialMockForObject:webView];
  CGPoint center = CGPointMake(20, 40);
  BOOL isInside = YES;
  [[[mock expect] andReturnValue:OCMOCK_VALUE(isInside)] pointInside:center
                                                           withEvent:nil];

  XCTAssertTrue([LPWebQuery point:center isVisibleInWebview:webView]);
  [mock verify];
}

- (void) testPointIsVisibleInWebViewNotInCenterNO {
  UIWebView *webView = [self webViewWithFrame:[self iphone4sFrame]];
  id mock = [OCMockObject partialMockForObject:webView];
  CGPoint center = CGPointMake(20, 40);
  BOOL isInside = NO;
  [[[mock expect] andReturnValue:OCMOCK_VALUE(isInside)] pointInside:center
                                                           withEvent:nil];

  XCTAssertFalse([LPWebQuery point:center isVisibleInWebview:webView]);
  [mock verify];
}

- (void) testPointIsVisibleInWebViewIsCGPointZero {
  UIWebView *webView = [self webViewWithFrame:[self iphone4sFrame]];
  id mock = [OCMockObject partialMockForObject:webView];
  CGPoint center = CGPointMake(0, 0);
  BOOL isInside = YES;
  [[[mock expect] andReturnValue:OCMOCK_VALUE(isInside)] pointInside:center
                                                           withEvent:nil];

  XCTAssertFalse([LPWebQuery point:center isVisibleInWebview:webView]);
  [mock verify];
}

- (void) testArrayByEvaluatingQueryUnknownType {
  NSArray *actual;
  actual = [LPWebQuery arrayByEvaluatingQuery:nil
                                frameSelector:WEBVIEW_DOCUMENT_FRAME_SELECTOR
                                         type:NSNotFound
                                      webView:nil
                             includeInvisible:NO];
  XCTAssertNil(actual);
}

@end
