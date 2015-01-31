#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "InvokerFactory.h"
#import "LPInvoker.h"

@interface InvokerFactory ()

@property(strong, nonatomic, readonly) NSDictionary *selectorMap;

- (id) init_private;
- (Receiver *) _receiverWithSelectorReturnValue:(NSString *) key;
- (LPInvoker *) _invokerWithSelectorReturnValue:(NSString *) key;

@end

@implementation InvokerFactory

@synthesize selectorMap = _selectorMap;

- (id) init {
  NSString *reason = [NSString stringWithFormat:@"%@ is a singleton",
                      [InvokerFactory debugDescription]];
  @throw [NSException exceptionWithName:@"LPSingletonInitializerException"
                                 reason:reason
                               userInfo:nil];
}

- (id) init_private {
  self = [super init];
  if (self) {

  }
  return self;
}

+ (InvokerFactory *) shared {
  static InvokerFactory *sharedFactory = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedFactory = [[InvokerFactory alloc] init_private];
  });
  return sharedFactory;
}

- (NSDictionary *) selectorMap {
  if (_selectorMap) { return _selectorMap; }

  _selectorMap =
  @{
    @"object" : NSStringFromSelector(@selector(object)),
    @"number" : NSStringFromSelector(@selector(number)),
    @"array" : NSStringFromSelector(@selector(array)),
    @"dictionary" : NSStringFromSelector(@selector(dictionary)),
    @"id" : NSStringFromSelector(@selector(idType)),

    @"void" : NSStringFromSelector(@selector(selectorThatReturnsVoid)),
    @"BOOL YES" : NSStringFromSelector(@selector(selectorThatReturnsBOOL_YES)),
    @"BOOL NO" : NSStringFromSelector(@selector(selectorThatReturnsBOOL_NO)),
    @"bool true" : NSStringFromSelector(@selector(selectorThatReturnsBool_true)),
    @"bool false" : NSStringFromSelector(@selector(selectorThatReturnsBool_false)),
    @"NSInteger" : NSStringFromSelector(@selector(selectorThatReturnsNSInteger)),
    @"NSUInteger" : NSStringFromSelector(@selector(selectorThatReturnsNSUInteger)),
    @"short" : NSStringFromSelector(@selector(selectorThatReturnsShort)),
    @"unsigned short" : NSStringFromSelector(@selector(selectorThatReturnsUnsignedShort)),
    @"CGFloat" : NSStringFromSelector(@selector(selectorThatReturnsCGFloat)),
    @"double" : NSStringFromSelector(@selector(selectorThatReturnsDouble)),
    @"float" : NSStringFromSelector(@selector(selectorThatReturnsFloat)),
    @"char" : NSStringFromSelector(@selector(selectorThatReturnsChar)),
    @"char *" : NSStringFromSelector(@selector(selectorThatReturnsCharStar)),
    @"const char *" : NSStringFromSelector(@selector(selectorThatReturnsConstCharStar)),
    @"unsigned char" : NSStringFromSelector(@selector(selectorThatReturnsUnsignedChar)),

    @"long" : NSStringFromSelector(@selector(selectorThatReturnsLong)),
    @"unsigned long" : NSStringFromSelector(@selector(selectorThatReturnsUnsignedLong)),
    @"long long" : NSStringFromSelector(@selector(selectorThatReturnsLongLong)),
    @"unsigned long long" : NSStringFromSelector(@selector(selectorThatReturnsUnsignedLongLong)),
    };

  return _selectorMap;
}

+ (Receiver *) receiverWithSelectorReturnValue:(NSString *) key {
  InvokerFactory *factory = [InvokerFactory shared];
  return [factory _receiverWithSelectorReturnValue:key];
}

+ (LPInvoker *) invokerWithSelectorReturnValue:(NSString *) key {
  InvokerFactory *factory = [InvokerFactory shared];
  return [factory _invokerWithSelectorReturnValue:key];
}

- (Receiver *) _receiverWithSelectorReturnValue:(NSString *) key {
  NSDictionary *map = self.selectorMap;
  NSString *selector = [map objectForKey:key];
  if (!selector) {
    NSString *reason = [NSString stringWithFormat:@"Key '%@' is not one of '%@'",
                        key, [map allKeys]];
    @throw [NSException exceptionWithName:@"LPNoObjectForKey"
                                   reason:reason
                                 userInfo:nil];
  }

  Receiver *receiver = [Receiver new];
  receiver.selector = NSSelectorFromString(selector);
  return receiver;
}

- (LPInvoker *) _invokerWithSelectorReturnValue:(NSString *) key {
  Receiver *receiver = [self _receiverWithSelectorReturnValue:key];
  return [[LPInvoker alloc] initWithSelector:receiver.selector
                                    receiver:receiver];
}

@end

@implementation Receiver

- (id) init {
  self = [super init];
  if (self) {
    _object = [NSObject new];
    _number = [NSNumber numberWithInt:0];
    _array = [NSArray array];
    _dictionary = [NSDictionary dictionary];
    _idType = nil;
    _selector = nil;
  }
  return self;
}

- (void) selectorThatReturnsVoid { return; }
- (BOOL) selectorThatReturnsBOOL_YES { return YES; }
- (BOOL) selectorThatReturnsBOOL_NO { return NO; }
- (bool) selectorThatReturnsBool_true { return true; }
- (bool) selectorThatReturnsBool_false { return false; }
- (NSInteger) selectorThatReturnsNSInteger { return (NSInteger)NSIntegerMin; }
- (NSInteger) selectorThatReturnsNSUInteger { return (NSUInteger)NSNotFound; }
- (short) selectorThatReturnsShort { return (short)SHRT_MIN; }
- (unsigned short) selectorThatReturnsUnsignedShort { return (unsigned short)SHRT_MAX; }
- (CGFloat) selectorThatReturnsCGFloat { return (CGFloat)CGFLOAT_MAX; }
- (double) selectorThatReturnsDouble { return (double)DBL_MAX; }
- (float) selectorThatReturnsFloat { return (float)MAXFLOAT; }
- (char) selectorThatReturnsChar { return 'c'; }
- (char *) selectorThatReturnsCharStar { return "char *"; }
- (const char *) selectorThatReturnsConstCharStar { return (const char *) "const char *"; }
- (unsigned char) selectorThatReturnsUnsignedChar { return (unsigned char) 'C'; }
- (long) selectorThatReturnsLong { return (long)LONG_MIN; }
- (unsigned long) selectorThatReturnsUnsignedLong { return (unsigned long)ULONG_MAX; }
- (long long) selectorThatReturnsLongLong { return (long long)LONG_LONG_MIN; }
- (unsigned long long) selectorThatReturnsUnsignedLongLong { return (unsigned long long)ULONG_LONG_MAX; }


@end
