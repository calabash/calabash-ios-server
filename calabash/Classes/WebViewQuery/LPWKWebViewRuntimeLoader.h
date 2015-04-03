#import <Foundation/Foundation.h>

extern NSString *const LPWKWebViewISO8601DateFormat;

typedef enum : NSUInteger {
  LPWKWebViewNotAvailable = 0,
  LPWKWebViewDidImplementProtocol,
  LPWKWebViewFailedToImplementProtocol,
  LPWKWebViewHaveNotTriedToImplementProtocol = NSNotFound
} LPWKWebViewWebViewProtocolImplementation;

@interface LPWKWebViewRuntimeLoader : NSObject

@property(atomic, assign, readonly) LPWKWebViewWebViewProtocolImplementation state;

+ (LPWKWebViewRuntimeLoader *) shared;
- (LPWKWebViewWebViewProtocolImplementation) loadImplementation;

@end

@interface LPWKWebViewMethodInvoker : NSObject

+ (NSString *) stringByInvokingSelector:(SEL) selector
                                 target:(id) target
                               argument:(id) argument;
@end
