#import <Foundation/Foundation.h>

extern NSString *const LPWKWebViewISO8601DateFormat;

typedef enum : NSUInteger {
  LPWKWebViewNotAvailable = 0,
  LPWKWebViewDidImplementProtocol,
  LPWKWebViewFailedToImplementProtocol
} LPWKWebViewWebViewProtocolImplementation;

@interface LPWKWebViewRuntimeLoader : NSObject

+ (LPWKWebViewRuntimeLoader *) shared;
+ (LPWKWebViewWebViewProtocolImplementation) implementLPWebViewProtocolOnWKWebView;

@end

@interface LPWKWebViewMethodInvoker : NSObject

+ (NSString *) stringByInvokingSelector:(SEL) selector
                                 target:(id) target
                               argument:(id) argument;
@end
