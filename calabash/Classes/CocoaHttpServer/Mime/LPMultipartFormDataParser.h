#import "LPMultipartMessageHeader.h"

/* 
Part one: http://tools.ietf.org/html/rfc2045 (Format of Internet Message Bodies)
Part two: http://tools.ietf.org/html/rfc2046 (Media Types)
Part three: http://tools.ietf.org/html/rfc2047 (Message Header Extensions for Non-ASCII Text)
Part four: http://tools.ietf.org/html/rfc4289 (Registration Procedures) 
Part five: http://tools.ietf.org/html/rfc2049 (Conformance Criteria and Examples) 
 
Internet message format:  http://tools.ietf.org/html/rfc2822

LPMutlipart/form-data http://tools.ietf.org/html/rfc2388
*/

@class LPMutlipartFormDataParser;

//-----------------------------------------------------------------
// protocol LPMutlipartFormDataParser
//-----------------------------------------------------------------

@protocol LPMutlipartFormDataParserDelegate <NSObject> 
@optional
- (void) processContent:(NSData*) data WithHeader:(LPMutlipartMessageHeader*) header;
- (void) processEndOfPartWithHeader:(LPMutlipartMessageHeader*) header;
- (void) processPreambleData:(NSData*) data;
- (void) processEpilogueData:(NSData*) data;
- (void) processStartOfPartWithHeader:(LPMutlipartMessageHeader*) header;
@end

//-----------------------------------------------------------------
// interface LPMutlipartFormDataParser
//-----------------------------------------------------------------

@interface LPMutlipartFormDataParser : NSObject {
NSMutableData*						pendingData;
    NSData*							boundaryData;
    LPMutlipartMessageHeader*			currentHeader;

	BOOL							waitingForCRLF;
	BOOL							reachedEpilogue;
	BOOL							processedPreamble;
	BOOL							checkForContentEnd;

#if __has_feature(objc_arc_weak)
	__weak id<LPMutlipartFormDataParserDelegate>                  delegate;
#else
	__unsafe_unretained id<LPMutlipartFormDataParserDelegate>     delegate;
#endif	
	int									currentEncoding;
	NSStringEncoding					formEncoding;
}

- (BOOL) appendData:(NSData*) data;

- (id) initWithBoundary:(NSString*) boundary formEncoding:(NSStringEncoding) formEncoding;

#if __has_feature(objc_arc_weak)
@property(weak, readwrite) id delegate;
#else
@property(unsafe_unretained, readwrite) id delegate;
#endif	

@property(readwrite) NSStringEncoding	formEncoding;

@end
