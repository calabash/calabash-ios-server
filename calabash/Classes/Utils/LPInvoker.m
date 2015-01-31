#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPInvoker.h"

NSString *const LPReceiverDoesNotRespondToSelectorEncoding = @"*****";

@interface LPInvoker ()

@property(strong, nonatomic, readonly) NSString *encoding;
@property(strong, nonatomic, readonly) NSInvocation *invocation;

- (BOOL) selectorReturnsObject;
- (BOOL) selectorReturnsVoid;
- (id) objectWithAutoboxedValue;
- (BOOL) selectorReturnValueCanBeCoerced;

@end

@implementation LPInvoker

@synthesize encoding = _encoding;
@synthesize invocation = _invocation;

- (id) init {
  @throw [NSException exceptionWithName:@"LPDesignatedInitializerException"
                                 reason:@"init is not the designated initializer for LPInvoker"
                                 userInfo:nil];
}

// Designated initializer.
- (id) initWithSelector:(SEL) selector receiver:(id) receiver {
  self = [super init];
  if (self) {
    _selector = selector;
    _receiver = receiver;
    _invocation = nil;
  }
  return self;
}

- (NSString *) description {
  return [NSString stringWithFormat:@"#<LPInvoker '%@' '%@' => '%@'>]",
          NSStringFromSelector(self.selector), [self.receiver class], self.encoding];
}

- (NSString *) debugDescription {
  return [self description];
}

- (NSInvocation *) invocation {
  if (_invocation) { return _invocation; }
  if (![self receiverRespondsToSelector]) {
    NSLog(@"Receiver '%@' does not respond to selector '%@'; cannot create invocation.",
          self.receiver, NSStringFromSelector(self.selector));
    return nil;
  }

  NSMethodSignature *signature;
  signature = [[self.receiver class] instanceMethodSignatureForSelector:self.selector];
  NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
  [invocation setTarget:self.receiver];
  [invocation setSelector:self.selector];
  _invocation = invocation;
  return _invocation;
}

- (BOOL) receiverRespondsToSelector {
  return [self.receiver respondsToSelector:self.selector];
}

- (NSString *) encoding {
  if (_encoding) { return _encoding; }

  if (![self receiverRespondsToSelector]) {
    _encoding = LPReceiverDoesNotRespondToSelectorEncoding;
  } else {
    NSMethodSignature *signature;
    signature = [self.receiver methodSignatureForSelector:self.selector];
    _encoding = [NSString stringWithCString:[signature methodReturnType]
                                   encoding:NSASCIIStringEncoding];
  }
  return _encoding;
}

- (BOOL) encodingIsUnhandled {
  NSString *encoding = self.encoding;

  // @encode(void *) => ^v
  // @encode(float *) => ^f
  if ([encoding hasPrefix:@"^"]) { return YES; }

  // @encode(typeof(NSError **))
  if ([encoding isEqualToString:@"^@"]) { return YES; }

  // @encode(NSObject)
  if ([encoding isEqualToString:@"#"]) { return YES; }

  // @encode(typeof([NSObject class])) => {NSObject=#}
  // @encode(typeof(Struct)) => {name=type...}
  if ([encoding hasPrefix:@"{"]) { return YES; }

  // @encode(typeof(Union)) => (name=type...)
  if ([encoding hasPrefix:@"("]) { return YES; }

  // @encode(typeof(@selector(length))) => :
  if ([encoding isEqualToString:@":"]) { return YES; }

  // @encode(typeof(BitField) => bNUM
  if ([encoding hasPrefix:@"b"]) { return YES; }

  // int arr[5] = {1, 2, 3, 4, 5}; @encode(typeof(arr)) => [5i]
  // float arr[3] = {0.1f, 0.2f, 0.3f}; @encode(typeof(arr)) => [3f]
  if ([encoding hasPrefix:@"["]) { return YES; }

  // unknown - function pointers?
  if ([encoding isEqualToString:@"?"]) { return YES; }
  return NO;
}

- (BOOL) selectorReturnsObject {
  if (![self receiverRespondsToSelector]) { return NO; }
  return [self.encoding isEqualToString:@"@"];
}

- (BOOL) selectorReturnsVoid {
  if (![self receiverRespondsToSelector]) { return NO; }
  return [self.encoding isEqualToString:@"v"];
}

- (BOOL) selectorReturnValueCanBeCoerced {
  if (![self receiverRespondsToSelector]) { return NO; }
  if ([self selectorReturnsVoid]) { return NO; }
  if ([self selectorReturnsObject]) { return NO; }
  if ([self encodingIsUnhandled]) { return NO; }
  return YES;
}

}

@end
