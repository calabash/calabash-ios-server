#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPWebViewUtils.h"
#import "LPDevice.h"
#import <WebKit/WebKit.h>

@interface LPWebViewUtils (LPXCTEST)

+ (Class) classForWKWebView;

@end

@interface MyUIWebView : UIWebView @end
@implementation MyUIWebView @end

@interface MyWKWebView : WKWebView @end
@implementation MyWKWebView @end

SpecBegin(LPIsWebView)

describe(@".isIFrameQueryResult", ^{
  describe(@"returns true when", ^{
    it(@"an iframe result", ^{
      NSDictionary *iframeResult = @{
                                       @"center" : @{
                                           @"X" : @170,
                                           @"Y" : @8942
                                           },
                                       @"webView" : @"<UIWebView: 0xFFFFFFFFF; frame = (0 71; 600 529); autoresize = RM+BM; layer = <CALayer: 0xFFFFFFFFF>>",
                                       @"nodeName" : @"IFRAME",
                                       @"iframe_info" : @{
                                           @"iframe_query_type" : @0,
                                           @"iframe_query" : @"*"
                                       },
                                       @"id" : @"contact-subject",
                                       @"textContent" : @"",
                                       @"class" : @"form-control",
                                       @"rect" : @{
                                           @"x" : @178,
                                           @"height" : @34,
                                           @"y" : @1388.875,
                                           @"width" : @310,
                                           @"left" : @23,
                                           @"top" : @1301.375,
                                           @"center_y" : @1388.875,
                                           @"center_x" : @178
                                           },
                                       @"nodeType" : @"ELEMENT_NODE"
                                       };
      expect([LPWebViewUtils isIFrameResult:iframeResult]).to.equal(YES);
    });
  });
  describe(@"returns false when", ^{
    it(@"not an iframe result", ^{
      NSDictionary *inputTagResult = @{
                                       @"center" : @{
                                           @"X" : @170,
                                           @"Y" : @8942
                                           },
                                       @"webView" : @"<UIWebView: 0xFFFFFFFFF; frame = (0 71; 600 529); autoresize = RM+BM; layer = <CALayer: 0xFFFFFFFFF>>",
                                       @"nodeName" : @"INPUT",
                                       @"id" : @"contact-subject",
                                       @"textContent" : @"",
                                       @"class" : @"form-control",
                                       @"rect" : @{
                                           @"x" : @178,
                                           @"height" : @34,
                                           @"y" : @1388.875,
                                           @"width" : @310,
                                           @"left" : @23,
                                           @"top" : @1301.375,
                                           @"center_y" : @1388.875,
                                           @"center_x" : @178
                                           },
                                       @"nodeType" : @"ELEMENT_NODE"
                                       };
      expect([LPWebViewUtils isIFrameResult:inputTagResult]).to.equal(NO);
    });
  });
});

describe(@".isWebView", ^{

  describe(@"when WebKit is available", ^{
    describe(@"returns true when", ^{
      it(@"a UIWebView", ^{
        UIWebView *view = [[UIWebView alloc] initWithFrame:CGRectZero];
        expect([LPWebViewUtils isWebView:view]).to.equal(YES);
      });

      it(@"a subclass of UIWebView", ^{
        MyUIWebView *view = [[MyUIWebView alloc] initWithFrame:CGRectZero];
        expect([LPWebViewUtils isWebView:view]).to.equal(YES);
      });

      it(@"is a WKWebView", ^{
        Class klass = objc_getClass("WKWebView");
        id obj = [[klass alloc] initWithFrame:CGRectZero];
        expect([LPWebViewUtils isWebView:obj]).to.equal(YES);
      });

      it(@"is a subclass of WKWebView", ^{
        MyWKWebView *view = [[MyWKWebView alloc] initWithFrame:CGRectZero];
        expect([LPWebViewUtils isWebView:view]).to.equal(YES);
      });
    });

    it(@"returns false otherwise", ^{
      UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
      expect([LPWebViewUtils isWebView:view]).to.equal(NO);

      NSObject *obj = [NSObject new];
      expect([LPWebViewUtils isWebView:obj]).to.equal(NO);
    });
  });

  describe(@"when WebKit is not available", ^{
    describe(@"returns true when", ^{
      it(@"a UIWebView", ^{
        UIWebView *view = [[UIWebView alloc] initWithFrame:CGRectZero];
        id mock = [OCMockObject mockForClass:[LPWebViewUtils class]];
        [[[mock expect] andReturn:nil] classForWKWebView];
        expect([LPWebViewUtils isWebView:view]).to.equal(YES);
        [mock verify];
      });

      it(@"a subclass of UIWebView", ^{
        MyUIWebView *view = [[MyUIWebView alloc] initWithFrame:CGRectZero];
        id mock = [OCMockObject mockForClass:[LPWebViewUtils class]];
        [[[mock expect] andReturn:nil] classForWKWebView];
        expect([LPWebViewUtils isWebView:view]).to.equal(YES);
        [mock verify];
      });
    });

    it(@"returns false otherwise", ^{
      id mock = [OCMockObject mockForClass:[LPWebViewUtils class]];
      [[[mock expect] andReturn:nil] classForWKWebView];

      UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
      expect([LPWebViewUtils isWebView:view]).to.equal(NO);
      [mock verify];

      [[[mock expect] andReturn:nil] classForWKWebView];
      NSObject *obj = [NSObject new];
      expect([LPWebViewUtils isWebView:obj]).to.equal(NO);
      [mock verify];
    });
  });
});

SpecEnd
