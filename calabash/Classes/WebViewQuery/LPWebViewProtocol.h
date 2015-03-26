@protocol LPWebViewProtocol <NSObject>

@required

// The bridge between UIWebView and WKWebKit.
- (NSString *) lpStringByEvaulatingJavaScript:(NSString *) javascript;

- (BOOL) pointInside:(CGPoint) point withEvent:(UIEvent *) event;
- (UIScrollView *) scrollView;
@end