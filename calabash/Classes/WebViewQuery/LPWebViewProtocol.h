@protocol LPWebViewProtocol <NSObject>

@required

- (NSString *) lpStringByEvaulatingJavaScript:(NSString *) javascript;

@end