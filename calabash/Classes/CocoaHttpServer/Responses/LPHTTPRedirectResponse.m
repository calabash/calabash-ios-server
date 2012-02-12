#import "LPHTTPRedirectResponse.h"

// Log levels : off, error, warn, info, verbose
// Other flags: trace


@implementation LPHTTPRedirectResponse

- (id)initWithPath:(NSString *)path
{
	if ((self = [super init]))
	{
		//LPHTTPLogTrace();
		
		redirectPath = [path copy];
	}
	return self;
}

- (UInt64)contentLength
{
	return 0;
}

- (UInt64)offset
{
	return 0;
}

- (void)setOffset:(UInt64)offset
{
	// Nothing to do
}

- (NSData *)readDataOfLength:(NSUInteger)length
{
	//LPHTTPLogTrace();
	
	return nil;
}

- (BOOL)isDone
{
	return YES;
}

- (NSDictionary *)httpHeaders
{
	//LPHTTPLogTrace();
	
	return [NSDictionary dictionaryWithObject:redirectPath forKey:@"Location"];
}

- (NSInteger)status
{
	//LPHTTPLogTrace();
	
	return 302;
}

- (void)dealloc
{
	//LPHTTPLogTrace();
	
	[redirectPath release];
	[super dealloc];
}

@end
