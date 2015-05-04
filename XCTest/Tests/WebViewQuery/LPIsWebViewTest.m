#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPIsWebView.h"

@interface LPIsWebView (LPXCTEST)

+ (Class) classForWKWebView;

@end

@interface MyUIWebView : UIWebView @end
@implementation MyUIWebView @end

SpecBegin(LPIsWebView)

describe(@".isWebView", ^{

  describe(@"when WebKit is available", ^{
    describe(@"returns true when", ^{
      it(@"a UIWebView", ^{
        UIWebView *view = [[UIWebView alloc] initWithFrame:CGRectZero];
        expect([LPIsWebView isWebView:view]).to.equal(YES);
      });

      it(@"a subclass of UIWebView", ^{
        MyUIWebView *view = [[MyUIWebView alloc] initWithFrame:CGRectZero];
        expect([LPIsWebView isWebView:view]).to.equal(YES);
      });

      it(@"is a WKWebView", ^{
        Class klass = objc_getClass("WKWebView");
        id obj = [[klass alloc] initWithFrame:CGRectZero];
        expect([LPIsWebView isWebView:obj]).to.equal(YES);
      });

      it(@"is a subclass of WKWebView", ^{
        Class klass = objc_getClass("WKWebView");
        Class subclass = objc_allocateClassPair(klass, "MyWKWebView", 0);
        id obj = [[subclass alloc] initWithFrame:CGRectZero];
        expect([LPIsWebView isWebView:obj]).to.equal(YES);
      });
    });

    it(@"returns false otherwise", ^{
      UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
      expect([LPIsWebView isWebView:view]).to.equal(NO);

      NSObject *obj = [NSObject new];
      expect([LPIsWebView isWebView:obj]).to.equal(NO);
    });
  });

  describe(@"when WebKit is not available", ^{
    describe(@"returns true when", ^{
      it(@"a UIWebView", ^{
        UIWebView *view = [[UIWebView alloc] initWithFrame:CGRectZero];
        id mock = [OCMockObject mockForClass:[LPIsWebView class]];
        [[[mock expect] andReturn:nil] classForWKWebView];
        expect([LPIsWebView isWebView:view]).to.equal(YES);
        [mock verify];
      });

      it(@"a subclass of UIWebView", ^{
        MyUIWebView *view = [[MyUIWebView alloc] initWithFrame:CGRectZero];
        id mock = [OCMockObject mockForClass:[LPIsWebView class]];
        [[[mock expect] andReturn:nil] classForWKWebView];
        expect([LPIsWebView isWebView:view]).to.equal(YES);
        [mock verify];
      });
    });

    it(@"returns false otherwise", ^{
      id mock = [OCMockObject mockForClass:[LPIsWebView class]];
      [[[mock expect] andReturn:nil] classForWKWebView];

      UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
      expect([LPIsWebView isWebView:view]).to.equal(NO);
      [mock verify];

      [[[mock expect] andReturn:nil] classForWKWebView];
      NSObject *obj = [NSObject new];
      expect([LPIsWebView isWebView:obj]).to.equal(NO);
      [mock verify];
    });
  });
});

SpecEnd
