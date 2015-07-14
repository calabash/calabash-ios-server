#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPInvoker.h"
#import "LPCoercion.h"
#import "LPCocoaLumberjack.h"

@interface LPInvoker ()

@property(strong, nonatomic, readonly) NSString *encodingForSelectorReturnType;
@property(strong, nonatomic, readonly) NSInvocation *invocation;
@property(strong, nonatomic, readonly) NSMethodSignature *signature;

- (BOOL) selectorReturnsObject;
- (BOOL) selectorReturnsVoid;
- (BOOL) selectorReturnValueCanBeCoerced;
- (NSUInteger) numberOfArguments;
- (BOOL) selectorHasArguments;
- (LPCoercion *) objectByCoercingReturnValue;
+ (BOOL) isCGRectEncoding:(NSString *) encoding;
+ (BOOL) isCGPointEncoding:(NSString *) encoding;
+ (NSString *) encodingAtIndex:(NSUInteger) index
                     signature:(NSMethodSignature *) signature;
+ (BOOL) canHandleArgumentEncoding:(NSString *) encoding;

@end

@implementation LPInvoker

@synthesize encodingForSelectorReturnType = _encodingForSelectorReturnType;
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
          NSStringFromSelector(self.selector),
          [self.target class],
          self.encodingForSelectorReturnType];
}

- (NSString *) debugDescription {
  return [self description];
}

+ (id) invokeZeroArgumentSelector:(SEL) selector withTarget:(id) target {
  LPInvoker *invoker = [[LPInvoker alloc] initWithSelector:selector
                                                    target:target];
  if (![invoker targetRespondsToSelector]) { return [NSNull null]; }

  if ([invoker selectorHasArguments]) { return [NSNull null]; }

  if ([invoker selectorReturnsVoid]) { return [NSNull null]; }

  if ([invoker selectorReturnTypeEncodingIsUnhandled]) { return [NSNull null]; }

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

+ (BOOL) isCGRectEncoding:(NSString *) encoding {
  return [encoding rangeOfString:@"{CGRect"].location == 0;
}

+ (BOOL) isCGPointEncoding:(NSString *) encoding {
  return [encoding rangeOfString:@"{CGPoint"].location == 0;
}

#pragma mark - Selector Return Type Encoding

- (NSString *) encodingForSelectorReturnType {
  if (_encodingForSelectorReturnType) { return _encodingForSelectorReturnType; }

  if (![self targetRespondsToSelector]) {
    _encodingForSelectorReturnType = LPTargetDoesNotRespondToSelector;
  } else {
    NSMethodSignature *signature = self.signature;
    _encodingForSelectorReturnType = [NSString stringWithCString:[signature methodReturnType]
                                                        encoding:NSASCIIStringEncoding];
  }
  return _encodingForSelectorReturnType;
}

- (BOOL) selectorReturnTypeEncodingIsUnhandled {
  NSString *encoding = self.encodingForSelectorReturnType;

  // @encode(void *) => ^v
  // @encode(float *) => ^f
  if ([encoding hasPrefix:@"^"]) { return YES; }

  // @encode(typeof(NSError **))
  if ([encoding isEqualToString:@"^@"]) { return YES; }

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
  return [self.encodingForSelectorReturnType isEqualToString:@"@"];
}

- (BOOL) selectorReturnsVoid {
  if (![self targetRespondsToSelector]) { return NO; }
  return [self.encodingForSelectorReturnType isEqualToString:@"v"];
}

- (BOOL) selectorReturnValueCanBeCoerced {
  if (![self targetRespondsToSelector]) { return NO; }
  if ([self selectorReturnsVoid]) { return NO; }
  if ([self selectorReturnsObject]) { return NO; }
  if ([self selectorReturnTypeEncodingIsUnhandled]) { return NO; }
  return YES;
}

- (LPCoercion *) objectByCoercingReturnValue {
  NSString *encoding = self.encodingForSelectorReturnType;
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
    LPLogWarn(@"Selector '%@' on '%@' has an invalid encoding; '%@' must have at least one character.",
              NSStringFromSelector(selector), target, encoding);
    return [LPCoercion coercionWithFailureMessage:LPSelectorHasUnknownEncoding];
  }

  NSInvocation *invocation = self.invocation;

  // Without this check, the static analyser complains.
  // Let's force a crash if we ever find ourselves in this situation.
  if (!invocation) {
    LPLogError(@"Expected a non-nil invocation.");
    NSString *reason = @"self.invocation must not be nil";
    @throw [NSException exceptionWithName:@"Calabash Server: LPInvoker"
                                   reason:reason
                                 userInfo:nil];
  }

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

    // [NSObject class]
    case '#' : {

      // A malloc here will create an instance of the Class.  For example,
      // if the Class were, [NSArray class], a malloc would create an empty
      // NSArray.
      void *buffer;

      [invocation getReturnValue:&buffer];

      Class klass = (__bridge Class)buffer;
      NSString *name = [NSString stringWithFormat:@"%@",
                        NSStringFromClass(klass)];

      // Force this to be collected by ARC.
      klass = nil;
      return [LPCoercion coercionWithValue:name];
    }

    case '{' : {

      const char *objCType = [encoding cStringUsingEncoding:NSASCIIStringEncoding];
      NSUInteger length = [[invocation methodSignature] methodReturnLength];
      void *buffer = (void *) malloc(length);

      [invocation getReturnValue:buffer];

      NSValue *value = [[NSValue alloc] initWithBytes:buffer
                                             objCType:objCType];

      if ([LPInvoker isCGPointEncoding:encoding]) {

        CGPoint *point = (CGPoint *) buffer;

        NSDictionary *dictionary =
        @{
          @"description" : [value description],
          @"X" : @(point->x),
          @"Y" : @(point->y),
          };
        LPCoercion *coercion = [LPCoercion coercionWithValue:dictionary];
        free(buffer);
        return coercion;
      } else if ([LPInvoker isCGRectEncoding:encoding]) {
        CGRect *rect = (CGRect *) buffer;

        NSDictionary *dictionary =
        @{
          @"description" : [value description],
          @"X" : @(rect->origin.x),
          @"Y" : @(rect->origin.y),
          @"Width" : @(rect->size.width),
          @"Height" : @(rect->size.height)
          };

        LPCoercion *coercion = [LPCoercion coercionWithValue:dictionary];

        free(buffer);
        return coercion;
      } else if ([encoding isEqualToString:@"{?=dd}"]) {
        // The '?' in this context indicates "unknown type".
        // A concrete example this encoding is CLLocation2D

        double *doubles = (double *) buffer;
        double d1 = *doubles;
        doubles++;
        double d2 = *doubles;

        NSArray *array = @[@(d1), @(d2)];
        LPCoercion *coercion = [LPCoercion coercionWithValue:array];

        free(buffer);
        return coercion;
      } else {
        LPCoercion *coercion;

        // A struct or NSObject class e.g. {NSObject=#}
        NSArray *tokens = [encoding componentsSeparatedByString:@"="];
        if (tokens.count == 2) {
          NSString *name = [tokens[0] stringByReplacingOccurrencesOfString:@"{"
                                                                withString:@""];
          NSString *values = [tokens[1] stringByReplacingOccurrencesOfString:@"}"
                                                                  withString:@""];
          if ([values isEqualToString:@"#"]) {
            // {NSObject=#}
            coercion = [LPCoercion coercionWithValue:values];
          } else {
            // typedef struct Face Face;
            // struct Face {
            //  NSUInteger eyes;
            //  short nose;
            //  float mouthWidth;
            // };
            // Encoding => {Face=Isf}
            // Returns => @"{Face=Isf}
            coercion = [LPCoercion coercionWithValue:name];
          }
        } else {
          coercion = [LPCoercion coercionWithFailureMessage:LPCannotCoerceSelectorReturnValueToObject];
        }
        free(buffer);
        return coercion;
      }
      break;
    }

    default: {
      LPLogWarn(@"Unexpected type encoding: '%@'.", encoding);
    }
  }

  return [LPCoercion coercionWithFailureMessage:LPSelectorHasUnknownEncoding];
}

#pragma mark - Argument Encodings

+ (NSString *) encodingAtIndex:(NSUInteger) index
                     signature:(NSMethodSignature *) signature {
  const char *encodingC = [signature getArgumentTypeAtIndex:index];
  return [NSString stringWithCString:encodingC
                            encoding:NSASCIIStringEncoding];
}

+ (BOOL) canHandleArgumentEncoding:(NSString *) encoding {
  // @encode(void *) => ^v
  // @encode(float *) => ^f
  if ([encoding hasPrefix:@"^"]) { return NO; }

  // @encode(typeof(NSError **))
  if ([encoding isEqualToString:@"^@"]) { return NO; }

  // @encode(typeof(Union)) => (name=type...)
  if ([encoding hasPrefix:@"("]) { return NO; }

  // @encode(typeof(@selector(length))) => :
  if ([encoding isEqualToString:@":"]) { return NO; }

  // @encode(typeof(BitField) => bNUM
  if ([encoding hasPrefix:@"b"]) { return NO; }

  // int arr[5] = {1, 2, 3, 4, 5}; @encode(typeof(arr)) => [5i]
  // float arr[3] = {0.1f, 0.2f, 0.3f}; @encode(typeof(arr)) => [3f]
  if ([encoding hasPrefix:@"["]) { return NO; }

  // unknown - function pointers?
  if ([encoding isEqualToString:@"?"]) { return NO; }

  // A struct or NSObject class e.g. {NSObject=#}
  // We only handle CGRect and CGPoint encodings.
  // TODO: handle CLCoreLocation encoding @"{?=dd}"
  if ([encoding hasPrefix:@"{"]) {
    return
    [LPInvoker isCGRectEncoding:encoding] ||
    [LPInvoker isCGPointEncoding:encoding];
  }

  return YES;
}

- (BOOL) selectorHasArgumentWithUnhandledEncoding {
  if (![self selectorHasArguments]) {  return NO; }

  NSUInteger numberOfArguments = [self numberOfArguments];
  NSMethodSignature *signature = self.signature;

  for (NSUInteger index = 0; index < numberOfArguments; index++) {
    NSString *encoding = [LPInvoker encodingAtIndex:index + 2
                                          signature:signature];
    if (![LPInvoker canHandleArgumentEncoding:encoding]) {
      return YES;
    }
  }
  return NO;
}

@end
