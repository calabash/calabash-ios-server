#import <Foundation/Foundation.h>
#import "LPHTTPResponse.h"


@interface LPHTTPRedirectResponse : NSObject <LPHTTPResponse>
{
	NSString *redirectPath;
}

- (id)initWithPath:(NSString *)redirectPath;

@end
