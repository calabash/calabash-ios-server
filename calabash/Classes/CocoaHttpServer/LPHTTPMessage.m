#import "LPHTTPMessage.h"


@implementation LPHTTPMessage

- (id)initEmptyRequest
{
	if ((self = [super init]))
	{
		message = CFHTTPMessageCreateEmpty(NULL, YES);
	}
	return self;
}

- (id)initRequestWithMethod:(NSString *)method URL:(NSURL *)url version:(NSString *)version
{
	if ((self = [super init]))
	{
		message = CFHTTPMessageCreateRequest(NULL, (__bridge CFStringRef)method, (__bridge CFURLRef)url, (__bridge CFStringRef)version);
	}
	return self;
}

- (id)initResponseWithStatusCode:(NSInteger)code description:(NSString *)description version:(NSString *)version
{
	if ((self = [super init]))
	{
		message = CFHTTPMessageCreateResponse(NULL, (CFIndex)code, (__bridge CFStringRef)description, (__bridge CFStringRef)version);
	}
	return self;
}

- (void)dealloc
{
	if (message)
	{
		CFRelease(message);
	}
}

- (BOOL)appendData:(NSData *)data
{
	return CFHTTPMessageAppendBytes(message, [data bytes], [data length]);
}

- (BOOL)isHeaderComplete
{
	return CFHTTPMessageIsHeaderComplete(message);
}

- (NSString *)version
{
	return CFBridgingRelease(CFHTTPMessageCopyVersion(message));
}

- (NSString *)method
{
	return CFBridgingRelease(CFHTTPMessageCopyRequestMethod(message));
}

- (NSURL *)url
{
	return CFBridgingRelease(CFHTTPMessageCopyRequestURL(message));
}

- (NSInteger)statusCode
{
	return (NSInteger)CFHTTPMessageGetResponseStatusCode(message);
}

- (NSDictionary *)allHeaderFields
{
	return CFBridgingRelease(CFHTTPMessageCopyAllHeaderFields(message));
}

- (NSString *)headerField:(NSString *)headerField
{
	return CFBridgingRelease(CFHTTPMessageCopyHeaderFieldValue(message, (__bridge CFStringRef)headerField));
}

- (void)setHeaderField:(NSString *)headerField value:(NSString *)headerFieldValue
{
	CFHTTPMessageSetHeaderFieldValue(message, (__bridge CFStringRef)headerField, (__bridge CFStringRef)headerFieldValue);
}

- (NSData *)messageData
{
	return CFBridgingRelease(CFHTTPMessageCopySerializedMessage(message));
}

- (NSData *)body
{
	return CFBridgingRelease(CFHTTPMessageCopyBody(message));
}

- (void)setBody:(NSData *)body
{
	CFHTTPMessageSetBody(message, (__bridge CFDataRef)body);
}

@end
