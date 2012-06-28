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
    CFStringRef mRef = (__bridge CFStringRef) method;
    CFURLRef uRef = (__bridge CFURLRef) url;
    CFStringRef vRef = (__bridge CFStringRef) version;
		message = CFHTTPMessageCreateRequest(NULL, mRef, uRef, vRef);
//		message = CFHTTPMessageCreateRequest(NULL, (CFStringRef)method, (CFURLRef)url, (CFStringRef)version);
	}
	return self;
}

- (id)initResponseWithStatusCode:(NSInteger)code description:(NSString *)description version:(NSString *)version
{
	if ((self = [super init]))
	{
    message = CFHTTPMessageCreateResponse(NULL, 
                                          (CFIndex)code, 
                                          (__bridge CFStringRef)description, 
                                          (__bridge CFStringRef)version);
    // message = CFHTTPMessageCreateResponse(NULL, (CFIndex)code, (CFStringRef)description, (CFStringRef)version);
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
  NSString *result = CFBridgingRelease(CFHTTPMessageCopyVersion(message));
  return result;
//	return [NSMakeCollectable(CFHTTPMessageCopyVersion(message)) autorelease];
}

- (NSString *)method
{
  NSString *result = CFBridgingRelease(CFHTTPMessageCopyRequestMethod(message));
  return result;
//	return [NSMakeCollectable(CFHTTPMessageCopyRequestMethod(message)) autorelease];
}

- (NSURL *)url
{
  NSURL *result = CFBridgingRelease(CFHTTPMessageCopyRequestURL(message));
  return result;
//	return [NSMakeCollectable(CFHTTPMessageCopyRequestURL(message)) autorelease];
}

- (NSInteger)statusCode
{
	return (NSInteger)CFHTTPMessageGetResponseStatusCode(message);
}

- (NSDictionary *)allHeaderFields
{
  NSDictionary *result = CFBridgingRelease(CFHTTPMessageCopyAllHeaderFields(message));
  return result;
  // return [NSMakeCollectable(CFHTTPMessageCopyAllHeaderFields(message)) autorelease];
}

- (NSString *)headerField:(NSString *)headerField
{
  NSString *result = CFBridgingRelease(CFHTTPMessageCopyHeaderFieldValue(message, 
                                                                         (__bridge CFStringRef)headerField));
  return result;
//	return [NSMakeCollectable(CFHTTPMessageCopyHeaderFieldValue(message, (CFStringRef)headerField)) autorelease];
}

- (void)setHeaderField:(NSString *)headerField value:(NSString *)headerFieldValue
{
  CFHTTPMessageSetHeaderFieldValue(message, 
                                   (__bridge CFStringRef)headerField, 
                                   (__bridge CFStringRef)headerFieldValue);
	//CFHTTPMessageSetHeaderFieldValue(message, (CFStringRef)headerField, (CFStringRef)headerFieldValue);
}

- (NSData *)messageData
{
  NSData *result = CFBridgingRelease(CFHTTPMessageCopySerializedMessage(message));
  return result;
//	return [NSMakeCollectable(CFHTTPMessageCopySerializedMessage(message)) autorelease];
}

- (NSData *)body
{
  NSData *result = CFBridgingRelease(CFHTTPMessageCopyBody(message));
  return result;
//	return [NSMakeCollectable(CFHTTPMessageCopyBody(message)) autorelease];
}

- (void)setBody:(NSData *)body
{
  CFHTTPMessageSetBody(message, 
                       (__bridge CFDataRef)body);
//  CFHTTPMessageSetBody(message, (CFDataRef)body);
}

@end
