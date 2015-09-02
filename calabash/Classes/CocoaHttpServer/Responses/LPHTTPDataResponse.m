#import "LPHTTPDataResponse.h"
#import "LPHTTPLogging.h"

#if !__has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

static LPLogLevel __unused lpHTTPLogLevel = LPLogLevelWarning;

@implementation LPHTTPDataResponse

- (id)initWithData:(NSData *)dataParam {
  if ((self = [super init])) {
    LPHTTPLogTrace();

    offset = 0;
    data = dataParam;
  }
  return self;
}

- (void)dealloc {
  LPHTTPLogTrace();
}

- (UInt64)contentLength {
  UInt64 result = (UInt64) [data length];

  LPHTTPLogVerbose(@"%@[%p]: contentLength - %llu", LP_THIS_FILE, self, result);

  return result;
}

- (UInt64)offset {
  LPHTTPLogTrace();

  return offset;
}

- (void)setOffset:(UInt64)offsetParam {
  LPHTTPLogVerbose(@"%@[%p]: setOffset:%lu", LP_THIS_FILE, self, (unsigned long) offset);

  offset = (NSUInteger) offsetParam;
}

- (NSData *)readDataOfLength:(NSUInteger)lengthParameter {
  LPHTTPLogVerbose(@"%@[%p]: readDataOfLength:%lu", LP_THIS_FILE, self, (unsigned long) lengthParameter);

  NSUInteger remaining = [data length] - offset;
  NSUInteger length = lengthParameter < remaining ? lengthParameter : remaining;

  void *bytes = (void *) ([data bytes] + offset);

  offset += length;

  return [NSData dataWithBytesNoCopy:bytes length:length freeWhenDone:NO];
}

- (BOOL)isDone {
  BOOL result = (offset == [data length]);

  LPHTTPLogVerbose(@"%@[%p]: isDone - %@", LP_THIS_FILE, self, (result ? @"YES" : @"NO"));

  return result;
}

@end
