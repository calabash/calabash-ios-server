#import "GCDAsyncSocket.h"
#import "LPHTTPServer.h"
#import "LPHTTPConnection.h"
#import "LPHTTPMessage.h"
#import "LPHTTPResponse.h"
#import "LPHTTPAuthenticationRequest.h"
#import "DDNumber.h"
#import "DDRange.h"
#import "DDData.h"
#import "LPHTTPFileResponse.h"
#import "LPHTTPAsyncFileResponse.h"


// Log levels: off, error, warn, info, verbose
// Other flags: trace

// Define chunk size used to read in data for responses
// This is how much data will be read from disk into RAM at a time
#if TARGET_OS_IPHONE
  #define READ_CHUNKSIZE  (1024 * 128)
#else
  #define READ_CHUNKSIZE  (1024 * 512)
#endif

// Define chunk size used to read in POST upload data
#if TARGET_OS_IPHONE
  #define POST_CHUNKSIZE  (1024 * 32)
#else
  #define POST_CHUNKSIZE  (1024 * 128)
#endif

// Define the various timeouts (in seconds) for various parts of the LPHTTP process
#define TIMEOUT_READ_FIRST_HEADER_LINE       30
#define TIMEOUT_READ_SUBSEQUENT_HEADER_LINE  30
#define TIMEOUT_READ_BODY                    -1
#define TIMEOUT_WRITE_HEAD                   30
#define TIMEOUT_WRITE_BODY                   -1
#define TIMEOUT_WRITE_ERROR                  30
#define TIMEOUT_NONCE                       300

// Define the various limits
// MAX_HEADER_LINE_LENGTH: Max length (in bytes) of any single line in a header (including \r\n)
// MAX_HEADER_LINES      : Max number of lines in a single header (including first GET line)
#define MAX_HEADER_LINE_LENGTH  8190
#define MAX_HEADER_LINES         100
// MAX_CHUNK_LINE_LENGTH : For accepting chunked transfer uploads, max length of chunk size line (including \r\n)
#define MAX_CHUNK_LINE_LENGTH    200

// Define the various tags we'll use to differentiate what it is we're currently doing
#define LPHTTP_REQUEST_HEADER                10
#define LPHTTP_REQUEST_BODY                  11
#define LPHTTP_REQUEST_CHUNK_SIZE            12
#define LPHTTP_REQUEST_CHUNK_DATA            13
#define LPHTTP_REQUEST_CHUNK_TRAILER         14
#define LPHTTP_REQUEST_CHUNK_FOOTER          15
#define LPHTTP_PARTIAL_RESPONSE              20
#define LPHTTP_PARTIAL_RESPONSE_HEADER       21
#define LPHTTP_PARTIAL_RESPONSE_BODY         22
#define LPHTTP_CHUNKED_RESPONSE_HEADER       30
#define LPHTTP_CHUNKED_RESPONSE_BODY         31
#define LPHTTP_CHUNKED_RESPONSE_FOOTER       32
#define LPHTTP_PARTIAL_RANGE_RESPONSE_BODY   40
#define LPHTTP_PARTIAL_RANGES_RESPONSE_BODY  50
#define LPHTTP_RESPONSE                      90
#define LPHTTP_FINAL_RESPONSE                91

// A quick note about the tags:
// 
// The LPHTTP_RESPONSE and LPHTTP_FINAL_RESPONSE are designated tags signalling that the response is completely sent.
// That is, in the onSocket:didWriteDataWithTag: method, if the tag is LPHTTP_RESPONSE or LPHTTP_FINAL_RESPONSE,
// it is assumed that the response is now completely sent.
// Use LPHTTP_RESPONSE if it's the end of a response, and you want to start reading more requests afterwards.
// Use LPHTTP_FINAL_RESPONSE if you wish to terminate the connection after sending the response.
// 
// If you are sending multiple data segments in a custom response, make sure that only the last segment has
// the LPHTTP_RESPONSE tag. For all other segments prior to the last segment use LPHTTP_PARTIAL_RESPONSE, or some other
// tag of your own invention.

@interface LPHTTPConnection (PrivateAPI)
- (void)startReadingRequest;
- (void)sendResponseHeadersAndBody;
@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation LPHTTPConnection

static NSMutableArray *recentNonces;

/**
 * This method is automatically called (courtesy of Cocoa) before the first instantiation of this class.
 * We use it to initialize any static variables.
**/
+ (void)initialize
{
	static BOOL initialized = NO;
	if(!initialized)
	{
		// Initialize class variables
		recentNonces = [[NSMutableArray alloc] initWithCapacity:5];
		
		initialized = YES;
	}
}

/**
 * This method is designed to be called by a scheduled timer, and will remove a nonce from the recent nonce list.
 * The nonce to remove should be set as the timer's userInfo.
**/
+ (void)removeRecentNonce:(NSTimer *)aTimer
{
	[recentNonces removeObject:[aTimer userInfo]];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Init, Dealloc:
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Sole Constructor.
 * Associates this new LPHTTP connection with the given AsyncSocket.
 * This LPHTTP connection object will become the socket's delegate and take over responsibility for the socket.
**/
- (id)initWithAsyncSocket:(LPGCDAsyncSocket *)newSocket configuration:(LPHTTPConfig *)aConfig
{
	if ((self = [super init]))
	{
		////LPHTTPLogTrace();
		
		if (aConfig.queue)
		{
			connectionQueue = aConfig.queue;
			dispatch_retain(connectionQueue);
		}
		else
		{
			connectionQueue = dispatch_queue_create("LPHTTPConnection", NULL);
		}
		
		// Take over ownership of the socket
		asyncSocket = [newSocket retain];
		[asyncSocket setDelegate:self delegateQueue:connectionQueue];
		
		// Store configuration
		config = [aConfig retain];
		
		// Initialize lastNC (last nonce count).
		// Used with digest access authentication.
		// These must increment for each request from the client.
		lastNC = 0;
		
		// Create a new LPHTTP message
		request = [[LPHTTPMessage alloc] initEmptyRequest];
		
		numHeaderLines = 0;
		
		responseDataSizes = [[NSMutableArray alloc] initWithCapacity:5];
	}
	return self;
}

/**
 * Standard Deconstructor.
**/
- (void)dealloc
{
	//LPHTTPLogTrace();
	
	dispatch_release(connectionQueue);
	
	[asyncSocket setDelegate:nil delegateQueue:NULL];
	[asyncSocket disconnect];
	[asyncSocket release];
	
	[config release];
	
	[request release];
	
	[nonce release];
	
	if ([httpResponse respondsToSelector:@selector(connectionDidClose)])
	{
		[httpResponse connectionDidClose];
	}
	[httpResponse release];
	
	[ranges release];
	[ranges_headers release];
	[ranges_boundry release];
	
	[responseDataSizes release];
	
	[super dealloc];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Method Support
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Returns whether or not the server will accept messages of a given method
 * at a particular URI.
**/
- (BOOL)supportsMethod:(NSString *)method atPath:(NSString *)path
{
	//LPHTTPLogTrace();
	
	// Override me to support methods such as POST.
	// 
	// Things you may want to consider:
	// - Does the given path represent a resource that is designed to accept this method?
	// - If accepting an upload, is the size of the data being uploaded too big?
	//   To do this you can check the requestContentLength variable.
	// 
	// For more information, you can always access the LPHTTPMessage request variable.
	// 
	// You should fall through with a call to [super supportsMethod:method atPath:path]
	// 
	// See also: expectsRequestBodyFromMethod:atPath:
	
	if ([method isEqualToString:@"GET"])
		return YES;
	
	if ([method isEqualToString:@"HEAD"])
		return YES;
		
	return NO;
}

/**
 * Returns whether or not the server expects a body from the given method.
 * 
 * In other words, should the server expect a content-length header and associated body from this method.
 * This would be true in the case of a POST, where the client is sending data,
 * or for something like PUT where the client is supposed to be uploading a file.
**/
- (BOOL)expectsRequestBodyFromMethod:(NSString *)method atPath:(NSString *)path
{
	//LPHTTPLogTrace();
	
	// Override me to add support for other methods that expect the client
	// to send a body along with the request header.
	// 
	// You should fall through with a call to [super expectsRequestBodyFromMethod:method atPath:path]
	// 
	// See also: supportsMethod:atPath:
	
	if ([method isEqualToString:@"POST"])
		return YES;
	
	if ([method isEqualToString:@"PUT"])
		return YES;
	
	return NO;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark LPHTTPS
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Returns whether or not the server is configured to be a secure server.
 * In other words, all connections to this server are immediately secured, thus only secure connections are allowed.
 * This is the equivalent of having an https server, where it is assumed that all connections must be secure.
 * If this is the case, then unsecure connections will not be allowed on this server, and a separate unsecure server
 * would need to be run on a separate port in order to support unsecure connections.
 * 
 * Note: In order to support secure connections, the sslIdentityAndCertificates method must be implemented.
**/
- (BOOL)isSecureServer
{
	//LPHTTPLogTrace();
	
	// Override me to create an https server...
	
	return NO;
}

/**
 * This method is expected to returns an array appropriate for use in kCFStreamSSLCertificates SSL Settings.
 * It should be an array of SecCertificateRefs except for the first element in the array, which is a SecIdentityRef.
**/
- (NSArray *)sslIdentityAndCertificates
{
	//LPHTTPLogTrace();
	
	// Override me to provide the proper required SSL identity.
	
	return nil;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Password Protection
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Returns whether or not the requested resource is password protected.
 * In this generic implementation, nothing is password protected.
**/
- (BOOL)isPasswordProtected:(NSString *)path
{
	//LPHTTPLogTrace();
	
	// Override me to provide password protection...
	// You can configure it for the entire server, or based on the current request
	
	return NO;
}

/**
 * Returns whether or not the authentication challenge should use digest access authentication.
 * The alternative is basic authentication.
 * 
 * If at all possible, digest access authentication should be used because it's more secure.
 * Basic authentication sends passwords in the clear and should be avoided unless using SSL/TLS.
**/
- (BOOL)useDigestAccessAuthentication
{
	//LPHTTPLogTrace();
	
	// Override me to customize the authentication scheme
	// Make sure you understand the security risks of using the weaker basic authentication
	
	return YES;
}

/**
 * Returns the authentication realm.
 * In this generic implmentation, a default realm is used for the entire server.
**/
- (NSString *)realm
{
	//LPHTTPLogTrace();
	
	// Override me to provide a custom realm...
	// You can configure it for the entire server, or based on the current request
	
	return @"defaultRealm@host.com";
}

/**
 * Returns the password for the given username.
**/
- (NSString *)passwordForUser:(NSString *)username
{
	//LPHTTPLogTrace();
	
	// Override me to provide proper password authentication
	// You can configure a password for the entire server, or custom passwords for users and/or resources
	
	// Security Note:
	// A nil password means no access at all. (Such as for user doesn't exist)
	// An empty string password is allowed, and will be treated as any other password. (To support anonymous access)
	
	return nil;
}

/**
 * Generates and returns an authentication nonce.
 * A nonce is a  server-specified string uniquely generated for each 401 response.
 * The default implementation uses a single nonce for each session.
**/
- (NSString *)generateNonce
{
	//LPHTTPLogTrace();
	
	// We use the Core Foundation UUID class to generate a nonce value for us
	// UUIDs (Universally Unique Identifiers) are 128-bit values guaranteed to be unique.
	CFUUIDRef theUUID = CFUUIDCreate(NULL);
	NSString *newNonce = [NSMakeCollectable(CFUUIDCreateString(NULL, theUUID)) autorelease];
	CFRelease(theUUID);
	
	// We have to remember that the LPHTTP protocol is stateless.
	// Even though with version 1.1 persistent connections are the norm, they are not guaranteed.
	// Thus if we generate a nonce for this connection,
	// it should be honored for other connections in the near future.
	// 
	// In fact, this is absolutely necessary in order to support QuickTime.
	// When QuickTime makes it's initial connection, it will be unauthorized, and will receive a nonce.
	// It then disconnects, and creates a new connection with the nonce, and proper authentication.
	// If we don't honor the nonce for the second connection, QuickTime will repeat the process and never connect.
	
	[recentNonces addObject:newNonce];
	
	[NSTimer scheduledTimerWithTimeInterval:TIMEOUT_NONCE
	                                 target:[LPHTTPConnection class]
	                               selector:@selector(removeRecentNonce:)
	                               userInfo:newNonce
	                                repeats:NO];
	return newNonce;
}

/**
 * Returns whether or not the user is properly authenticated.
**/
- (BOOL)isAuthenticated
{
	//LPHTTPLogTrace();
	
	// Extract the authentication information from the Authorization header
	LPHTTPAuthenticationRequest *auth = [[[LPHTTPAuthenticationRequest alloc] initWithRequest:request] autorelease];
	
	if ([self useDigestAccessAuthentication])
	{
		// Digest Access Authentication (RFC 2617)
		
		if(![auth isDigest])
		{
			// User didn't send proper digest access authentication credentials
			return NO;
		}
		
		if ([auth username] == nil)
		{
			// The client didn't provide a username
			// Most likely they didn't provide any authentication at all
			return NO;
		}
		
		NSString *password = [self passwordForUser:[auth username]];
		if (password == nil)
		{
			// No access allowed (username doesn't exist in system)
			return NO;
		}
		
		NSString *url = [[request url] relativeString];
		
		if (![url isEqualToString:[auth uri]])
		{
			// Requested URL and Authorization URI do not match
			// This could be a replay attack
			// IE - attacker provides same authentication information, but requests a different resource
			return NO;
		}
		
		// The nonce the client provided will most commonly be stored in our local (cached) nonce variable
		if (![nonce isEqualToString:[auth nonce]])
		{
			// The given nonce may be from another connection
			// We need to search our list of recent nonce strings that have been recently distributed
			if ([recentNonces containsObject:[auth nonce]])
			{
				// Store nonce in local (cached) nonce variable to prevent array searches in the future
				[nonce release];
				nonce = [[auth nonce] copy];
				
				// The client has switched to using a different nonce value
				// This may happen if the client tries to get a file in a directory with different credentials.
				// The previous credentials wouldn't work, and the client would receive a 401 error
				// along with a new nonce value. The client then uses this new nonce value and requests the file again.
				// Whatever the case may be, we need to reset lastNC, since that variable is on a per nonce basis.
				lastNC = 0;
			}
			else
			{
				// We have no knowledge of ever distributing such a nonce.
				// This could be a replay attack from a previous connection in the past.
				return NO;
			}
		}
		
		long authNC = strtol([[auth nc] UTF8String], NULL, 16);
		
		if (authNC <= lastNC)
		{
			// The nc value (nonce count) hasn't been incremented since the last request.
			// This could be a replay attack.
			return NO;
		}
		lastNC = authNC;
		
		NSString *HA1str = [NSString stringWithFormat:@"%@:%@:%@", [auth username], [auth realm], password];
		NSString *HA2str = [NSString stringWithFormat:@"%@:%@", [request method], [auth uri]];
		
		NSString *HA1 = [[[HA1str dataUsingEncoding:NSUTF8StringEncoding] md5Digest] hexStringValue];
		
		NSString *HA2 = [[[HA2str dataUsingEncoding:NSUTF8StringEncoding] md5Digest] hexStringValue];
		
		NSString *responseStr = [NSString stringWithFormat:@"%@:%@:%@:%@:%@:%@",
								 HA1, [auth nonce], [auth nc], [auth cnonce], [auth qop], HA2];
		
		NSString *response = [[[responseStr dataUsingEncoding:NSUTF8StringEncoding] md5Digest] hexStringValue];
		
		return [response isEqualToString:[auth response]];
	}
	else
	{
		// Basic Authentication
		
		if (![auth isBasic])
		{
			// User didn't send proper base authentication credentials
			return NO;
		}
		
		// Decode the base 64 encoded credentials
		NSString *base64Credentials = [auth base64Credentials];
		
		NSData *temp = [[base64Credentials dataUsingEncoding:NSUTF8StringEncoding] base64Decoded];
		
		NSString *credentials = [[[NSString alloc] initWithData:temp encoding:NSUTF8StringEncoding] autorelease];
		
		// The credentials should be of the form "username:password"
		// The username is not allowed to contain a colon
		
		NSRange colonRange = [credentials rangeOfString:@":"];
		
		if (colonRange.length == 0)
		{
			// Malformed credentials
			return NO;
		}
		
		NSString *credUsername = [credentials substringToIndex:colonRange.location];
		NSString *credPassword = [credentials substringFromIndex:(colonRange.location + colonRange.length)];
		
		NSString *password = [self passwordForUser:credUsername];
		if (password == nil)
		{
			// No access allowed (username doesn't exist in system)
			return NO;
		}
		
		return [password isEqualToString:credPassword];
	}
}

/**
 * Adds a digest access authentication challenge to the given response.
**/
- (void)addDigestAuthChallenge:(LPHTTPMessage *)response
{
	//LPHTTPLogTrace();
	
	NSString *authFormat = @"Digest realm=\"%@\", qop=\"auth\", nonce=\"%@\"";
	NSString *authInfo = [NSString stringWithFormat:authFormat, [self realm], [self generateNonce]];
	
	[response setHeaderField:@"WWW-Authenticate" value:authInfo];
}

/**
 * Adds a basic authentication challenge to the given response.
**/
- (void)addBasicAuthChallenge:(LPHTTPMessage *)response
{
	//LPHTTPLogTrace();
	
	NSString *authFormat = @"Basic realm=\"%@\"";
	NSString *authInfo = [NSString stringWithFormat:authFormat, [self realm]];
	
	[response setHeaderField:@"WWW-Authenticate" value:authInfo];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Core
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Starting point for the LPHTTP connection after it has been fully initialized (including subclasses).
 * This method is called by the LPHTTP server.
**/
- (void)start
{
	dispatch_async(connectionQueue, ^{
		
		if (started) return;
		started = YES;
		
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		[self startConnection];
		
		[pool drain];
	});
}

/**
 * This method is called by the LPHTTPServer if it is asked to stop.
 * The server, in turn, invokes stop on each LPHTTPConnection instance.
**/
- (void)stop
{
	dispatch_async(connectionQueue, ^{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		// Disconnect the socket.
		// The socketDidDisconnect delegate method will handle everything else.
		[asyncSocket disconnect];
		
		[pool drain];
	});
}

/**
 * Starting point for the LPHTTP connection.
**/
- (void)startConnection
{
	// Override me to do any custom work before the connection starts.
	// 
	// Be sure to invoke [super startConnection] when you're done.
	
	//LPHTTPLogTrace();
	
	if ([self isSecureServer])
	{
		// We are configured to be an LPHTTPS server.
		// That is, we secure via SSL/TLS the connection prior to any communication.
		
		NSArray *certificates = [self sslIdentityAndCertificates];
		
		if ([certificates count] > 0)
		{
			// All connections are assumed to be secure. Only secure connections are allowed on this server.
			NSMutableDictionary *settings = [NSMutableDictionary dictionaryWithCapacity:3];
			
			// Configure this connection as the server
			[settings setObject:[NSNumber numberWithBool:YES]
						 forKey:(NSString *)kCFStreamSSLIsServer];
			
			[settings setObject:certificates
						 forKey:(NSString *)kCFStreamSSLCertificates];
			
			// Configure this connection to use the highest possible SSL level
			[settings setObject:(NSString *)kCFStreamSocketSecurityLevelNegotiatedSSL
						 forKey:(NSString *)kCFStreamSSLLevel];
			
			[asyncSocket startTLS:settings];
		}
	}
	
	[self startReadingRequest];
}

/**
 * Starts reading an LPHTTP request.
**/
- (void)startReadingRequest
{
	//LPHTTPLogTrace();
	
	[asyncSocket readDataToData:[LPGCDAsyncSocket CRLFData]
	                withTimeout:TIMEOUT_READ_FIRST_HEADER_LINE
	                  maxLength:MAX_HEADER_LINE_LENGTH
	                        tag:LPHTTP_REQUEST_HEADER];
}

/**
 * Parses the given query string.
 * 
 * For example, if the query is "q=John%20Mayer%20Trio&num=50"
 * then this method would return the following dictionary:
 * { 
 *   q = "John Mayer Trio" 
 *   num = "50" 
 * }
**/
- (NSDictionary *)parseParams:(NSString *)query
{
	NSArray *components = [query componentsSeparatedByString:@"&"];
	NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:[components count]];
	
	NSUInteger i;
	for (i = 0; i < [components count]; i++)
	{ 
		NSString *component = [components objectAtIndex:i];
		if ([component length] > 0)
		{
			NSRange range = [component rangeOfString:@"="];
			if (range.location != NSNotFound)
			{ 
				NSString *escapedKey = [component substringToIndex:(range.location + 0)]; 
				NSString *escapedValue = [component substringFromIndex:(range.location + 1)];
				
				if ([escapedKey length] > 0)
				{
					CFStringRef k, v;
					
					k = CFURLCreateStringByReplacingPercentEscapes(NULL, (CFStringRef)escapedKey, CFSTR(""));
					v = CFURLCreateStringByReplacingPercentEscapes(NULL, (CFStringRef)escapedValue, CFSTR(""));
					
					NSString *key, *value;
					
					key   = [NSMakeCollectable(k) autorelease];
					value = [NSMakeCollectable(v) autorelease];
					
					if (key)
					{
						if (value)
							[result setObject:value forKey:key]; 
						else 
							[result setObject:[NSNull null] forKey:key]; 
					}
				}
			}
		}
	}
	
	return result;
}

/** 
 * Parses the query variables in the request URI. 
 * 
 * For example, if the request URI was "/search.html?q=John%20Mayer%20Trio&num=50" 
 * then this method would return the following dictionary: 
 * { 
 *   q = "John Mayer Trio" 
 *   num = "50" 
 * } 
**/ 
- (NSDictionary *)parseGetParams 
{
	if(![request isHeaderComplete]) return nil;
	
	NSDictionary *result = nil;
	
	NSURL *url = [request url];
	if(url)
	{
		NSString *query = [url query];
		if (query)
		{
			result = [self parseParams:query];
		}
	}
	
	return result; 
}

/**
 * Attempts to parse the given range header into a series of sequential non-overlapping ranges.
 * If successfull, the variables 'ranges' and 'rangeIndex' will be updated, and YES will be returned.
 * Otherwise, NO is returned, and the range request should be ignored.
 **/
- (BOOL)parseRangeRequest:(NSString *)rangeHeader withContentLength:(UInt64)contentLength
{
	//LPHTTPLogTrace();
	
	// Examples of byte-ranges-specifier values (assuming an entity-body of length 10000):
	// 
	// - The first 500 bytes (byte offsets 0-499, inclusive):  bytes=0-499
	// 
	// - The second 500 bytes (byte offsets 500-999, inclusive): bytes=500-999
	// 
	// - The final 500 bytes (byte offsets 9500-9999, inclusive): bytes=-500
	// 
	// - Or bytes=9500-
	// 
	// - The first and last bytes only (bytes 0 and 9999):  bytes=0-0,-1
	// 
	// - Several legal but not canonical specifications of the second 500 bytes (byte offsets 500-999, inclusive):
	// bytes=500-600,601-999
	// bytes=500-700,601-999
	// 
	
	NSRange eqsignRange = [rangeHeader rangeOfString:@"="];
	
	if(eqsignRange.location == NSNotFound) return NO;
	
	NSUInteger tIndex = eqsignRange.location;
	NSUInteger fIndex = eqsignRange.location + eqsignRange.length;
	
	NSString *rangeType  = [[[rangeHeader substringToIndex:tIndex] mutableCopy] autorelease];
	NSString *rangeValue = [[[rangeHeader substringFromIndex:fIndex] mutableCopy] autorelease];
	
	CFStringTrimWhitespace((CFMutableStringRef)rangeType);
	CFStringTrimWhitespace((CFMutableStringRef)rangeValue);
	
	if([rangeType caseInsensitiveCompare:@"bytes"] != NSOrderedSame) return NO;
	
	NSArray *rangeComponents = [rangeValue componentsSeparatedByString:@","];
	
	if([rangeComponents count] == 0) return NO;
	
	[ranges release];
	ranges = [[NSMutableArray alloc] initWithCapacity:[rangeComponents count]];
	
	rangeIndex = 0;
	
	// Note: We store all range values in the form of LPDDRange structs, wrapped in NSValue objects.
	// Since LPDDRange consists of UInt64 values, the range extends up to 16 exabytes.
	
	NSUInteger i;
	for (i = 0; i < [rangeComponents count]; i++)
	{
		NSString *rangeComponent = [rangeComponents objectAtIndex:i];
		
		NSRange dashRange = [rangeComponent rangeOfString:@"-"];
		
		if (dashRange.location == NSNotFound)
		{
			// We're dealing with an individual byte number
			
			UInt64 byteIndex;
			if(![NSNumber parseString:rangeComponent intoUInt64:&byteIndex]) return NO;
			
			if(byteIndex >= contentLength) return NO;
			
			[ranges addObject:[NSValue valueWithDDRange:LPDDMakeRange(byteIndex, 1)]];
		}
		else
		{
			// We're dealing with a range of bytes
			
			tIndex = dashRange.location;
			fIndex = dashRange.location + dashRange.length;
			
			NSString *r1str = [rangeComponent substringToIndex:tIndex];
			NSString *r2str = [rangeComponent substringFromIndex:fIndex];
			
			UInt64 r1, r2;
			
			BOOL hasR1 = [NSNumber parseString:r1str intoUInt64:&r1];
			BOOL hasR2 = [NSNumber parseString:r2str intoUInt64:&r2];
			
			if (!hasR1)
			{
				// We're dealing with a "-[#]" range
				// 
				// r2 is the number of ending bytes to include in the range
				
				if(!hasR2) return NO;
				if(r2 > contentLength) return NO;
				
				UInt64 startIndex = contentLength - r2;
				
				[ranges addObject:[NSValue valueWithDDRange:LPDDMakeRange(startIndex, r2)]];
			}
			else if (!hasR2)
			{
				// We're dealing with a "[#]-" range
				// 
				// r1 is the starting index of the range, which goes all the way to the end
				
				if(r1 >= contentLength) return NO;
				
				[ranges addObject:[NSValue valueWithDDRange:LPDDMakeRange(r1, contentLength - r1)]];
			}
			else
			{
				// We're dealing with a normal "[#]-[#]" range
				// 
				// Note: The range is inclusive. So 0-1 has a length of 2 bytes.
				
				if(r1 > r2) return NO;
				if(r2 >= contentLength) return NO;
				
				[ranges addObject:[NSValue valueWithDDRange:LPDDMakeRange(r1, r2 - r1 + 1)]];
			}
		}
	}
	
	if([ranges count] == 0) return NO;
	
	// Now make sure none of the ranges overlap
	
	for (i = 0; i < [ranges count] - 1; i++)
	{
		LPDDRange range1 = [[ranges objectAtIndex:i] ddrangeValue];
		
		NSUInteger j;
		for (j = i+1; j < [ranges count]; j++)
		{
			LPDDRange range2 = [[ranges objectAtIndex:j] ddrangeValue];
			
			LPDDRange iRange = LPDDIntersectionRange(range1, range2);
			
			if(iRange.length != 0)
			{
				return NO;
			}
		}
	}
	
	// Sort the ranges
	
	[ranges sortUsingSelector:@selector(ddrangeCompare:)];
	
	return YES;
}

- (NSString *)requestURI
{
	if(request == nil) return nil;
	
	return [[request url] relativeString];
}

/**
 * This method is called after a full LPHTTP request has been received.
 * The current request is in the LPHTTPMessage request variable.
**/
- (void)replyToHTTPRequest
{
	//LPHTTPLogTrace();
	
	
	// Check the LPHTTP version
	// We only support version 1.0 and 1.1
	
	NSString *version = [request version];
	if (![version isEqualToString:LPHTTPVersion1_1] && ![version isEqualToString:LPHTTPVersion1_0])
	{
		[self handleVersionNotSupported:version];
		return;
	}
	
	// Extract requested URI
	NSString *uri = [self requestURI];
	
	// Check for WebSocket request
//	if (0)
//	{
//		//LPHTTPLogVerbose(@"isWebSocket");
//		
//		WebSocket *ws = [self webSocketForURI:uri];
//		
//		if (ws == nil)
//		{
//			[self handleResourceNotFound];
//		}
//		else
//		{
//			[ws start];
//			
//			[[config server] addWebSocket:ws];
//			
//			// The WebSocket should now be the delegate of the underlying socket.
//			// But gracefully handle the situation if it forgot.
//			if ([asyncSocket delegate] == self)
//			{
//				//LPHTTPLogWarn(@"%@[%p]: WebSocket forgot to set itself as socket delegate", THIS_FILE, self);
//				
//				// Disconnect the socket.
//				// The socketDidDisconnect delegate method will handle everything else.
//				[asyncSocket disconnect];
//			}
//			else
//			{
//				// The WebSocket is using the socket,
//				// so make sure we don't disconnect it in the dealloc method.
//				[asyncSocket release];
//				asyncSocket = nil;
//				
//				[self die];
//				
//				// Note: There is a timing issue here that should be pointed out.
//				// 
//				// A bug that existed in previous versions happend like so:
//				// - We invoked [self die]
//				// - This caused us to get released, and our dealloc method to start executing
//				// - Meanwhile, AsyncSocket noticed a disconnect, and began to dispatch a socketDidDisconnect at us
//				// - The dealloc method finishes execution, and our instance gets freed
//				// - The socketDidDisconnect gets run, and a crash occurs
//				// 
//				// So the issue we want to avoid is releasing ourself when there is a possibility
//				// that AsyncSocket might be gearing up to queue a socketDidDisconnect for us.
//				// 
//				// In this particular situation notice that we invoke [asyncSocket delegate].
//				// This method is synchronous concerning AsyncSocket's internal socketQueue.
//				// Which means we can be sure, when it returns, that AsyncSocket has already
//				// queued any delegate methods for us if it was going to.
//				// And if the delegate methods are queued, then we've been properly retained.
//				// Meaning we won't get released / dealloc'd until the delegate method has finished executing.
//				// 
//				// In this rare situation, the die method will get invoked twice.
//			}
//		}
//		
//		return;
//	}
	
	// Check Authentication (if needed)
	// If not properly authenticated for resource, issue Unauthorized response
	if ([self isPasswordProtected:uri] && ![self isAuthenticated])
	{
		[self handleAuthenticationFailed];
		return;
	}
	
	// Extract the method
	NSString *method = [request method];
	
	// Note: We already checked to ensure the method was supported in onSocket:didReadData:withTag:
	
	// Respond properly to LPHTTP 'GET' and 'HEAD' commands
	httpResponse = [[self httpResponseForMethod:method URI:uri] retain];
	
	if (httpResponse == nil)
	{
		[self handleResourceNotFound];
		return;
	}
	
	[self sendResponseHeadersAndBody];
}

/**
 * Prepares a single-range response.
 * 
 * Note: The returned LPHTTPMessage is owned by the sender, who is responsible for releasing it.
**/
- (LPHTTPMessage *)newUniRangeResponse:(UInt64)contentLength
{
	//LPHTTPLogTrace();
	
	// Status Code 206 - Partial Content
	LPHTTPMessage *response = [[LPHTTPMessage alloc] initResponseWithStatusCode:206 description:nil version:LPHTTPVersion1_1];
	
	LPDDRange range = [[ranges objectAtIndex:0] ddrangeValue];
	
	NSString *contentLengthStr = [NSString stringWithFormat:@"%qu", range.length];
	[response setHeaderField:@"Content-Length" value:contentLengthStr];
	
	NSString *rangeStr = [NSString stringWithFormat:@"%qu-%qu", range.location, LPDDMaxRange(range) - 1];
	NSString *contentRangeStr = [NSString stringWithFormat:@"bytes %@/%qu", rangeStr, contentLength];
	[response setHeaderField:@"Content-Range" value:contentRangeStr];
	
	return response;
}

/**
 * Prepares a multi-range response.
 * 
 * Note: The returned LPHTTPMessage is owned by the sender, who is responsible for releasing it.
**/
- (LPHTTPMessage *)newMultiRangeResponse:(UInt64)contentLength
{
	//LPHTTPLogTrace();
	
	// Status Code 206 - Partial Content
	LPHTTPMessage *response = [[LPHTTPMessage alloc] initResponseWithStatusCode:206 description:nil version:LPHTTPVersion1_1];
	
	// We have to send each range using multipart/byteranges
	// So each byterange has to be prefix'd and suffix'd with the boundry
	// Example:
	// 
	// LPHTTP/1.1 206 Partial Content
	// Content-Length: 220
	// Content-Type: multipart/byteranges; boundary=4554d24e986f76dd6
	// 
	// 
	// --4554d24e986f76dd6
	// Content-Range: bytes 0-25/4025
	// 
	// [...]
	// --4554d24e986f76dd6
	// Content-Range: bytes 3975-4024/4025
	// 
	// [...]
	// --4554d24e986f76dd6--
	
	ranges_headers = [[NSMutableArray alloc] initWithCapacity:[ranges count]];
	
	CFUUIDRef theUUID = CFUUIDCreate(NULL);
	ranges_boundry = NSMakeCollectable(CFUUIDCreateString(NULL, theUUID));
	CFRelease(theUUID);
	
	NSString *startingBoundryStr = [NSString stringWithFormat:@"\r\n--%@\r\n", ranges_boundry];
	NSString *endingBoundryStr = [NSString stringWithFormat:@"\r\n--%@--\r\n", ranges_boundry];
	
	UInt64 actualContentLength = 0;
	
	NSUInteger i;
	for (i = 0; i < [ranges count]; i++)
	{
		LPDDRange range = [[ranges objectAtIndex:i] ddrangeValue];
		
		NSString *rangeStr = [NSString stringWithFormat:@"%qu-%qu", range.location, LPDDMaxRange(range) - 1];
		NSString *contentRangeVal = [NSString stringWithFormat:@"bytes %@/%qu", rangeStr, contentLength];
		NSString *contentRangeStr = [NSString stringWithFormat:@"Content-Range: %@\r\n\r\n", contentRangeVal];
		
		NSString *fullHeader = [startingBoundryStr stringByAppendingString:contentRangeStr];
		NSData *fullHeaderData = [fullHeader dataUsingEncoding:NSUTF8StringEncoding];
		
		[ranges_headers addObject:fullHeaderData];
		
		actualContentLength += [fullHeaderData length];
		actualContentLength += range.length;
	}
	
	NSData *endingBoundryData = [endingBoundryStr dataUsingEncoding:NSUTF8StringEncoding];
	
	actualContentLength += [endingBoundryData length];
	
	NSString *contentLengthStr = [NSString stringWithFormat:@"%qu", actualContentLength];
	[response setHeaderField:@"Content-Length" value:contentLengthStr];
	
	NSString *contentTypeStr = [NSString stringWithFormat:@"multipart/byteranges; boundary=%@", ranges_boundry];
	[response setHeaderField:@"Content-Type" value:contentTypeStr];
	
	return response;
}

/**
 * Returns the chunk size line that must precede each chunk of data when using chunked transfer encoding.
 * This consists of the size of the data, in hexadecimal, followed by a CRLF.
**/
- (NSData *)chunkedTransferSizeLineForLength:(NSUInteger)length
{
	return [[NSString stringWithFormat:@"%lx\r\n", (unsigned long)length] dataUsingEncoding:NSUTF8StringEncoding];
}

/**
 * Returns the data that signals the end of a chunked transfer.
**/
- (NSData *)chunkedTransferFooter
{
	// Each data chunk is preceded by a size line (in hex and including a CRLF),
	// followed by the data itself, followed by another CRLF.
	// After every data chunk has been sent, a zero size line is sent,
	// followed by optional footer (which are just more headers),
	// and followed by a CRLF on a line by itself.
	
	return [@"\r\n0\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding];
}

- (void)sendResponseHeadersAndBody
{
	if ([httpResponse respondsToSelector:@selector(delayResponeHeaders)])
	{
		if ([httpResponse delayResponeHeaders])
		{
			return;
		}
	}
	
	BOOL isChunked = NO;
	
	if ([httpResponse respondsToSelector:@selector(isChunked)])
	{
		isChunked = [httpResponse isChunked];
	}
	
	// If a response is "chunked", this simply means the LPHTTPResponse object
	// doesn't know the content-length in advance.
	
	UInt64 contentLength = 0;
	
	if (!isChunked)
	{
		contentLength = [httpResponse contentLength];
	}
	
	// Check for specific range request
	NSString *rangeHeader = [request headerField:@"Range"];
	
	BOOL isRangeRequest = NO;
	
	// If the response is "chunked" then we don't know the exact content-length.
	// This means we'll be unable to process any range requests.
	// This is because range requests might include a range like "give me the last 100 bytes"
	
	if (!isChunked && rangeHeader)
	{
		if ([self parseRangeRequest:rangeHeader withContentLength:contentLength])
		{
			isRangeRequest = YES;
		}
	}
	
	LPHTTPMessage *response;
	
	if (!isRangeRequest)
	{
		// Create response
		// Default status code: 200 - OK
		NSInteger status = 200;
		
		if ([httpResponse respondsToSelector:@selector(status)])
		{
			status = [httpResponse status];
		}
		response = [[LPHTTPMessage alloc] initResponseWithStatusCode:status description:@"OK" version:LPHTTPVersion1_1];
		
		if (isChunked)
		{
			[response setHeaderField:@"Transfer-Encoding" value:@"chunked"];
		}
		else
		{
			NSString *contentLengthStr = [NSString stringWithFormat:@"%qu", contentLength];
			[response setHeaderField:@"Content-Length" value:contentLengthStr];
		}
	}
	else
	{
		if ([ranges count] == 1)
		{
			response = [self newUniRangeResponse:contentLength];
		}
		else
		{
			response = [self newMultiRangeResponse:contentLength];
		}
	}
	
	BOOL isZeroLengthResponse = !isChunked && (contentLength == 0);
    
	// If they issue a 'HEAD' command, we don't have to include the file
	// If they issue a 'GET' command, we need to include the file
	
	if ([[request method] isEqualToString:@"HEAD"] || isZeroLengthResponse)
	{
		NSData *responseData = [self preprocessResponse:response];
		[asyncSocket writeData:responseData withTimeout:TIMEOUT_WRITE_HEAD tag:LPHTTP_RESPONSE];
		
		sentResponseHeaders = YES;
	}
	else
	{
		// Write the header response
		NSData *responseData = [self preprocessResponse:response];
		[asyncSocket writeData:responseData withTimeout:TIMEOUT_WRITE_HEAD tag:LPHTTP_PARTIAL_RESPONSE_HEADER];
		
		sentResponseHeaders = YES;
		
		// Now we need to send the body of the response
		if (!isRangeRequest)
		{
			// Regular request
			NSData *data = [httpResponse readDataOfLength:READ_CHUNKSIZE];
			
			if ([data length] > 0)
			{
				[responseDataSizes addObject:[NSNumber numberWithUnsignedInteger:[data length]]];
				
				if (isChunked)
				{
					NSData *chunkSize = [self chunkedTransferSizeLineForLength:[data length]];
					[asyncSocket writeData:chunkSize withTimeout:TIMEOUT_WRITE_HEAD tag:LPHTTP_CHUNKED_RESPONSE_HEADER];
					
					[asyncSocket writeData:data withTimeout:TIMEOUT_WRITE_BODY tag:LPHTTP_CHUNKED_RESPONSE_BODY];
					
					if ([httpResponse isDone])
					{
						NSData *footer = [self chunkedTransferFooter];
						[asyncSocket writeData:footer withTimeout:TIMEOUT_WRITE_HEAD tag:LPHTTP_RESPONSE];
					}
					else
					{
						NSData *footer = [LPGCDAsyncSocket CRLFData];
						[asyncSocket writeData:footer withTimeout:TIMEOUT_WRITE_HEAD tag:LPHTTP_CHUNKED_RESPONSE_FOOTER];
					}
				}
				else
				{
					long tag = [httpResponse isDone] ? LPHTTP_RESPONSE : LPHTTP_PARTIAL_RESPONSE_BODY;
					[asyncSocket writeData:data withTimeout:TIMEOUT_WRITE_BODY tag:tag];
				}
			}
		}
		else
		{
			// Client specified a byte range in request
			
			if ([ranges count] == 1)
			{
				// Client is requesting a single range
				LPDDRange range = [[ranges objectAtIndex:0] ddrangeValue];
				
				[httpResponse setOffset:range.location];
				
				NSUInteger bytesToRead = range.length < READ_CHUNKSIZE ? (NSUInteger)range.length : READ_CHUNKSIZE;
				
				NSData *data = [httpResponse readDataOfLength:bytesToRead];
				
				if ([data length] > 0)
				{
					[responseDataSizes addObject:[NSNumber numberWithUnsignedInteger:[data length]]];
					
					long tag = [data length] == range.length ? LPHTTP_RESPONSE : LPHTTP_PARTIAL_RANGE_RESPONSE_BODY;
					[asyncSocket writeData:data withTimeout:TIMEOUT_WRITE_BODY tag:tag];
				}
			}
			else
			{
				// Client is requesting multiple ranges
				// We have to send each range using multipart/byteranges
				
				// Write range header
				NSData *rangeHeaderData = [ranges_headers objectAtIndex:0];
				[asyncSocket writeData:rangeHeaderData withTimeout:TIMEOUT_WRITE_HEAD tag:LPHTTP_PARTIAL_RESPONSE_HEADER];
				
				// Start writing range body
				LPDDRange range = [[ranges objectAtIndex:0] ddrangeValue];
				
				[httpResponse setOffset:range.location];
				
				NSUInteger bytesToRead = range.length < READ_CHUNKSIZE ? (NSUInteger)range.length : READ_CHUNKSIZE;
				
				NSData *data = [httpResponse readDataOfLength:bytesToRead];
				
				if ([data length] > 0)
				{
					[responseDataSizes addObject:[NSNumber numberWithUnsignedInteger:[data length]]];
					
					[asyncSocket writeData:data withTimeout:TIMEOUT_WRITE_BODY tag:LPHTTP_PARTIAL_RANGES_RESPONSE_BODY];
				}
			}
		}
	}
	
	[response release];
}

/**
 * Returns the number of bytes of the http response body that are sitting in asyncSocket's write queue.
 * 
 * We keep track of this information in order to keep our memory footprint low while
 * working with asynchronous LPHTTPResponse objects.
**/
- (NSUInteger)writeQueueSize
{
	NSUInteger result = 0;
	
	NSUInteger i;
	for(i = 0; i < [responseDataSizes count]; i++)
	{
		result += [[responseDataSizes objectAtIndex:i] unsignedIntegerValue];
	}
	
	return result;
}

/**
 * Sends more data, if needed, without growing the write queue over its approximate size limit.
 * The last chunk of the response body will be sent with a tag of LPHTTP_RESPONSE.
 * 
 * This method should only be called for standard (non-range) responses.
**/
- (void)continueSendingStandardResponseBody
{
	//LPHTTPLogTrace();
	
	// This method is called when either asyncSocket has finished writing one of the response data chunks,
	// or when an asynchronous LPHTTPResponse object informs us that it has more available data for us to send.
	// In the case of the asynchronous LPHTTPResponse, we don't want to blindly grab the new data,
	// and shove it onto asyncSocket's write queue.
	// Doing so could negatively affect the memory footprint of the application.
	// Instead, we always ensure that we place no more than READ_CHUNKSIZE bytes onto the write queue.
	// 
	// Note that this does not affect the rate at which the LPHTTPResponse object may generate data.
	// The LPHTTPResponse is free to do as it pleases, and this is up to the application's developer.
	// If the memory footprint is a concern, the developer creating the custom LPHTTPResponse object may freely
	// use the calls to readDataOfLength as an indication to start generating more data.
	// This provides an easy way for the LPHTTPResponse object to throttle its data allocation in step with the rate
	// at which the socket is able to send it.
	
	NSUInteger writeQueueSize = [self writeQueueSize];
	
	if(writeQueueSize >= READ_CHUNKSIZE) return;
	
	NSUInteger available = READ_CHUNKSIZE - writeQueueSize;
	NSData *data = [httpResponse readDataOfLength:available];
	
	if ([data length] > 0)
	{
		[responseDataSizes addObject:[NSNumber numberWithUnsignedInteger:[data length]]];
		
		BOOL isChunked = NO;
		
		if ([httpResponse respondsToSelector:@selector(isChunked)])
		{
			isChunked = [httpResponse isChunked];
		}
		
		if (isChunked)
		{
			NSData *chunkSize = [self chunkedTransferSizeLineForLength:[data length]];
			[asyncSocket writeData:chunkSize withTimeout:TIMEOUT_WRITE_HEAD tag:LPHTTP_CHUNKED_RESPONSE_HEADER];
			
			[asyncSocket writeData:data withTimeout:TIMEOUT_WRITE_BODY tag:LPHTTP_CHUNKED_RESPONSE_BODY];
			
			if([httpResponse isDone])
			{
				NSData *footer = [self chunkedTransferFooter];
				[asyncSocket writeData:footer withTimeout:TIMEOUT_WRITE_HEAD tag:LPHTTP_RESPONSE];
			}
			else
			{
				NSData *footer = [LPGCDAsyncSocket CRLFData];
				[asyncSocket writeData:footer withTimeout:TIMEOUT_WRITE_HEAD tag:LPHTTP_CHUNKED_RESPONSE_FOOTER];
			}
		}
		else
		{
			long tag = [httpResponse isDone] ? LPHTTP_RESPONSE : LPHTTP_PARTIAL_RESPONSE_BODY;
			[asyncSocket writeData:data withTimeout:TIMEOUT_WRITE_BODY tag:tag];
		}
	}
}

/**
 * Sends more data, if needed, without growing the write queue over its approximate size limit.
 * The last chunk of the response body will be sent with a tag of LPHTTP_RESPONSE.
 * 
 * This method should only be called for single-range responses.
**/
- (void)continueSendingSingleRangeResponseBody
{
	//LPHTTPLogTrace();
	
	// This method is called when either asyncSocket has finished writing one of the response data chunks,
	// or when an asynchronous response informs us that is has more available data for us to send.
	// In the case of the asynchronous response, we don't want to blindly grab the new data,
	// and shove it onto asyncSocket's write queue.
	// Doing so could negatively affect the memory footprint of the application.
	// Instead, we always ensure that we place no more than READ_CHUNKSIZE bytes onto the write queue.
	// 
	// Note that this does not affect the rate at which the LPHTTPResponse object may generate data.
	// The LPHTTPResponse is free to do as it pleases, and this is up to the application's developer.
	// If the memory footprint is a concern, the developer creating the custom LPHTTPResponse object may freely
	// use the calls to readDataOfLength as an indication to start generating more data.
	// This provides an easy way for the LPHTTPResponse object to throttle its data allocation in step with the rate
	// at which the socket is able to send it.
	
	NSUInteger writeQueueSize = [self writeQueueSize];
	
	if(writeQueueSize >= READ_CHUNKSIZE) return;
	
	LPDDRange range = [[ranges objectAtIndex:0] ddrangeValue];
	
	UInt64 offset = [httpResponse offset];
	UInt64 bytesRead = offset - range.location;
	UInt64 bytesLeft = range.length - bytesRead;
	
	if (bytesLeft > 0)
	{
		NSUInteger available = READ_CHUNKSIZE - writeQueueSize;
		NSUInteger bytesToRead = bytesLeft < available ? (NSUInteger)bytesLeft : available;
		
		NSData *data = [httpResponse readDataOfLength:bytesToRead];
		
		if ([data length] > 0)
		{
			[responseDataSizes addObject:[NSNumber numberWithUnsignedInteger:[data length]]];
			
			long tag = [data length] == bytesLeft ? LPHTTP_RESPONSE : LPHTTP_PARTIAL_RANGE_RESPONSE_BODY;
			[asyncSocket writeData:data withTimeout:TIMEOUT_WRITE_BODY tag:tag];
		}
	}
}

/**
 * Sends more data, if needed, without growing the write queue over its approximate size limit.
 * The last chunk of the response body will be sent with a tag of LPHTTP_RESPONSE.
 * 
 * This method should only be called for multi-range responses.
**/
- (void)continueSendingMultiRangeResponseBody
{
	//LPHTTPLogTrace();
	
	// This method is called when either asyncSocket has finished writing one of the response data chunks,
	// or when an asynchronous LPHTTPResponse object informs us that is has more available data for us to send.
	// In the case of the asynchronous LPHTTPResponse, we don't want to blindly grab the new data,
	// and shove it onto asyncSocket's write queue.
	// Doing so could negatively affect the memory footprint of the application.
	// Instead, we always ensure that we place no more than READ_CHUNKSIZE bytes onto the write queue.
	// 
	// Note that this does not affect the rate at which the LPHTTPResponse object may generate data.
	// The LPHTTPResponse is free to do as it pleases, and this is up to the application's developer.
	// If the memory footprint is a concern, the developer creating the custom LPHTTPResponse object may freely
	// use the calls to readDataOfLength as an indication to start generating more data.
	// This provides an easy way for the LPHTTPResponse object to throttle its data allocation in step with the rate
	// at which the socket is able to send it.
	
	NSUInteger writeQueueSize = [self writeQueueSize];
	
	if(writeQueueSize >= READ_CHUNKSIZE) return;
	
	LPDDRange range = [[ranges objectAtIndex:rangeIndex] ddrangeValue];
	
	UInt64 offset = [httpResponse offset];
	UInt64 bytesRead = offset - range.location;
	UInt64 bytesLeft = range.length - bytesRead;
	
	if (bytesLeft > 0)
	{
		NSUInteger available = READ_CHUNKSIZE - writeQueueSize;
		NSUInteger bytesToRead = bytesLeft < available ? (NSUInteger)bytesLeft : available;
		
		NSData *data = [httpResponse readDataOfLength:bytesToRead];
		
		if ([data length] > 0)
		{
			[responseDataSizes addObject:[NSNumber numberWithUnsignedInteger:[data length]]];
			
			[asyncSocket writeData:data withTimeout:TIMEOUT_WRITE_BODY tag:LPHTTP_PARTIAL_RANGES_RESPONSE_BODY];
		}
	}
	else
	{
		if (++rangeIndex < [ranges count])
		{
			// Write range header
			NSData *rangeHeader = [ranges_headers objectAtIndex:rangeIndex];
			[asyncSocket writeData:rangeHeader withTimeout:TIMEOUT_WRITE_HEAD tag:LPHTTP_PARTIAL_RESPONSE_HEADER];
			
			// Start writing range body
			range = [[ranges objectAtIndex:rangeIndex] ddrangeValue];
			
			[httpResponse setOffset:range.location];
			
			NSUInteger available = READ_CHUNKSIZE - writeQueueSize;
			NSUInteger bytesToRead = range.length < available ? (NSUInteger)range.length : available;
			
			NSData *data = [httpResponse readDataOfLength:bytesToRead];
			
			if ([data length] > 0)
			{
				[responseDataSizes addObject:[NSNumber numberWithUnsignedInteger:[data length]]];
				
				[asyncSocket writeData:data withTimeout:TIMEOUT_WRITE_BODY tag:LPHTTP_PARTIAL_RANGES_RESPONSE_BODY];
			}
		}
		else
		{
			// We're not done yet - we still have to send the closing boundry tag
			NSString *endingBoundryStr = [NSString stringWithFormat:@"\r\n--%@--\r\n", ranges_boundry];
			NSData *endingBoundryData = [endingBoundryStr dataUsingEncoding:NSUTF8StringEncoding];
			
			[asyncSocket writeData:endingBoundryData withTimeout:TIMEOUT_WRITE_HEAD tag:LPHTTP_RESPONSE];
		}
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Responses
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Returns an array of possible index pages.
 * For example: {"index.html", "index.htm"}
**/
- (NSArray *)directoryIndexFileNames
{
	//LPHTTPLogTrace();
	
	// Override me to support other index pages.
	
	return [NSArray arrayWithObjects:@"index.html", @"index.htm", nil];
}

- (NSString *)filePathForURI:(NSString *)path
{
	return [self filePathForURI:path allowDirectory:NO];
}

/**
 * Converts relative URI path into full file-system path.
**/
- (NSString *)filePathForURI:(NSString *)path allowDirectory:(BOOL)allowDirectory
{
	//LPHTTPLogTrace();
	
	// Override me to perform custom path mapping.
	// For example you may want to use a default file other than index.html, or perhaps support multiple types.
	
	NSString *documentRoot = [config documentRoot];
	
	// Part 0: Validate document root setting.
	// 
	// If there is no configured documentRoot,
	// then it makes no sense to try to return anything.
	
	if (documentRoot == nil)
	{
		//LPHTTPLogWarn(@"%@[%p]: No configured document root", THIS_FILE, self);
		return nil;
	}
	
	// Part 1: Strip parameters from the url
	// 
	// E.g.: /page.html?q=22&var=abc -> /page.html
	
	NSURL *docRoot = [NSURL fileURLWithPath:documentRoot isDirectory:YES];
	if (docRoot == nil)
	{
		//LPHTTPLogWarn(@"%@[%p]: Document root is invalid file path", THIS_FILE, self);
		return nil;
	}
	
	NSString *relativePath = [[NSURL URLWithString:path relativeToURL:docRoot] relativePath];
	
	// Part 2: Append relative path to document root (base path)
	// 
	// E.g.: relativePath="/images/icon.png"
	//       documentRoot="/Users/robbie/Sites"
	//           fullPath="/Users/robbie/Sites/images/icon.png"
	// 
	// We also standardize the path.
	// 
	// E.g.: "Users/robbie/Sites/images/../index.html" -> "/Users/robbie/Sites/index.html"
	
	NSString *fullPath = [[documentRoot stringByAppendingPathComponent:relativePath] stringByStandardizingPath];
	
	if ([relativePath isEqualToString:@"/"])
	{
		fullPath = [fullPath stringByAppendingString:@"/"];
	}
	
	// Part 3: Prevent serving files outside the document root.
	// 
	// Sneaky requests may include ".." in the path.
	// 
	// E.g.: relativePath="../Documents/TopSecret.doc"
	//       documentRoot="/Users/robbie/Sites"
	//           fullPath="/Users/robbie/Documents/TopSecret.doc"
	// 
	// E.g.: relativePath="../Sites_Secret/TopSecret.doc"
	//       documentRoot="/Users/robbie/Sites"
	//           fullPath="/Users/robbie/Sites_Secret/TopSecret"
	
	if (![documentRoot hasSuffix:@"/"])
	{
		documentRoot = [documentRoot stringByAppendingString:@"/"];
	}
	
	if (![fullPath hasPrefix:documentRoot])
	{
		//LPHTTPLogWarn(@"%@[%p]: Request for file outside document root", THIS_FILE, self);
		return nil;
	}
	
	// Part 4: Search for index page if path is pointing to a directory
	if (!allowDirectory)
	{
		BOOL isDir = NO;
		if ([[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:&isDir] && isDir)
		{
			NSArray *indexFileNames = [self directoryIndexFileNames];

			for (NSString *indexFileName in indexFileNames)
			{
				NSString *indexFilePath = [fullPath stringByAppendingPathComponent:indexFileName];

				if ([[NSFileManager defaultManager] fileExistsAtPath:indexFilePath isDirectory:&isDir] && !isDir)
				{
					return indexFilePath;
				}
			}

			// No matching index files found in directory
			return nil;
		}
	}

	return fullPath;
}

/**
 * This method is called to get a response for a request.
 * You may return any object that adopts the LPHTTPResponse protocol.
 * The LPHTTPServer comes with two such classes: LPHTTPFileResponse and LPHTTPDataResponse.
 * LPHTTPFileResponse is a wrapper for an NSFileHandle object, and is the preferred way to send a file response.
 * LPHTTPDataResponse is a wrapper for an NSData object, and may be used to send a custom response.
**/
- (NSObject<LPHTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path
{
	//LPHTTPLogTrace();
	
	// Override me to provide custom responses.
	
	NSString *filePath = [self filePathForURI:path allowDirectory:NO];
	
	BOOL isDir = NO;
	
	if (filePath && [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDir] && !isDir)
	{
		return [[[LPHTTPFileResponse alloc] initWithFilePath:filePath forConnection:self] autorelease];
	
		// Use me instead for asynchronous file IO.
		// Generally better for larger files.
		
	//	return [[[LPHTTPAsyncFileResponse alloc] initWithFilePath:filePath forConnection:self] autorelease];
	}
	
	return nil;
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Uploads
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * This method is called after receiving all LPHTTP headers, but before reading any of the request body.
**/
- (void)prepareForBodyWithSize:(UInt64)contentLength
{
	// Override me to allocate buffers, file handles, etc.
}

/**
 * This method is called to handle data read from a POST / PUT.
 * The given data is part of the request body.
**/
- (void)processBodyData:(NSData *)postDataChunk
{
	// Override me to do something useful with a POST / PUT.
	// If the post is small, such as a simple form, you may want to simply append the data to the request.
	// If the post is big, such as a file upload, you may want to store the file to disk.
	// 
	// Remember: In order to support LARGE POST uploads, the data is read in chunks.
	// This prevents a 50 MB upload from being stored in RAM.
	// The size of the chunks are limited by the POST_CHUNKSIZE definition.
	// Therefore, this method may be called multiple times for the same POST request.
}

/**
 * This method is called after the request body has been fully read but before the LPHTTP request is processed.
**/
- (void)finishBody
{
	// Override me to perform any final operations on an upload.
	// For example, if you were saving the upload to disk this would be
	// the hook to flush any pending data to disk and maybe close the file.
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Errors
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Called if the HTML version is other than what is supported
**/
- (void)handleVersionNotSupported:(NSString *)version
{
	// Override me for custom error handling of unsupported http version responses
	// If you simply want to add a few extra header fields, see the preprocessErrorResponse: method.
	// You can also use preprocessErrorResponse: to add an optional HTML body.
	
	//LPHTTPLogWarn(@"LPHTTP Server: Error 505 - Version Not Supported: %@ (%@)", version, [self requestURI]);
	
	LPHTTPMessage *response = [[LPHTTPMessage alloc] initResponseWithStatusCode:505 description:nil version:LPHTTPVersion1_1];
	[response setHeaderField:@"Content-Length" value:@"0"];
    
	NSData *responseData = [self preprocessErrorResponse:response];
	[asyncSocket writeData:responseData withTimeout:TIMEOUT_WRITE_ERROR tag:LPHTTP_RESPONSE];
	
	[response release];
}

/**
 * Called if the authentication information was required and absent, or if authentication failed.
**/
- (void)handleAuthenticationFailed
{
	// Override me for custom handling of authentication challenges
	// If you simply want to add a few extra header fields, see the preprocessErrorResponse: method.
	// You can also use preprocessErrorResponse: to add an optional HTML body.
	
	//LPHTTPLogInfo(@"LPHTTP Server: Error 401 - Unauthorized (%@)", [self requestURI]);
		
	// Status Code 401 - Unauthorized
	LPHTTPMessage *response = [[LPHTTPMessage alloc] initResponseWithStatusCode:401 description:nil version:LPHTTPVersion1_1];
	[response setHeaderField:@"Content-Length" value:@"0"];
	
	if ([self useDigestAccessAuthentication])
	{
		[self addDigestAuthChallenge:response];
	}
	else
	{
		[self addBasicAuthChallenge:response];
	}
	
	NSData *responseData = [self preprocessErrorResponse:response];
	[asyncSocket writeData:responseData withTimeout:TIMEOUT_WRITE_ERROR tag:LPHTTP_RESPONSE];
	
	[response release];
}

/**
 * Called if we receive some sort of malformed LPHTTP request.
 * The data parameter is the invalid LPHTTP header line, including CRLF, as read from LPGCDAsyncSocket.
 * The data parameter may also be nil if the request as a whole was invalid, such as a POST with no Content-Length.
**/
- (void)handleInvalidRequest:(NSData *)data
{
	// Override me for custom error handling of invalid LPHTTP requests
	// If you simply want to add a few extra header fields, see the preprocessErrorResponse: method.
	// You can also use preprocessErrorResponse: to add an optional HTML body.
	
	//LPHTTPLogWarn(@"LPHTTP Server: Error 400 - Bad Request (%@)", [self requestURI]);
	
	// Status Code 400 - Bad Request
	LPHTTPMessage *response = [[LPHTTPMessage alloc] initResponseWithStatusCode:400 description:nil version:LPHTTPVersion1_1];
	[response setHeaderField:@"Content-Length" value:@"0"];
	[response setHeaderField:@"Connection" value:@"close"];
	
	NSData *responseData = [self preprocessErrorResponse:response];
	[asyncSocket writeData:responseData withTimeout:TIMEOUT_WRITE_ERROR tag:LPHTTP_FINAL_RESPONSE];
	
	[response release];
	
	// Note: We used the LPHTTP_FINAL_RESPONSE tag to disconnect after the response is sent.
	// We do this because we couldn't parse the request,
	// so we won't be able to recover and move on to another request afterwards.
	// In other words, we wouldn't know where the first request ends and the second request begins.
}

/**
 * Called if we receive a LPHTTP request with a method other than GET or HEAD.
**/
- (void)handleUnknownMethod:(NSString *)method
{
	// Override me for custom error handling of 405 method not allowed responses.
	// If you simply want to add a few extra header fields, see the preprocessErrorResponse: method.
	// You can also use preprocessErrorResponse: to add an optional HTML body.
	// 
	// See also: supportsMethod:atPath:
	
	//LPHTTPLogWarn(@"LPHTTP Server: Error 405 - Method Not Allowed: %@ (%@)", method, [self requestURI]);
	
	// Status code 405 - Method Not Allowed
	LPHTTPMessage *response = [[LPHTTPMessage alloc] initResponseWithStatusCode:405 description:nil version:LPHTTPVersion1_1];
	[response setHeaderField:@"Content-Length" value:@"0"];
	[response setHeaderField:@"Connection" value:@"close"];
	
	NSData *responseData = [self preprocessErrorResponse:response];
	[asyncSocket writeData:responseData withTimeout:TIMEOUT_WRITE_ERROR tag:LPHTTP_FINAL_RESPONSE];
    
	[response release];
	
	// Note: We used the LPHTTP_FINAL_RESPONSE tag to disconnect after the response is sent.
	// We do this because the method may include an http body.
	// Since we can't be sure, we should close the connection.
}

/**
 * Called if we're unable to find the requested resource.
**/
- (void)handleResourceNotFound
{
	// Override me for custom error handling of 404 not found responses
	// If you simply want to add a few extra header fields, see the preprocessErrorResponse: method.
	// You can also use preprocessErrorResponse: to add an optional HTML body.
	
	//LPHTTPLogInfo(@"LPHTTP Server: Error 404 - Not Found (%@)", [self requestURI]);
	
	// Status Code 404 - Not Found
	LPHTTPMessage *response = [[LPHTTPMessage alloc] initResponseWithStatusCode:404 description:nil version:LPHTTPVersion1_1];
	[response setHeaderField:@"Content-Length" value:@"0"];
	
	NSData *responseData = [self preprocessErrorResponse:response];
	[asyncSocket writeData:responseData withTimeout:TIMEOUT_WRITE_ERROR tag:LPHTTP_RESPONSE];
	
	[response release];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Headers
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Gets the current date and time, formatted properly (according to RFC) for insertion into an LPHTTP header.
**/
- (NSString *)dateAsString:(NSDate *)date
{
	// From Apple's Documentation (Data Formatting Guide -> Date Formatters -> Cache Formatters for Efficiency):
	// 
	// "Creating a date formatter is not a cheap operation. If you are likely to use a formatter frequently,
	// it is typically more efficient to cache a single instance than to create and dispose of multiple instances.
	// One approach is to use a static variable."
	// 
	// This was discovered to be true in massive form via issue #46:
	// 
	// "Was doing some performance benchmarking using instruments and httperf. Using this single optimization
	// I got a 26% speed improvement - from 1000req/sec to 3800req/sec. Not insignificant.
	// The culprit? Why, NSDateFormatter, of course!"
	// 
	// Thus, we are using a static NSDateFormatter here.
	
	static NSDateFormatter *df;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		
		// Example: Sun, 06 Nov 1994 08:49:37 GMT
		
		df = [[NSDateFormatter alloc] init];
		[df setFormatterBehavior:NSDateFormatterBehavior10_4];
		[df setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
		[df setDateFormat:@"EEE, dd MMM y HH:mm:ss 'GMT'"];
		[df setLocale:[[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"] autorelease]];
		
		// For some reason, using zzz in the format string produces GMT+00:00
	});
	
	return [df stringFromDate:date];
}

/**
 * This method is called immediately prior to sending the response headers.
 * This method adds standard header fields, and then converts the response to an NSData object.
**/
- (NSData *)preprocessResponse:(LPHTTPMessage *)response
{
	//LPHTTPLogTrace();
	
	// Override me to customize the response headers
	// You'll likely want to add your own custom headers, and then return [super preprocessResponse:response]
	
	// Add standard headers
	NSString *now = [self dateAsString:[NSDate date]];
	[response setHeaderField:@"Date" value:now];
	
	// Add server capability headers
	[response setHeaderField:@"Accept-Ranges" value:@"bytes"];
	
	// Add optional response headers
	if ([httpResponse respondsToSelector:@selector(httpHeaders)])
	{
		NSDictionary *responseHeaders = [httpResponse httpHeaders];
		
		NSEnumerator *keyEnumerator = [responseHeaders keyEnumerator];
		NSString *key;
		
		while ((key = [keyEnumerator nextObject]))
		{
			NSString *value = [responseHeaders objectForKey:key];
			
			[response setHeaderField:key value:value];
		}
	}
	
	return [response messageData];
}

/**
 * This method is called immediately prior to sending the response headers (for an error).
 * This method adds standard header fields, and then converts the response to an NSData object.
**/
- (NSData *)preprocessErrorResponse:(LPHTTPMessage *)response;
{
	//LPHTTPLogTrace();
	
	// Override me to customize the error response headers
	// You'll likely want to add your own custom headers, and then return [super preprocessErrorResponse:response]
	// 
	// Notes:
	// You can use [response statusCode] to get the type of error.
	// You can use [response setBody:data] to add an optional HTML body.
	// If you add a body, don't forget to update the Content-Length.
	// 
	// if ([response statusCode] == 404)
	// {
	//     NSString *msg = @"<html><body>Error 404 - Not Found</body></html>";
	//     NSData *msgData = [msg dataUsingEncoding:NSUTF8StringEncoding];
	//     
	//     [response setBody:msgData];
	//     
	//     NSString *contentLengthStr = [NSString stringWithFormat:@"%lu", (unsigned long)[msgData length]];
	//     [response setHeaderField:@"Content-Length" value:contentLengthStr];
	// }
	
	// Add standard headers
	NSString *now = [self dateAsString:[NSDate date]];
	[response setHeaderField:@"Date" value:now];
	
	// Add server capability headers
	[response setHeaderField:@"Accept-Ranges" value:@"bytes"];
	
	// Add optional response headers
	if ([httpResponse respondsToSelector:@selector(httpHeaders)])
	{
		NSDictionary *responseHeaders = [httpResponse httpHeaders];
		
		NSEnumerator *keyEnumerator = [responseHeaders keyEnumerator];
		NSString *key;
		
		while((key = [keyEnumerator nextObject]))
		{
			NSString *value = [responseHeaders objectForKey:key];
			
			[response setHeaderField:key value:value];
		}
	}
	
	return [response messageData];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark LPGCDAsyncSocket Delegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * This method is called after the socket has successfully read data from the stream.
 * Remember that this method will only be called after the socket reaches a CRLF, or after it's read the proper length.
**/
- (void)socket:(LPGCDAsyncSocket *)sock didReadData:(NSData*)data withTag:(long)tag
{
	if (tag == LPHTTP_REQUEST_HEADER)
	{
		// Append the header line to the http message
		BOOL result = [request appendData:data];
		if (!result)
		{
			//LPHTTPLogWarn(@"%@[%p]: Malformed request", THIS_FILE, self);
			
			[self handleInvalidRequest:data];
		}
		else if (![request isHeaderComplete])
		{
			// We don't have a complete header yet
			// That is, we haven't yet received a CRLF on a line by itself, indicating the end of the header
			if (++numHeaderLines > MAX_HEADER_LINES)
			{
				// Reached the maximum amount of header lines in a single LPHTTP request
				// This could be an attempted DOS attack
				[asyncSocket disconnect];
				
				// Explictly return to ensure we don't do anything after the socket disconnect
				return;
			}
			else
			{
				[asyncSocket readDataToData:[LPGCDAsyncSocket CRLFData]
				                withTimeout:TIMEOUT_READ_SUBSEQUENT_HEADER_LINE
				                  maxLength:MAX_HEADER_LINE_LENGTH
				                        tag:LPHTTP_REQUEST_HEADER];
			}
		}
		else
		{
			// We have an entire LPHTTP request header from the client
			
			// Extract the method (such as GET, HEAD, POST, etc)
			NSString *method = [request method];
			
			// Extract the uri (such as "/index.html")
			NSString *uri = [self requestURI];
			
			// Check for a Transfer-Encoding field
			NSString *transferEncoding = [request headerField:@"Transfer-Encoding"];
      
			// Check for a Content-Length field
			NSString *contentLength = [request headerField:@"Content-Length"];
			
			// Content-Length MUST be present for upload methods (such as POST or PUT)
			// and MUST NOT be present for other methods.
			BOOL expectsUpload = [self expectsRequestBodyFromMethod:method atPath:uri];
			
			if (expectsUpload)
			{
				if (transferEncoding && ![transferEncoding caseInsensitiveCompare:@"Chunked"])
				{
					requestContentLength = -1;
				}
				else
				{
					if (contentLength == nil)
					{
						//LPHTTPLogWarn(@"%@[%p]: Method expects request body, but had no specified Content-Length",
	//								THIS_FILE, self);
						
						[self handleInvalidRequest:nil];
						return;
					}
					
					if (![NSNumber parseString:(NSString *)contentLength intoUInt64:&requestContentLength])
					{
						//LPHTTPLogWarn(@"%@[%p]: Unable to parse Content-Length header into a valid number",
//									THIS_FILE, self);
						
						[self handleInvalidRequest:nil];
						return;
					}
				}
			}
			else
			{
				if (contentLength != nil)
				{
					// Received Content-Length header for method not expecting an upload.
					// This better be zero...
					
					if (![NSNumber parseString:(NSString *)contentLength intoUInt64:&requestContentLength])
					{
						//LPHTTPLogWarn(@"%@[%p]: Unable to parse Content-Length header into a valid number",
//									THIS_FILE, self);
						
						[self handleInvalidRequest:nil];
						return;
					}
					
					if (requestContentLength > 0)
					{
						//LPHTTPLogWarn(@"%@[%p]: Method not expecting request body had non-zero Content-Length",
//									THIS_FILE, self);
						
						[self handleInvalidRequest:nil];
						return;
					}
				}
				
				requestContentLength = 0;
				requestContentLengthReceived = 0;
			}
			
			// Check to make sure the given method is supported
			if (![self supportsMethod:method atPath:uri])
			{
				// The method is unsupported - either in general, or for this specific request
				// Send a 405 - Method not allowed response
				[self handleUnknownMethod:method];
				return;
			}
			
			if (expectsUpload)
			{
				// Reset the total amount of data received for the upload
				requestContentLengthReceived = 0;
				
				// Prepare for the upload
				[self prepareForBodyWithSize:requestContentLength];
				
				if (requestContentLength > 0)
				{
					// Start reading the request body
					if (requestContentLength == -1)
					{
						// Chunked transfer
						
						[asyncSocket readDataToData:[LPGCDAsyncSocket CRLFData]
						                withTimeout:TIMEOUT_READ_BODY
						                  maxLength:MAX_CHUNK_LINE_LENGTH
						                        tag:LPHTTP_REQUEST_CHUNK_SIZE];
					}
					else
					{
						NSUInteger bytesToRead;
						if (requestContentLength < POST_CHUNKSIZE)
							bytesToRead = (NSUInteger)requestContentLength;
						else
							bytesToRead = POST_CHUNKSIZE;
						
						[asyncSocket readDataToLength:bytesToRead
						                  withTimeout:TIMEOUT_READ_BODY
						                          tag:LPHTTP_REQUEST_BODY];
					}
				}
				else
				{
					// Empty upload
					[self finishBody];
					[self replyToHTTPRequest];
				}
			}
			else
			{
				// Now we need to reply to the request
				[self replyToHTTPRequest];
			}
		}
	}
	else
	{
		BOOL doneReadingRequest = NO;
		
		// A chunked message body contains a series of chunks,
		// followed by a line with "0" (zero),
		// followed by optional footers (just like headers),
		// and a blank line.
		// 
		// Each chunk consists of two parts:
		// 
		// 1. A line with the size of the chunk data, in hex,
		//    possibly followed by a semicolon and extra parameters you can ignore (none are currently standard),
		//    and ending with CRLF.
		// 2. The data itself, followed by CRLF.
		// 
		// Part 1 is represented by LPHTTP_REQUEST_CHUNK_SIZE
		// Part 2 is represented by LPHTTP_REQUEST_CHUNK_DATA and LPHTTP_REQUEST_CHUNK_TRAILER
		// where the trailer is the CRLF that follows the data.
		// 
		// The optional footers and blank line are represented by LPHTTP_REQUEST_CHUNK_FOOTER.
		
		if (tag == LPHTTP_REQUEST_CHUNK_SIZE)
		{
			// We have just read in a line with the size of the chunk data, in hex, 
			// possibly followed by a semicolon and extra parameters that can be ignored,
			// and ending with CRLF.
			
			NSString *sizeLine = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
			
			requestChunkSize = (UInt64)strtoull([sizeLine UTF8String], NULL, 16);
			requestChunkSizeReceived = 0;
			
			if (errno != 0)
			{
				//LPHTTPLogWarn(@"%@[%p]: Method expects chunk size, but received something else", THIS_FILE, self);
				
				[self handleInvalidRequest:nil];
				return;
			}
			
			if (requestChunkSize > 0)
			{
				NSUInteger bytesToRead;
				bytesToRead = (requestChunkSize < POST_CHUNKSIZE) ? (NSUInteger)requestChunkSize : POST_CHUNKSIZE;
				
				[asyncSocket readDataToLength:bytesToRead
				                  withTimeout:TIMEOUT_READ_BODY
				                          tag:LPHTTP_REQUEST_CHUNK_DATA];
			}
			else
			{
				// This is the "0" (zero) line,
				// which is to be followed by optional footers (just like headers) and finally a blank line.
				
				[asyncSocket readDataToData:[LPGCDAsyncSocket CRLFData]
				                withTimeout:TIMEOUT_READ_BODY
				                  maxLength:MAX_HEADER_LINE_LENGTH
				                        tag:LPHTTP_REQUEST_CHUNK_FOOTER];
			}
			
			return;
		}
		else if (tag == LPHTTP_REQUEST_CHUNK_DATA)
		{
			// We just read part of the actual data.
			
			requestContentLengthReceived += [data length];
			requestChunkSizeReceived += [data length];
			
			[self processBodyData:data];
			
			UInt64 bytesLeft = requestChunkSize - requestChunkSizeReceived;
			if (bytesLeft > 0)
			{
				NSUInteger bytesToRead = (bytesLeft < POST_CHUNKSIZE) ? (NSUInteger)bytesLeft : POST_CHUNKSIZE;
				
				[asyncSocket readDataToLength:bytesToRead
				                  withTimeout:TIMEOUT_READ_BODY
				                          tag:LPHTTP_REQUEST_CHUNK_DATA];
			}
			else
			{
				// We've read in all the data for this chunk.
				// The data is followed by a CRLF, which we need to read (and basically ignore)
				
				[asyncSocket readDataToLength:2
				                  withTimeout:TIMEOUT_READ_BODY
				                          tag:LPHTTP_REQUEST_CHUNK_TRAILER];
			}
			
			return;
		}
		else if (tag == LPHTTP_REQUEST_CHUNK_TRAILER)
		{
			// This should be the CRLF following the data.
			// Just ensure it's a CRLF.
			
			if (![data isEqualToData:[LPGCDAsyncSocket CRLFData]])
			{
				//LPHTTPLogWarn(@"%@[%p]: Method expects chunk trailer, but is missing", THIS_FILE, self);
				
				[self handleInvalidRequest:nil];
				return;
			}
			
			// Now continue with the next chunk
			
			[asyncSocket readDataToData:[LPGCDAsyncSocket CRLFData]
			                withTimeout:TIMEOUT_READ_BODY
			                  maxLength:MAX_CHUNK_LINE_LENGTH
			                        tag:LPHTTP_REQUEST_CHUNK_SIZE];
			
		}
		else if (tag == LPHTTP_REQUEST_CHUNK_FOOTER)
		{
			if (++numHeaderLines > MAX_HEADER_LINES)
			{
				// Reached the maximum amount of header lines in a single LPHTTP request
				// This could be an attempted DOS attack
				[asyncSocket disconnect];
				
				// Explictly return to ensure we don't do anything after the socket disconnect
				return;
			}
			
			if ([data length] > 2)
			{
				// We read in a footer.
				// In the future we may want to append these to the request.
				// For now we ignore, and continue reading the footers, waiting for the final blank line.
				
				[asyncSocket readDataToData:[LPGCDAsyncSocket CRLFData]
				                withTimeout:TIMEOUT_READ_BODY
				                  maxLength:MAX_HEADER_LINE_LENGTH
				                        tag:LPHTTP_REQUEST_CHUNK_FOOTER];
			}
			else
			{
				doneReadingRequest = YES;
			}
		}
		else  // LPHTTP_REQUEST_BODY
		{
			// Handle a chunk of data from the POST body
			
			requestContentLengthReceived += [data length];
			[self processBodyData:data];
			
			if (requestContentLengthReceived < requestContentLength)
			{
				// We're not done reading the post body yet...
				
				UInt64 bytesLeft = requestContentLength - requestContentLengthReceived;
				
				NSUInteger bytesToRead = bytesLeft < POST_CHUNKSIZE ? (NSUInteger)bytesLeft : POST_CHUNKSIZE;
				
				[asyncSocket readDataToLength:bytesToRead
				                  withTimeout:TIMEOUT_READ_BODY
				                          tag:LPHTTP_REQUEST_BODY];
			}
			else
			{
				doneReadingRequest = YES;
			}
		}
		
		// Now that the entire body has been received, we need to reply to the request
		
		if (doneReadingRequest)
		{
			[self finishBody];
			[self replyToHTTPRequest];
		}
	}
}

/**
 * This method is called after the socket has successfully written data to the stream.
**/
- (void)socket:(LPGCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
	BOOL doneSendingResponse = NO;
	
	if (tag == LPHTTP_PARTIAL_RESPONSE_BODY)
	{
    // Update the amount of data we have in asyncSocket's write queue
    if ([responseDataSizes count] > 0)
    {
      [responseDataSizes removeObjectAtIndex:0];
    }
		// We only wrote a part of the response - there may be more
		[self continueSendingStandardResponseBody];
	}
	else if (tag == LPHTTP_CHUNKED_RESPONSE_BODY)
	{
		// Update the amount of data we have in asyncSocket's write queue.
    if ([responseDataSizes count] > 0)
    {
      [responseDataSizes removeObjectAtIndex:0];
    }
		
		// Don't continue sending the response yet.
		// The chunked footer that was sent after the body will tell us if we have more data to send.
	}
	else if (tag == LPHTTP_CHUNKED_RESPONSE_FOOTER)
	{
		// Normal chunked footer indicating we have more data to send (non final footer).
		[self continueSendingStandardResponseBody];
	}
	else if (tag == LPHTTP_PARTIAL_RANGE_RESPONSE_BODY)
	{
    // Update the amount of data we have in asyncSocket's write queue.
    if ([responseDataSizes count] > 0)
    {
      [responseDataSizes removeObjectAtIndex:0];
    }
		
		// We only wrote a part of the range - there may be more
		[self continueSendingSingleRangeResponseBody];
	}
	else if (tag == LPHTTP_PARTIAL_RANGES_RESPONSE_BODY)
	{
    // Update the amount of data we have in asyncSocket's write queue.
    if ([responseDataSizes count] > 0)
    {
      [responseDataSizes removeObjectAtIndex:0];
    }
		
		// We only wrote part of the range - there may be more, or there may be more ranges
		[self continueSendingMultiRangeResponseBody];
	}
	else if (tag == LPHTTP_RESPONSE || tag == LPHTTP_FINAL_RESPONSE)
	{
		// Update the amount of data we have in asyncSocket's write queue
		if ([responseDataSizes count] > 0)
		{
			[responseDataSizes removeObjectAtIndex:0];
		}
		
		doneSendingResponse = YES;
	}
	
	if (doneSendingResponse)
	{
		// Inform the http response that we're done
		if ([httpResponse respondsToSelector:@selector(connectionDidClose)])
		{
			[httpResponse connectionDidClose];
		}
		
		// Cleanup after the last request
		[self finishResponse];
		
		
		if (tag == LPHTTP_FINAL_RESPONSE)
		{
			// Terminate the connection
			[asyncSocket disconnect];
			
			// Explictly return to ensure we don't do anything after the socket disconnect
			return;
		}
		else
		{
			if ([self shouldDie])
			{
				// The only time we should invoke [self die] is from socketDidDisconnect,
				// or if the socket gets taken over by someone else like a WebSocket.
				
				[asyncSocket disconnect];
			}
			else
			{
				// Prepare for the next request
				
				// If this assertion fails, it likely means you overrode the
				// finishBody method and forgot to call [super finishBody].
				NSAssert(request == nil, @"Request not properly released in finishBody");
				
				request = [[LPHTTPMessage alloc] initEmptyRequest];
				
				numHeaderLines = 0;
				sentResponseHeaders = NO;
				
				// And start listening for more requests
				[self startReadingRequest];
			}
		}
	}
}

/**
 * Sent after the socket has been disconnected.
**/
- (void)socketDidDisconnect:(LPGCDAsyncSocket *)sock withError:(NSError *)err;
{
	//LPHTTPLogTrace();
	
	[asyncSocket release];
	asyncSocket = nil;
	
	[self die];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark LPHTTPResponse Notifications
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * This method may be called by asynchronous LPHTTPResponse objects.
 * That is, LPHTTPResponse objects that return YES in their "- (BOOL)isAsynchronous" method.
 * 
 * This informs us that the response object has generated more data that we may be able to send.
**/
- (void)responseHasAvailableData:(NSObject<LPHTTPResponse> *)sender
{
	//LPHTTPLogTrace();
	
	// We always dispatch this asynchronously onto our connectionQueue,
	// even if the connectionQueue is the current queue.
	// 
	// We do this to give the LPHTTPResponse classes the flexibility to call
	// this method whenever they want, even from within a readDataOfLength method.
	
	dispatch_async(connectionQueue, ^{
		
		if (sender != httpResponse)
		{
			//LPHTTPLogWarn(@"%@[%p]: %@ - Sender is not current httpResponse", THIS_FILE, self, THIS_METHOD);
			return;
		}
		
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		if (!sentResponseHeaders)
		{
			[self sendResponseHeadersAndBody];
		}
		else
		{
			if (ranges == nil)
			{
				[self continueSendingStandardResponseBody];
			}
			else
			{
				if ([ranges count] == 1)
					[self continueSendingSingleRangeResponseBody];
				else
					[self continueSendingMultiRangeResponseBody];
			}
		}
		
		[pool drain];
	});
}

/**
 * This method is called if the response encounters some critical error,
 * and it will be unable to fullfill the request.
**/
- (void)responseDidAbort:(NSObject<LPHTTPResponse> *)sender
{
	//LPHTTPLogTrace();
	
	// We always dispatch this asynchronously onto our connectionQueue,
	// even if the connectionQueue is the current queue.
	// 
	// We do this to give the LPHTTPResponse classes the flexibility to call
	// this method whenever they want, even from within a readDataOfLength method.
	
	dispatch_async(connectionQueue, ^{
		
		if (sender != httpResponse)
		{
			//LPHTTPLogWarn(@"%@[%p]: %@ - Sender is not current httpResponse", THIS_FILE, self, THIS_METHOD);
			return;
		}
		
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		[asyncSocket disconnectAfterWriting];
		
		[pool drain];
	});
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Post Request
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * This method is called after each response has been fully sent.
 * Since a single connection may handle multiple request/responses, this method may be called multiple times.
 * That is, it will be called after completion of each response.
**/
- (void)finishResponse
{
	//LPHTTPLogTrace();
	
	// Override me if you want to perform any custom actions after a response has been fully sent.
	// This is the place to release memory or resources associated with the last request.
	// 
	// If you override this method, you should take care to invoke [super finishResponse] at some point.
	
	[request release];
	request = nil;
	
	[httpResponse release];
	httpResponse = nil;
	
	[ranges release];
	[ranges_headers release];
	[ranges_boundry release];
	ranges = nil;
	ranges_headers = nil;
	ranges_boundry = nil;
}

/**
 * This method is called after each successful response has been fully sent.
 * It determines whether the connection should stay open and handle another request.
**/
- (BOOL)shouldDie
{
	//LPHTTPLogTrace();
	
	// Override me if you have any need to force close the connection.
	// You may do so by simply returning YES.
	// 
	// If you override this method, you should take care to fall through with [super shouldDie]
	// instead of returning NO.
	
	
	BOOL shouldDie = NO;
	
	NSString *version = [request version];
	if ([version isEqualToString:LPHTTPVersion1_1])
	{
		// LPHTTP version 1.1
		// Connection should only be closed if request included "Connection: close" header
		
		NSString *connection = [request headerField:@"Connection"];
		
		shouldDie = (connection && ([connection caseInsensitiveCompare:@"close"] == NSOrderedSame));
	}
	else if ([version isEqualToString:LPHTTPVersion1_0])
	{
		// LPHTTP version 1.0
		// Connection should be closed unless request included "Connection: Keep-Alive" header
		
		NSString *connection = [request headerField:@"Connection"];
		
		if (connection == nil)
			shouldDie = YES;
		else
			shouldDie = [connection caseInsensitiveCompare:@"Keep-Alive"] != NSOrderedSame;
	}
	
	return shouldDie;
}

- (void)die
{
	//LPHTTPLogTrace();
	
	// Override me if you want to perform any custom actions when a connection is closed.
	// Then call [super die] when you're done.
	// 
	// See also the finishResponse method.
	// 
	// Important: There is a rare timing condition where this method might get invoked twice.
	// If you override this method, you should be prepared for this situation.
	
	// Inform the http response that we're done
	if ([httpResponse respondsToSelector:@selector(connectionDidClose)])
	{
		[httpResponse connectionDidClose];
	}
	
	// Release the http response so we don't call it's connectionDidClose method again in our dealloc method
	[httpResponse release];
	httpResponse = nil;
	
	// Post notification of dead connection
	// This will allow our server to release us from its array of connections
	[[NSNotificationCenter defaultCenter] postNotificationName:LPHTTPConnectionDidDieNotification object:self];
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation LPHTTPConfig

@synthesize server;
@synthesize documentRoot;
@synthesize queue;

- (id)initWithServer:(LPHTTPServer *)aServer documentRoot:(NSString *)aDocumentRoot
{
	if ((self = [super init]))
	{
		server = [aServer retain];
		documentRoot = [aDocumentRoot retain];
	}
	return self;
}

- (id)initWithServer:(LPHTTPServer *)aServer documentRoot:(NSString *)aDocumentRoot queue:(dispatch_queue_t)q
{
	if ((self = [super init]))
	{
		server = [aServer retain];
		
		documentRoot = [aDocumentRoot stringByStandardizingPath];
		if ([documentRoot hasSuffix:@"/"])
		{
			documentRoot = [documentRoot stringByAppendingString:@"/"];
		}
		[documentRoot retain];
		
		if (q)
		{
			dispatch_retain(q);
			queue = q;
		}
	}
	return self;
}

- (void)dealloc
{
	[server release];
	[documentRoot release];
	
	if (queue)
		dispatch_release(queue);
	
	[super dealloc];
}

@end
