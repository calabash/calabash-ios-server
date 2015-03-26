#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "UIWebView+LPWebView.h"

@implementation UIWebView (UIWebView_LPWebView)

- (NSString *) lpStringByEvaulatingJavaScript:(NSString *) javascript {
  return [self stringByEvaluatingJavaScriptFromString:javascript];
}

@end
