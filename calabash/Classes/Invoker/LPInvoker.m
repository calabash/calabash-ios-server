#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPInvoker.h"

NSString *const LPTargetDoesNotRespondToSelector = @"*****";
NSString *const LPVoidSelectorReturnValue = @"*selector returns void*";
NSString *const LPSelectorHasUnhandledEncoding = @"*selector returns unhandled encoding*";
NSString *const LPSelectorHasUnhandledArguments = @"*unhandled selector arguments*";
NSString *const LPCannotCoerceSelectorReturnValueToObject = @"*cannot coerce to object*";
NSString *const LPSelectorHasUnknownEncoding = @"*unknown encoding*";
NSString *const LPUnspecifiedInvocationError = @"*invocation error*";

@interface LPCoercion ()

- (id) initWithValue:(id) value
      failureMessage:(NSString *) failureMessage;

@end

@implementation LPCoercion

- (id) initWithValue:(id) value
      failureMessage:(NSString *) failureMessage {
  self = [super init];
  if (self) {
    _value = value;
    _failureMessage = failureMessage;
  };
  return self;
}

+ (id) coercionWithValue:(id) value {
  return [[LPCoercion alloc] initWithValue:value failureMessage:nil];
}

+ (id) coercionWithFailureMessage:(NSString *) failureMessage {
  return [[LPCoercion alloc] initWithValue:nil failureMessage:failureMessage];
}

- (BOOL) wasSuccessful {
  if (self) {
    return YES;
  } else {
    return NO;
  }
}

@end

@interface LPInvoker ()

@property(strong, nonatomic, readonly) NSString *encoding;
@property(strong, nonatomic, readonly) NSInvocation *invocation;
@property(strong, nonatomic, readonly) NSMethodSignature *signature;

- (BOOL) selectorReturnsObject;
- (BOOL) selectorReturnsVoid;
- (BOOL) selectorReturnValueCanBeCoerced;
- (NSUInteger) numberOfArguments;
- (BOOL) selectorHasArguments;
- (LPCoercion *) objectByCoercingReturnValue;

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
- (id) initWithSelector:(SEL) selector target:(id) target {
  self = [super init];
  if (self) {
    _selector = selector;
    _target = target;
    _invocation = nil;
    _signature = nil;
  }
  return self;
}

- (NSString *) description {
  return [NSString stringWithFormat:@"#<LPInvoker '%@' '%@' => '%@'>]",
          NSStringFromSelector(self.selector), [self.target class], self.encoding];
}

- (NSString *) debugDescription {
  return [self description];
}

+ (id) invokeSelector:(SEL) selector withTarget:(id) target {
  LPInvoker *invoker = [[LPInvoker alloc] initWithSelector:selector
                                                    target:target];
  if (![invoker targetRespondsToSelector]) { return [NSNull null]; }

  if ([invoker selectorHasArguments]) { return [NSNull null]; }

  if ([invoker selectorReturnsVoid]) { return [NSNull null]; }

  if ([invoker encodingIsUnhandled]) { return [NSNull null]; }

  if ([invoker selectorReturnsObject]) {
    NSInvocation *invocation = invoker.invocation;

    id result = nil;

    @try {
      void *buffer;
      [invocation invoke];
      [invocation getReturnValue:&buffer];
      result = (__bridge id)buffer;
    } @catch (NSException *exception) {
      NSLog(@"LPInvoker caught an exception: %@", exception);
      NSLog(@"=== INVOCATION DETAILS ===");
      NSLog(@"target class = %@", [target class]);
      NSLog(@"selector = %@", NSStringFromSelector(selector));
      NSLog(@"target responds to selector: %@", [target respondsToSelector:selector] ? @"YES" : @"NO");
      result = nil;
    }

    if(!result) {
      return [NSNull null];
    } else {
      return result;
    }
  }

  if ([invoker selectorReturnValueCanBeCoerced]) {
    LPCoercion *coercion = [invoker objectByCoercingReturnValue];
    if ([coercion wasSuccessful]) {
      return coercion.value;
    } else {
      return [NSNull null];
    }
  }

  return [NSNull null];
}

- (NSInvocation *) invocation {
  if (_invocation) { return _invocation; }
  if (![self targetRespondsToSelector]) {
    NSLog(@"Target '%@' does not respond to selector '%@'; cannot create invocation.",
          self.target, NSStringFromSelector(self.selector));
    return nil;
  }

  NSInvocation *invocation;
  invocation = [NSInvocation invocationWithMethodSignature:self.signature];
  [invocation setTarget:self.target];
  [invocation setSelector:self.selector];
  _invocation = invocation;
  return _invocation;
}

- (NSMethodSignature *) signature {
  if (_signature) { return _signature; }
  _signature = [[self.target class] instanceMethodSignatureForSelector:self.selector];
  if (!_signature) {
    NSLog(@"Cannot create signature; target '%@' does not respond to selector '%@'",
          self.target, NSStringFromSelector(self.selector));
  }
  return _signature;
}

- (BOOL) targetRespondsToSelector {
  return [self.target respondsToSelector:self.selector];
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

  if (![self targetRespondsToSelector]) {
    _encoding = LPTargetDoesNotRespondToSelector;
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
  if (![self targetRespondsToSelector]) { return NO; }
  return [self.encoding isEqualToString:@"@"];
}

- (BOOL) selectorReturnsVoid {
  if (![self targetRespondsToSelector]) { return NO; }
  return [self.encoding isEqualToString:@"v"];
}

- (BOOL) selectorReturnValueCanBeCoerced {
  if (![self targetRespondsToSelector]) { return NO; }
  if ([self selectorReturnsVoid]) { return NO; }
  if ([self selectorReturnsObject]) { return NO; }
  if ([self encodingIsUnhandled]) { return NO; }
  return YES;
}

- (LPCoercion *) objectByCoercingReturnValue {
  NSString *encoding = self.encoding;
  SEL selector = self.selector;
  id target = self.target;

  if (![self targetRespondsToSelector]) {
    return [LPCoercion coercionWithFailureMessage:LPTargetDoesNotRespondToSelector];
  }

  if (![self selectorReturnValueCanBeCoerced]) {
    return [LPCoercion coercionWithFailureMessage:LPCannotCoerceSelectorReturnValueToObject];
  }

  // Guard against invalid access when asking for encoding[0]
  if (!encoding.length >= 1) {
    NSLog(@"Selector '%@' on '%@' has an invalid encoding; '%@' must have at least once character.",
          NSStringFromSelector(selector), target, encoding);
    return [LPCoercion coercionWithFailureMessage:LPSelectorHasUnknownEncoding];
  }

  NSInvocation *invocation = self.invocation;
  [invocation invoke];

  if ([encoding isEqualToString:@"r*"]) {
    const char *ref;
    [invocation getReturnValue:(void **) &ref];
    return [LPCoercion coercionWithValue:@(ref)];
  }

  char char_encoding = [encoding cStringUsingEncoding:NSASCIIStringEncoding][0];
  switch (char_encoding) {

    case '*' : {
      char *ref;
      [invocation getReturnValue:(void **) &ref];
      return [LPCoercion coercionWithValue:@(ref)];
    }

      // BOOL is explicitly signed so @encode(BOOL) == "c" rather than "C"
      // even if -funsigned-char is used.
    case 'c' : {
      char ref;
      [invocation getReturnValue:(void **) &ref];
      if (ref == (BOOL)1) {
        return [LPCoercion coercionWithValue:@(YES)];
      } else if (ref == (BOOL)0) {
        return [LPCoercion coercionWithValue:@(NO)];
      } else {
        NSString *value = [NSString stringWithFormat:@"%c", (char) ref];
        return [LPCoercion coercionWithValue:value];
      }
    }

    case 'C' : {
      unsigned char ref;
      [invocation getReturnValue:(void **) &ref];
      NSString *value = [NSString stringWithFormat:@"%c", (char) ref];
      return [LPCoercion coercionWithValue:value];
    }

      // See note above for 'c'.
    case 'B': {
      bool ref;
      [invocation getReturnValue:(void **) &ref];
      if (ref == true) {
        return [LPCoercion coercionWithValue:@(YES)];
      } else {
        return [LPCoercion coercionWithValue:@(NO)];
      }
    }

    case 'i': {
      int ref;
      [invocation getReturnValue:(void **) &ref];
      return [LPCoercion coercionWithValue:@((int) ref)];
    }

    case 'I': {
      unsigned int ref;
      [invocation getReturnValue:(void **) &ref];
      return [LPCoercion coercionWithValue:@((unsigned int) ref)];
    }

    case 's': {
      short ref;
      [invocation getReturnValue:(void **) &ref];
      return [LPCoercion coercionWithValue:@((short) ref)];
    }

    case 'S': {
      unsigned short ref;
      [invocation getReturnValue:(void **) &ref];
      return [LPCoercion coercionWithValue:@((unsigned short) ref)];
    }

    case 'd' : {
      double ref;
      [invocation getReturnValue:(void **) &ref];
      return [LPCoercion coercionWithValue:@((double) ref)];
    }

    case 'f' : {
      float ref;
      [invocation getReturnValue:(void **) &ref];
      return [LPCoercion coercionWithValue:@((float) ref)];
    }

    case 'l' : {
      long ref;
      [invocation getReturnValue:(void **) &ref];
      return [LPCoercion coercionWithValue:@((long) ref)];
    }

    case 'L' : {
      unsigned long ref;
      [invocation getReturnValue:(void **) &ref];
      return [LPCoercion coercionWithValue:@((unsigned long) ref)];
    }

    case 'q' : {
      long long ref;
      [invocation getReturnValue:(void **) &ref];
      return [LPCoercion coercionWithValue:@((long long) ref)];
    }

    case 'Q' : {
      unsigned long long ref;
      [invocation getReturnValue:(void **) &ref];
      return [LPCoercion coercionWithValue:@((unsigned long long) ref)];
    }

    default: {
      NSLog(@"Unexpected type encoding: '%@'.", encoding);
    }
  }

  return [LPCoercion coercionWithFailureMessage:LPSelectorHasUnknownEncoding];
}

@end
