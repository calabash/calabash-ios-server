#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "UIView+LPIsWebView.h"

@interface MyUIWebView : UIWebView

@end

@implementation MyUIWebView

@end

@interface MyWKWebView : WKWebView

@end

@implementation MyWKWebView

@end

@interface UIView_LPIsWebViewTest : XCTestCase

@end

@implementation UIView_LPIsWebViewTest

@end

SpecBegin(UIView_LPIsWebViewTest)

describe(@"#lpIsWebView", ^{

  describe(@"returns true when", ^{
    it(@"a UIWebView", ^{
      UIWebView *view = [[UIWebView alloc] initWithFrame:CGRectZero];
      expect([view lpIsWebView]).to.equal(YES);
    });

    it(@"a subclass of UIWebView", ^{
      MyUIWebView *view = [[MyUIWebView alloc] initWithFrame:CGRectZero];
      expect([view lpIsWebView]).to.equal(YES);
    });
  });

  describe(@"returns true when", ^{
    it(@"a WKWebView", ^{
      WKWebView *view = [[WKWebView alloc] initWithFrame:CGRectZero];
      expect([view lpIsWebView]).to.equal(YES);
    });

    it(@"a subclass of WKWebView", ^{
      MyWKWebView *view = [[MyWKWebView alloc] initWithFrame:CGRectZero];
      expect([view lpIsWebView]).to.equal(YES);
    });
  });

  it(@"returns false otherwise", ^{
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    expect([view lpIsWebView]).to.equal(NO);
  });
});

SpecEnd
