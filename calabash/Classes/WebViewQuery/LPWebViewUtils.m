#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPWebViewUtils.h"
#import "LPConstants.h"
#import <objc/runtime.h>

@interface LPWebViewUtils ()

+ (Class) classForWKWebView;

@end

@implementation LPWebViewUtils

+ (Class) classForWKWebView {
  return objc_getClass("WKWebView");
}

+ (BOOL) isWebView:(id) object {
  Class klass = [LPWebViewUtils classForWKWebView];
  if (klass) {
    return
    [object isKindOfClass:[UIWebView class]] ||
    [object isKindOfClass:klass];
  } else {
    return [object isKindOfClass:[UIWebView class]];
  }
}

+ (BOOL) isIFrameResult:(NSDictionary *)result {
  return result[IFRAME_INFO_KEY] != nil;
}

@end
