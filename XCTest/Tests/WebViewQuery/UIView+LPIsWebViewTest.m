#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "UIView+LPIsWebView.h"

@interface UIView (LPXCTEST)

- (Class) lpClassForWKWebView;

@end


@interface MyUIWebView : UIWebView @end
@implementation MyUIWebView @end

@interface UIView_LPIsWebViewTest : XCTestCase

@end

@implementation UIView_LPIsWebViewTest

@end

SpecBegin(UIView_LPIsWebViewTest)

describe(@"#lpIsWebView", ^{

  describe(@"when WebKit is available", ^{
    describe(@"returns true when", ^{
      it(@"a UIWebView", ^{
        UIWebView *view = [[UIWebView alloc] initWithFrame:CGRectZero];
        expect([view lpIsWebView]).to.equal(YES);
      });

      it(@"a subclass of UIWebView", ^{
        MyUIWebView *view = [[MyUIWebView alloc] initWithFrame:CGRectZero];
        expect([view lpIsWebView]).to.equal(YES);
      });

      it(@"is a WKWebView", ^{
        Class klass = objc_getClass("WKWebView");
        id obj = [[klass alloc] initWithFrame:CGRectZero];
        expect([obj lpIsWebView]).to.equal(YES);
      });

      it(@"is a subclass of WKWebView", ^{
        Class klass = objc_getClass("WKWebView");
        Class subclass = objc_allocateClassPair(klass, "MyWKWebView", 0);
        id obj = [[subclass alloc] initWithFrame:CGRectZero];
        expect([obj lpIsWebView]).to.equal(YES);
      });
    });

    it(@"returns false otherwise", ^{
      UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
      expect([view lpIsWebView]).to.equal(NO);
    });
  });

  describe(@"when WebKit is not available", ^{
    describe(@"returns true when", ^{
      it(@"a UIWebView", ^{
        UIWebView *view = [[UIWebView alloc] initWithFrame:CGRectZero];
        id mock = [OCMockObject partialMockForObject:view];
        [[[mock expect] andReturn:nil] lpClassForWKWebView];
        expect([view lpIsWebView]).to.equal(YES);
        [mock verify];
      });

      it(@"a subclass of UIWebView", ^{
        MyUIWebView *view = [[MyUIWebView alloc] initWithFrame:CGRectZero];
        id mock = [OCMockObject partialMockForObject:view];
        [[[mock expect] andReturn:nil] lpClassForWKWebView];
        expect([view lpIsWebView]).to.equal(YES);
      });
    });

    it(@"returns false otherwise", ^{
      UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
      id mock = [OCMockObject partialMockForObject:view];
      [[[mock expect] andReturn:nil] lpClassForWKWebView];
      expect([view lpIsWebView]).to.equal(NO);
    });
  });
});

SpecEnd
