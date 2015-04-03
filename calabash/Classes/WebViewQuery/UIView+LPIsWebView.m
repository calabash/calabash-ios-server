#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "UIView+LPIsWebView.h"

@interface UIView (UIView_LPIsWebView_Private)

- (Class) lpClassForWKWebView;

@end

@implementation UIView (UIView_LPIsWebView)

- (Class) lpClassForWKWebView {
  return objc_getClass("WKWebView");
}

- (BOOL) lpIsWebView {
  Class klass = [self lpClassForWKWebView];
  if (klass) {
    return
    [self isKindOfClass:[UIWebView class]] ||
    [self isKindOfClass:klass];
  } else {
    return [self isKindOfClass:[UIWebView class]];
  }
}

@end
