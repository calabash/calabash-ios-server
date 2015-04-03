#import <Foundation/Foundation.h>

extern NSString *const LPRuntimeWKWebViewISO8601DateFormat;

typedef enum : NSUInteger {
  LPWKWebViewNotAvailable = 0,
  LPWKWebViewDidImplementProtocol,
  LPWKWebViewFailedToImplementProtocol
} LPWKWebViewWebViewProtocolImplementation;

@interface LPRuntimeWKWebView : NSObject

+ (LPWKWebViewWebViewProtocolImplementation) implementLPWebViewProtocolOnWKWebView;

@end

@interface LPWKWebViewMethodInvoker : NSObject

+ (NSString *) stringByInvokingSelector:(SEL) selector
                                 target:(id) target
                               argument:(id) argument;
@end
