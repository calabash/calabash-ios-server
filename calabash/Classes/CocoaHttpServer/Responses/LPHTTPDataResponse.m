#import "LPHTTPDataResponse.h"

// Log levels : off, error, warn, info, verbose
// Other flags: trace


@implementation LPHTTPDataResponse

- (id)initWithData:(NSData *)dataParam
{
	if((self = [super init]))
	{
		//LPHTTPLogTrace();
		
		offset = 0;
		data = [dataParam retain];
	}
	return self;
}

- (void)dealloc
{
	//LPHTTPLogTrace();
	
	[data release];
	[super dealloc];
}

- (UInt64)contentLength
{
	UInt64 result = (UInt64)[data length];
	
	//LPHTTPLogTrace2(@"%@[%p]: contentLength - %llu", THIS_FILE, self, result);
	
	return result;
}

- (UInt64)offset
{
	//LPHTTPLogTrace();
	
	return offset;
}

- (void)setOffset:(UInt64)offsetParam
{
	//LPHTTPLogTrace2(@"%@[%p]: setOffset:%llu", THIS_FILE, self, offset);
	
	offset = (NSUInteger)offsetParam;
}

- (NSData *)readDataOfLength:(NSUInteger)lengthParameter
{
	//LPHTTPLogTrace2(@"%@[%p]: readDataOfLength:%lu", THIS_FILE, self, (unsigned long)lengthParameter);
	
	NSUInteger remaining = [data length] - offset;
	NSUInteger length = lengthParameter < remaining ? lengthParameter : remaining;
	
	void *bytes = (void *)([data bytes] + offset);
	
	offset += length;
	
	return [NSData dataWithBytesNoCopy:bytes length:length freeWhenDone:NO];
}

- (BOOL)isDone
{
	BOOL result = (offset == [data length]);
	
	//LPHTTPLogTrace2(@"%@[%p]: isDone - %@", THIS_FILE, self, (result ? @"YES" : @"NO"));
	
	return result;
}

@end
