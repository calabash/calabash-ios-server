#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPInvoker.h"

NSString *const LPReceiverDoesNotRespondToSelector = @"*****";
NSString *const LPVoidSelectorReturnValue = @"*selector returns void*";
NSString *const LPSelectorHasUnhandledEncoding = @"*selector returns unhandled encoding*";
NSString *const LPSelectorHasUnhandledArguments = @"*unhandled selector arguments*";
NSString *const LPCannotCoerceSelectorReturnValueToObject = @"*cannot coerce to object*";
NSString *const LPSelectorHasUnknownEncoding = @"*unknown encoding*";
NSString *const LPUnspecifiedInvocationError = @"*invocation error*";

@interface LPInvoker ()

@property(strong, nonatomic, readonly) NSString *encoding;
@property(strong, nonatomic, readonly) NSInvocation *invocation;
@property(strong, nonatomic, readonly) NSMethodSignature *signature;

- (BOOL) selectorReturnsObject;
- (BOOL) selectorReturnsVoid;
- (BOOL) selectorReturnValueCanBeCoerced;
- (NSUInteger) numberOfArguments;
- (BOOL) selectorHasArguments;
- (id) objectByCoercingReturnValue;

@end

@implementation LPInvoker

@synthesize encoding = _encoding;
@synthesize invocation = _invocation;
@synthesize signature = _signature;

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
    _signature = nil;
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

+ (id) objectBySafelyInvokingSelector:(SEL)selector receiver:(id)receiver {
  LPInvoker *invoker = [[LPInvoker alloc] initWithSelector:selector
                                                  receiver:receiver];
  if (![invoker receiverRespondsToSelector]) { return LPReceiverDoesNotRespondToSelector; }

  if ([invoker selectorHasArguments]) { return LPSelectorHasUnhandledArguments; }

  if ([invoker selectorReturnsVoid]) { return LPVoidSelectorReturnValue; }

  if ([invoker encodingIsUnhandled]) { return LPSelectorHasUnhandledEncoding; }

  if ([invoker selectorReturnsObject]) {
    NSInvocation *invocation = invoker.invocation;
    id result;
    [invocation invoke];
    [invocation getReturnValue:&result];
    return result;
  }

  if ([invoker selectorReturnValueCanBeCoerced]) { return [invoker objectByCoercingReturnValue]; }

  return LPUnspecifiedInvocationError;
}

- (NSInvocation *) invocation {
  if (_invocation) { return _invocation; }
  if (![self receiverRespondsToSelector]) {
    NSLog(@"Receiver '%@' does not respond to selector '%@'; cannot create invocation.",
          self.receiver, NSStringFromSelector(self.selector));
    return nil;
  }

  NSInvocation *invocation;
  invocation = [NSInvocation invocationWithMethodSignature:self.signature];
  [invocation setTarget:self.receiver];
  [invocation setSelector:self.selector];
  _invocation = invocation;
  return _invocation;
}

- (NSMethodSignature *) signature {
  if (_signature) { return _signature; }
  _signature = [[self.receiver class] instanceMethodSignatureForSelector:self.selector];
  if (!_signature) {
    NSLog(@"Cannot create signature; receiver '%@' does not respond to selector '%@'",
          self.receiver, NSStringFromSelector(self.selector));
  }
  return _signature;
}

- (BOOL) receiverRespondsToSelector {
  return [self.receiver respondsToSelector:self.selector];
}

/*
 There are always at least two arguments, because an NSMethodSignature object
 includes the hidden arguments self and _cmd, which are the first two arguments
 passed to every method implementation.
*/
- (NSUInteger) numberOfArguments {
  return [self.signature numberOfArguments] - 2;
}

- (BOOL) selectorHasArguments {
  return [self numberOfArguments] != 0;
}

- (NSString *) encoding {
  if (_encoding) { return _encoding; }

  if (![self receiverRespondsToSelector]) {
    _encoding = LPReceiverDoesNotRespondToSelector;
  } else {
    NSMethodSignature *signature = self.signature;
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

- (id) objectByCoercingReturnValue {
  NSString *encoding = self.encoding;
  SEL selector = self.selector;
  id receiver = self.receiver;

  if (![self receiverRespondsToSelector]) {
    return LPReceiverDoesNotRespondToSelector;
  }

  if (![self selectorReturnValueCanBeCoerced]) {
    return LPCannotCoerceSelectorReturnValueToObject;
  }

  // Guard against invalid access when asking for encoding[0]
  if (!encoding.length >= 1) {
    NSLog(@"Selector '%@' on '%@' has an invalid encoding; '%@' must have at least once character.",
          NSStringFromSelector(selector), receiver, encoding);
    return LPSelectorHasUnknownEncoding;
  }

  NSInvocation *invocation = self.invocation;
  [invocation invoke];

  if ([encoding isEqualToString:@"r*"]) {
    const char *ref;
    [invocation getReturnValue:(void **) &ref];
    return @(ref);
  }

  char char_encoding = [encoding cStringUsingEncoding:NSASCIIStringEncoding][0];
  switch (char_encoding) {

    case '*' : {
      char *ref;
      [invocation getReturnValue:(void **) &ref];
      return @(ref);
    }

      // BOOL is explicitly signed so @encode(BOOL) == "c" rather than "C"
      // even if -funsigned-char is used.
    case 'c' : {
      char ref;
      [invocation getReturnValue:(void **) &ref];
      if (ref == (BOOL)1) {
        return [NSNumber numberWithBool:YES];
      } else if (ref == (BOOL)0) {
        return [NSNumber numberWithBool:NO];
      } else {
        return [NSString stringWithFormat:@"%c", (char) ref];
      }
    }

    case 'C' : {
      unsigned char ref;
      [invocation getReturnValue:(void **) &ref];
      return [NSString stringWithFormat:@"%c", (char) ref];
    }

      // See note above for 'c'.
    case 'B': {
      bool ref;
      [invocation getReturnValue:(void **) &ref];
      if (ref == true) {
        return [NSNumber numberWithBool:YES];
      } else {
        return [NSNumber numberWithBool:NO];
      }
    }

    case 'i': {
      int ref;
      [invocation getReturnValue:(void **) &ref];
      return @((int) ref);
    }

    case 'I': {
      unsigned int ref;
      [invocation getReturnValue:(void **) &ref];
      return @((unsigned int) ref);
    }

    case 's': {
      short ref;
      [invocation getReturnValue:(void **) &ref];
      return @((short) ref);
    }

    case 'S': {
      unsigned short ref;
      [invocation getReturnValue:(void **) &ref];
      return @((unsigned short) ref);
    }

    case 'd' : {
      double ref;
      [invocation getReturnValue:(void **) &ref];
      return @((double) ref);
    }

    case 'f' : {
      float ref;
      [invocation getReturnValue:(void **) &ref];
      return @((float) ref);
    }

    case 'l' : {
      long ref;
      [invocation getReturnValue:(void **) &ref];
      return @((long) ref);
    }

    case 'L' : {
      unsigned long ref;
      [invocation getReturnValue:(void **) &ref];
      return @((unsigned long) ref);
    }

    case 'q' : {
      long long ref;
      [invocation getReturnValue:(void **) &ref];
      return @((long long) ref);
    }

    case 'Q' : {
      unsigned long long ref;
      [invocation getReturnValue:(void **) &ref];
      return @((unsigned long long) ref);
    }

    default: {
      NSLog(@"Unexpected type encoding: '%@'.", encoding);
    }
  }

  return LPSelectorHasUnknownEncoding;
}

@end
