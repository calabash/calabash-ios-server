#import "LPHTTPRedirectResponse.h"
#import "LPHTTPLogging.h"

#if !__has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

static LPLogLevel __unused lpHTTPLogLevel = LPLogLevelError;

@implementation LPHTTPRedirectResponse

- (id)initWithPath:(NSString *)path {
  if ((self = [super init])) {
    LPHTTPLogTrace();

    redirectPath = [path copy];
  }
  return self;
}

- (UInt64)contentLength {
  return 0;
}

- (UInt64)offset {
  return 0;
}

- (void)setOffset:(UInt64)offset {
  // Nothing to do
}

- (NSData *)readDataOfLength:(NSUInteger)length {
  LPHTTPLogTrace();

  return nil;
}

- (BOOL)isDone {
  return YES;
}

- (NSDictionary *)httpHeaders {
  LPHTTPLogTrace();

  return [NSDictionary dictionaryWithObject:redirectPath forKey:@"Location"];
}

- (NSInteger)status {
  LPHTTPLogTrace();

  return 302;
}

- (void)dealloc {
  LPHTTPLogTrace();
}

@end
