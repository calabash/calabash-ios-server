#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "UIView+LPIsWebView.h"


@implementation UIView (UIView_LPIsWebView)

- (BOOL) lpIsWebView {
  return

  [self isKindOfClass:[UIWebView class]] ||
  [self isKindOfClass:[WKWebView class]];
}

@end
