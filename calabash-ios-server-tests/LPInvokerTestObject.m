#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPInvokerTestObject.h"

@implementation LPInvokerTestObject

- (id) init {
  self = [super init];
  if (self) {
    _object = [NSObject new];
    _number = [NSNumber numberWithInt:0];
    _array = [NSArray array];
    _dictionary = [NSDictionary dictionary];
    _idType = nil;
  }
  return self;
}

- (void) selectorThatReturnsVoid { return; }
- (BOOL) selectorThatReturnsBOOL { return YES; }
- (NSInteger) selectorThatReturnsNSInteger { return 1; }
- (CGFloat) selectorThatReturnsCGFloat { return 0.0; }
- (char) selectorThatReturnsChar { return 'a'; }
- (const char *) selectorThatReturnsCharArray {
  return [@"abc" cStringUsingEncoding:NSASCIIStringEncoding];
}

- (char *) selectorThatReturnsCharStar {
  char *cString = "A c-string";
  return cString;
}

@end
