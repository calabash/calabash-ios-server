#import <Foundation/Foundation.h>

@protocol LPWebQuerySameAs <NSObject>

@required

- (BOOL) isSameAs:(id<LPWebQuerySameAs>) other;

@end

@interface LPWebQueryHash : NSObject <LPWebQuerySameAs>

- (id) initWithDictionary:(NSDictionary *) dictionary;
- (BOOL) isValid;

@end

@interface LPWebQueryCenter : LPWebQueryHash

- (NSNumber *) x;
- (NSNumber *) y;

@end

@interface LPWebQueryRect : LPWebQueryHash

- (NSNumber *) center_x;
- (NSNumber *) center_y;
- (NSNumber *) height;
- (NSNumber *) left;
- (NSNumber *) top;
- (NSNumber *) width;
- (NSNumber *) x;
- (NSNumber *) y;

@end

@interface LPWebQueryResult : LPWebQueryHash

- (id) initWithJSON:(NSString *) json;

- (LPWebQueryRect *) rect;
- (LPWebQueryCenter *) center;
- (NSString *) klass;
- (NSString *) href;
- (NSString *) identifier;
- (NSString *) nodeName;
- (NSString *) nodeType;
- (NSString *) textContent;
- (NSString *) webView;

@end
