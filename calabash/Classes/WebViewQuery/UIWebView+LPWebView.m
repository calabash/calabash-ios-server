#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "UIWebView+LPWebView.h"

@implementation UIWebView (UIWebView_LPWebView)

- (NSString *) calabashStringByEvaluatingJavaScript:(NSString *) javascript {
  if ([[NSThread currentThread] isMainThread]) {
    return [self stringByEvaluatingJavaScriptFromString:javascript];
  } else {
    __block NSString *result = nil;
    dispatch_sync(dispatch_get_main_queue(), ^{
      result = [self stringByEvaluatingJavaScriptFromString:javascript];
    });
    return result;
  }
}

@end
