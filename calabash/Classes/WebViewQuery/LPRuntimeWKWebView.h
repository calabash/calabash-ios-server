#import <Foundation/Foundation.h>

extern NSString *const LPRuntimeWKWebViewISO8601DateFormat;

@interface LPRuntimeWKWebView : NSObject

+ (BOOL) create;

@end

@interface LPJSReturnedObjectParser : NSObject

- (NSString *) lpStringWithDate:(NSDate *) date;
- (NSString *) lpStringWithDictionary:(NSDictionary *) dictionary;
- (NSString *) lpStringWithArray:(NSArray *) array;

@end
