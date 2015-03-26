#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "UIWebView+LPWebView.h"

@interface UIWebView_LPWebViewTest : XCTestCase

@end

@implementation UIWebView_LPWebViewTest

@end

SpecBegin(UIWebView_LPWebViewTest)

describe(@"UIWebView+LPWebView", ^{

  it(@"#lpStringByEvaulatingJavaScript:", ^{
    UIWebView *webView = [[UIWebView alloc] initWithFrame:CGRectZero];
    NSString *actual = [webView lpStringByEvaulatingJavaScript:@"1 + 2"];
    expect(actual).to.equal(@"3");
  });
});

SpecEnd
