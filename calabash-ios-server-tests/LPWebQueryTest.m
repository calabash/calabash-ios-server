#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPWebQuery.h"
#import "LPTouchUtils.h"

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

- (void) testArrayByEvaluatingQueryCss {
  NSString *query = @"a";
  LPWebQueryType type = LPWebQueryTypeCSS;
  UIWebView *webView = [self webviewWithFrame:[self iphone4sFrame]];

  NSString *jsEvaled = @"[{\"rect\":{\"left\":100,\"top\":363.4375,\"width\":24.890625,\"height\":20,\"x\":112,\"y\":373.4375},\"nodeType\":\"ELEMENT_NODE\",\"nodeName\":\"A\",\"id\":\"\",\"class\":\"\",\"href\":\"http://www.googl.com/\",\"textContent\":\"link\"}]";

  id mockWebView = [OCMockObject partialMockForObject:webView];
  [[[mockWebView expect]
    andReturn:jsEvaled]
   stringByEvaluatingJavaScriptFromString:OCMOCK_ANY];

  id touchUtilMock = [OCMockObject mockForClass:[LPTouchUtils class]];
  UIWindow *mainWindow = [self appWindow];
  OCMStub([touchUtilMock windowForView:mockWebView]).andReturn(mainWindow);

  NSValue *finalCenter = OCMOCK_VALUE(CGPointMake(112, 393.4375));
  [[[[touchUtilMock stub]
     ignoringNonObjectArgs]
    andReturnValue:finalCenter]
   translateToScreenCoords:CGPointZero];

  id webQueryMock = [OCMockObject mockForClass:[LPWebQuery class]];
  CGPoint pageOffset = CGPointZero;
  [[[webQueryMock stub]
    andReturnValue:OCMOCK_VALUE(pageOffset)]
   pointByAdjustingOffsetForScrollPostionOfWebView:mockWebView];

  NSArray *actualArr = [LPWebQuery arrayByEvaluatingQuery:query
                                                     type:type
                                                  webView:mockWebView
                                         includeInvisible:YES];

  XCTAssertTrue(actualArr.count == 1);

  NSDictionary *actual = actualArr[0];

  NSString *expectedJSON = @"{\"rect\":{\"x\":112,\"left\":100,\"center_x\":112,\"y\":393.4375,\"top\":363.4375,\"width\":24.890625,\"height\":20,\"center_y\":393.4375},\"nodeName\":\"A\",\"id\":\"\",\"textContent\":\"link\",\"center\":{\"X\":112,\"Y\":393.4375},\"nodeType\":\"ELEMENT_NODE\",\"webView\":\"<UIWebView: 0x78d497f0; frame = (0 20; 320 499); autoresize = RM+BM; layer = <CALayer: 0x78d4d680>>\",\"class\":\"\",\"href\":\"http://www.googl.com/\"}";

  NSData *expectedData = [expectedJSON dataUsingEncoding:NSUTF8StringEncoding];
  NSDictionary *expected = [NSJSONSerialization JSONObjectWithData:expectedData
                                                           options:kNilOptions
                                                             error:nil];

  XCTAssertEqual(actual.count, expected.count);

  XCTAssertEqualObjects(actual[@"center"][@"X"], expected[@"center"][@"X"]);
  XCTAssertEqualObjects(actual[@"center"][@"Y"], expected[@"center"][@"Y"]);

  XCTAssertEqualObjects(actual[@"class"], expected[@"class"]);
  XCTAssertEqualObjects(actual[@"href"], expected[@"href"]);
  XCTAssertEqualObjects(actual[@"id"], expected[@"id"]);
  XCTAssertEqualObjects(actual[@"nodeName"], expected[@"nodeName"]);

  XCTAssertEqualObjects(actual[@"rect"][@"height"], expected[@"rect"][@"height"]);
  XCTAssertEqualObjects(actual[@"rect"][@"left"], expected[@"rect"][@"left"]);
  XCTAssertEqualObjects(actual[@"rect"][@"top"], expected[@"rect"][@"top"]);
  XCTAssertEqualObjects(actual[@"rect"][@"width"], expected[@"rect"][@"width"]);
  XCTAssertEqualObjects(actual[@"rect"][@"x"], expected[@"rect"][@"x"]);
  XCTAssertEqualObjects(actual[@"rect"][@"y"], expected[@"rect"][@"y"]);

  XCTAssertEqualObjects(actual[@"textContent"], expected[@"textContent"]);

  XCTAssertNotNil(actual[@"webView"]);

  [mockWebView verify];
  [webQueryMock verify];
  [touchUtilMock verify];
}

@end
