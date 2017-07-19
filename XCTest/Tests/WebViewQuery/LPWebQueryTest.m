#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPWebQuery.h"
#import "LPTouchUtils.h"
#import "LPWebQueryResult.h"
#import "LPConstants.h"

@interface LPWebQuery (LPXCTTEST)

+ (CGPoint) pointByAdjustingOffsetForScrollPostionOfWebView:(UIWebView *) webView;

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

#pragma mark - Convenience

- (UIWindow *) appWindow {
  UIApplication *app = [UIApplication sharedApplication];
  return [[app delegate] window];
}

- (CGRect) iphone4sFrame {
  return CGRectMake(0, 0, 320, 480);
}

- (UIWebView *) webviewWithFrame:(CGRect) frame {
  return [[UIWebView alloc] initWithFrame:frame];
}

#pragma mark - point:isVisibleInWebView:

- (void) testPointIsVisibleInWebViewYES {
  UIWebView *webView = [self webviewWithFrame:[self iphone4sFrame]];
  id mock = [OCMockObject partialMockForObject:webView];
  CGPoint center = CGPointMake(20, 40);
  BOOL isInside = YES;
  [[[mock expect] andReturnValue:OCMOCK_VALUE(isInside)] pointInside:center withEvent:nil];

  XCTAssertTrue([LPWebQuery point:center isVisibleInWebview:webView]);
  [mock verify];
}

- (void) testPointIsVisibleInWebViewNotInCenterNO {
  UIWebView *webView = [self webviewWithFrame:[self iphone4sFrame]];
  id mock = [OCMockObject partialMockForObject:webView];
  CGPoint center = CGPointMake(20, 40);
  BOOL isInside = NO;
  [[[mock expect] andReturnValue:OCMOCK_VALUE(isInside)] pointInside:center withEvent:nil];

  XCTAssertFalse([LPWebQuery point:center isVisibleInWebview:webView]);
  [mock verify];
}

- (void) testPointIsVisibleInWebViewIsCGPointZero {
  UIWebView *webView = [self webviewWithFrame:[self iphone4sFrame]];
  id mock = [OCMockObject partialMockForObject:webView];
  CGPoint center = CGPointMake(0, 0);
  BOOL isInside = YES;
  [[[mock expect] andReturnValue:OCMOCK_VALUE(isInside)] pointInside:center withEvent:nil];

  XCTAssertFalse([LPWebQuery point:center isVisibleInWebview:webView]);
  [mock verify];
}

#pragma mark - arrayByEvaluatingQuery:frameSelector:Type:webView:includeInvisible:

- (id) mockForEvaluatingJavaScriptInWebView:(UIWebView *) webView
                                    evalsTo:(NSString *) result {
  id mock = [OCMockObject partialMockForObject:webView];
  [[[mock expect]
    andReturn:result]
   stringByEvaluatingJavaScriptFromString:OCMOCK_ANY];
  return mock;
}

- (id) mockTouchUtilsMockingTranslateToScreenCoords:(CGPoint) point
                                         mainWindow:(UIWindow *) mainWindow
                                         forWebView:(UIWebView *) webView {
  id mock = [OCMockObject mockForClass:[LPTouchUtils class]];
  OCMStub([mock windowForView:webView]).andReturn(mainWindow);

  NSValue *finalCenter = OCMOCK_VALUE(point);
  [[[[mock stub]
     ignoringNonObjectArgs]
    andReturnValue:finalCenter]
   translateToScreenCoords:CGPointZero];
  return mock;
}

- (id) mockPointByAdjustingForPageOffsetWithPoint:(CGPoint) point
                                       forWebView:(UIWebView *) webView {
  id mock = [OCMockObject mockForClass:[LPWebQuery class]];
  [[[mock stub]
    andReturnValue:OCMOCK_VALUE(point)]
   pointByAdjustingOffsetForScrollPostionOfWebView:webView];
  return mock;
}

- (void) testArrayByEvaluatingQueryUnknownType {
  NSArray *actual = [LPWebQuery arrayByEvaluatingQuery:nil
                                         frameSelector:WEBVIEW_DOCUMENT_FRAME_SELECTOR
                                                  type:NSNotFound
                                               webView:nil
                                      includeInvisible:NO];
  XCTAssertNil(actual);
}

- (void) testArrayByEvaluatingNoVisibleCenterNotZeroZeroButPointInsideNO {
  if (lp_ios_version_gte(@"9.0")) {
    NSLog(@"WARNING: SKIPPING WebView Test on iOS 9");
  } else {
    NSString *query = @"a";
    LPWebQueryType type = LPWebQueryTypeCSS;
    UIWebView *webView = [self webviewWithFrame:[self iphone4sFrame]];

    NSString *jsEvaled = @"[{\"rect\":{\"left\":100,\"top\":363.4375,\"width\":24.890625,\"height\":20,\"x\":112,\"y\":373.4375},\"nodeType\":\"ELEMENT_NODE\",\"nodeName\":\"A\",\"id\":\"\",\"class\":\"\",\"href\":\"http://www.googl.com/\",\"textContent\":\"link\"}]";

    UIWindow *mainWindow = [self appWindow];
    CGPoint finalCenter = CGPointMake(112, 393.4375);

    id mockWebView = [self mockForEvaluatingJavaScriptInWebView:webView
                                                        evalsTo:jsEvaled];

    id touchUtilMock = [self mockTouchUtilsMockingTranslateToScreenCoords:finalCenter
                                                               mainWindow:mainWindow
                                                               forWebView:mockWebView];
    CGPoint pageOffset = CGPointMake(0, 120);
    id webQueryMock = [self mockPointByAdjustingForPageOffsetWithPoint:pageOffset
                                                            forWebView:mockWebView];
    BOOL notInside = NO;
    [[[mockWebView expect]
      andReturnValue:OCMOCK_VALUE(notInside)]
     // Point must match _exactly_ or the mock will not be called.
     pointInside:CGPointMake(112, 373.4375 + 120) withEvent:nil];

    NSArray *results = [LPWebQuery arrayByEvaluatingQuery:query
                                            frameSelector:WEBVIEW_DOCUMENT_FRAME_SELECTOR
                                                     type:type
                                                  webView:mockWebView
                                         includeInvisible:NO];
    XCTAssertEqual(results.count, 0);

    [mockWebView verify];
    [webQueryMock verify];
    [touchUtilMock verify];
  }
}

- (void) testArrayByEvaluatingNoVisibleCenterIsZeroZeroButInsideYES {
  if (lp_ios_version_gte(@"9.0")) {
    NSLog(@"WARNING: SKIPPING WebView Test on iOS 9");
  } else {

    NSString *query = @"a";
    LPWebQueryType type = LPWebQueryTypeCSS;
    UIWebView *webView = [self webviewWithFrame:[self iphone4sFrame]];

    NSString *jsEvaled = @"[{\"rect\":{\"left\":100,\"top\":363.4375,\"width\":24.890625,\"height\":20,\"x\":112,\"y\":373.4375},\"nodeType\":\"ELEMENT_NODE\",\"nodeName\":\"A\",\"id\":\"\",\"class\":\"\",\"href\":\"http://www.googl.com/\",\"textContent\":\"link\"}]";

    UIWindow *mainWindow = [self appWindow];
    CGPoint finalCenter = CGPointMake(112, 393.4375);

    id mockWebView = [self mockForEvaluatingJavaScriptInWebView:webView
                                                        evalsTo:jsEvaled];

    id touchUtilMock = [self mockTouchUtilsMockingTranslateToScreenCoords:finalCenter
                                                               mainWindow:mainWindow
                                                               forWebView:mockWebView];
    CGPoint pageOffset = CGPointMake(-112, -373.4375);
    id webQueryMock = [self mockPointByAdjustingForPageOffsetWithPoint:pageOffset
                                                            forWebView:mockWebView];
    BOOL notInside = YES;
    [[[mockWebView expect]
      andReturnValue:OCMOCK_VALUE(notInside)]
     // Point must match _exactly_ or the mock will not be called.
     pointInside:CGPointZero withEvent:nil];

    NSArray *results = [LPWebQuery arrayByEvaluatingQuery:query
                                            frameSelector:WEBVIEW_DOCUMENT_FRAME_SELECTOR
                                                     type:type
                                                  webView:mockWebView
                                         includeInvisible:NO];
    XCTAssertEqual(results.count, 0);

    [mockWebView verify];
    [webQueryMock verify];
    [touchUtilMock verify];
  }
}

- (void) testArrayByEvaluatingQueryCss {

  if (lp_ios_version_gte(@"9.0")) {
    NSLog(@"WARNING: SKIPPING WebView Test on iOS 9");
  } else {
    NSString *query = @"a";
    LPWebQueryType type = LPWebQueryTypeCSS;
    UIWebView *webView = [self webviewWithFrame:[self iphone4sFrame]];

    NSString *jsEvaled = @"[{\"rect\":{\"left\":100,\"top\":363.4375,\"width\":24.890625,\"height\":20,\"x\":112,\"y\":373.4375},\"nodeType\":\"ELEMENT_NODE\",\"nodeName\":\"A\",\"id\":\"\",\"class\":\"\",\"href\":\"http://www.googl.com/\",\"textContent\":\"link\"}]";

    UIWindow *mainWindow = [self appWindow];
    CGPoint finalCenter = CGPointMake(112, 393.4375);

    id mockWebView = [self mockForEvaluatingJavaScriptInWebView:webView
                                                        evalsTo:jsEvaled];

    id touchUtilMock = [self mockTouchUtilsMockingTranslateToScreenCoords:finalCenter
                                                               mainWindow:mainWindow
                                                               forWebView:mockWebView];
    CGPoint pageOffset = CGPointZero;
    id webQueryMock = [self mockPointByAdjustingForPageOffsetWithPoint:pageOffset
                                                            forWebView:mockWebView];

    NSArray *results = [LPWebQuery arrayByEvaluatingQuery:query
                                            frameSelector:WEBVIEW_DOCUMENT_FRAME_SELECTOR
                                                     type:type
                                                  webView:mockWebView
                                         includeInvisible:YES];

    XCTAssertTrue(results.count == 1);

    LPWebQueryResult *actual = [[LPWebQueryResult alloc] initWithDictionary:results[0]];
    XCTAssertTrue([actual isValid]);

    NSString *expectedJSON = @"{\"rect\":{\"x\":112,\"left\":100,\"center_x\":112,\"y\":393.4375,\"top\":363.4375,\"width\":24.890625,\"height\":20,\"center_y\":393.4375},\"nodeName\":\"A\",\"id\":\"\",\"textContent\":\"link\",\"center\":{\"X\":112,\"Y\":393.4375},\"nodeType\":\"ELEMENT_NODE\",\"webView\":\"<UIWebView: 0x78d497f0; frame = (0 20; 320 499); autoresize = RM+BM; layer = <CALayer: 0x78d4d680>>\",\"class\":\"\",\"href\":\"http://www.googl.com/\"}";

    LPWebQueryResult *expected = [[LPWebQueryResult alloc] initWithJSON:expectedJSON];

    XCTAssertTrue([actual isSameAs:expected]);

    [mockWebView verify];
    [webQueryMock verify];
    [touchUtilMock verify];
  }
}

@end
