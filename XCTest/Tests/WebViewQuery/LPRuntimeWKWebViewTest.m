#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "LPRuntimeWKWebView.h"
#import <WebKit/WebKit.h>
#import "LPInvoker.h"
#import "lPWebViewProtocol.h"

@interface LPRuntimeWKWebViewTest : XCTestCase

@end

@implementation LPRuntimeWKWebViewTest

@end

SpecBegin(LPRuntimeWKWebViewTest)

describe(@"LPRuntimeWKWebView", ^{

  __block WKWebView *webView;


  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    [LPRuntimeWKWebView create];
  });

  before(^{
    webView = [[WKWebView alloc] initWithFrame:CGRectZero];
  });

  it(@"implements LPWebViewProtocol", ^{
    BOOL conforms = [webView conformsToProtocol:@protocol(LPWebViewProtocol)];
    expect(conforms).to.equal(YES);
  });

  it(@"#lpStringWithDate:", ^{
    SEL sel = NSSelectorFromString(@"lpStringWithDate:");
    expect([webView respondsToSelector:sel]).to.equal(YES);
  });

});


SpecEnd