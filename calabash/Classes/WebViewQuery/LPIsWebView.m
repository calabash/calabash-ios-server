#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPIsWebView.h"
#import <objc/runtime.h>

@interface LPIsWebView ()

+ (Class) classForWKWebView;

@end

@implementation LPIsWebView

+ (Class) classForWKWebView {
  return objc_getClass("WKWebView");
}

+ (BOOL) isWebView:(id) object {
  Class klass = [LPIsWebView classForWKWebView];
  if (klass) {
    return
    [object isKindOfClass:[UIWebView class]] ||
    [object isKindOfClass:klass];
  } else {
    return [object isKindOfClass:[UIWebView class]];
  }
}

@end
