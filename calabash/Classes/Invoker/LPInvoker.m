#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPInvoker.h"
#import "LPInvocationResult.h"
#import "LPInvocationError.h"
#import <objc/runtime.h>
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
- (LPInvocationResult *) resultByCoercingReturnValue;
+ (BOOL) isCGRectEncoding:(NSString *) encoding;
+ (BOOL) isCGPointEncoding:(NSString *) encoding;
+ (NSString *) encodingAtIndex:(NSUInteger) index
                     signature:(NSMethodSignature *) signature;
+ (BOOL) canHandleArgumentEncoding:(NSString *) encoding;
- (void) populateInvocationWithArguments:(NSArray *) arguments;
- (LPInvocationResult *) invokeAndCoerce;

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

+ (LPInvocationResult *) invokeOnMainThreadZeroArgumentSelector:(SEL) selector
                                                     withTarget:(id) target {
  if ([[NSThread currentThread] isMainThread]) {
    return [LPInvoker invokeZeroArgumentSelector:selector withTarget:target];
  } else {
    __block LPInvocationResult *result = [LPInvocationError unspecifiedInvocationError];
    dispatch_sync(dispatch_get_main_queue(), ^{
      result = [LPInvoker invokeZeroArgumentSelector:selector withTarget:target];
    });
    return result;
  }
}

+ (LPInvocationResult *) invokeOnMainThreadSelector:(SEL) selector
                                         withTarget:(id) target
                                          arguments:(NSArray *) arguments {
  if ([[NSThread currentThread] isMainThread]) {
    return [LPInvoker invokeSelector:selector
                          withTarget:target
                           arguments:arguments];
  } else {
    __block LPInvocationResult *result = [LPInvocationError unspecifiedInvocationError];
    dispatch_sync(dispatch_get_main_queue(), ^{
      result = [LPInvoker invokeSelector:selector
                              withTarget:target
                               arguments:arguments];
    });
    return result;
  }
}

+ (LPInvocationResult *) invokeZeroArgumentSelector:(SEL) selector
                                         withTarget:(id) target {
  LPInvoker *invoker = [[LPInvoker alloc] initWithSelector:selector
                                                    target:target];

  if (![invoker targetRespondsToSelector]) {
    LPLogWarn(@"Target '%@' does not respond to selector '%@'",
              [invoker.target class], NSStringFromSelector(invoker.selector));

    return [LPInvocationError targetDoesNotRespondToSelector];
  }

  if ([invoker selectorHasArguments]) {
    LPLogWarn(@"Selector '%@' on target '%@' requires %@ arguments but was provided with none.",
              NSStringFromSelector(invoker.selector),
              [invoker.target class],
              @([invoker numberOfArguments]));
    return [LPInvocationError incorectNumberOfArgumentsProvided];
  }

  if ([invoker selectorReturnTypeEncodingIsUnhandled]) {
    LPLogWarn(@"Return type encoding '%@' for selector '%@' on target '%@' is unhandled.",
              [invoker encodingForSelectorReturnType],
              NSStringFromSelector(invoker.selector),
              [invoker.target class]);
    return [LPInvocationError cannotCoerceReturnValueToObject];
  }

  // Always returns an object.
  return [invoker invokeAndCoerce];
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

  // 'r' means constant.
  // @encode(typeof(const char *)) => "r*"
  if ([encoding hasPrefix:@"r"]) {
    return ![encoding isEqualToString:@"r*"];
  }

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

- (LPInvocationResult *) resultByCoercingReturnValue {
  NSString *encoding = self.encodingForSelectorReturnType;
  SEL selector = self.selector;
  id target = self.target;

  if (![self targetRespondsToSelector]) {
    return [LPInvocationError targetDoesNotRespondToSelector];
  }

  if (![self selectorReturnValueCanBeCoerced]) {
    return [LPInvocationError cannotCoerceReturnValueToObject];
  }

  // Guard against invalid access when asking for encoding[0]
  if (!encoding.length >= 1) {
    LPLogError(@"Selector '%@' on '%@' has an invalid encoding; '%@' must have at least one character.",
               NSStringFromSelector(selector), target, encoding);
    return [LPInvocationError hasUnknownReturnTypeEncoding];
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
    return [LPInvocationResult resultWithValue:@(ref)];
  }

  char char_encoding = [encoding cStringUsingEncoding:NSASCIIStringEncoding][0];
  switch (char_encoding) {

    case '*' : {
      char *ref;
      [invocation getReturnValue:(void **) &ref];
      return [LPInvocationResult resultWithValue:@(ref)];
    }

      // BOOL is explicitly signed so @encode(BOOL) == "c" rather than "C"
      // even if -funsigned-char is used.
    case 'c' : {
      char ref;
      [invocation getReturnValue:(void **) &ref];
      if (ref == (BOOL)1) {
        return [LPInvocationResult resultWithValue:@(YES)];
      } else if (ref == (BOOL)0) {
        return [LPInvocationResult resultWithValue:@(NO)];
      } else {
        NSString *value = [NSString stringWithFormat:@"%c", (char) ref];
        return [LPInvocationResult resultWithValue:value];
      }
    }

    case 'C' : {
      unsigned char ref;
      [invocation getReturnValue:(void **) &ref];
      NSString *value = [NSString stringWithFormat:@"%c", (char) ref];
      return [LPInvocationResult resultWithValue:value];
    }

      // See note above for 'c'.
    case 'B': {
      bool ref;
      [invocation getReturnValue:(void **) &ref];
      if (ref == true) {
        return [LPInvocationResult resultWithValue:@(YES)];
      } else {
        return [LPInvocationResult resultWithValue:@(NO)];
      }
    }

    case 'i': {
      int ref;
      [invocation getReturnValue:(void **) &ref];
      return [LPInvocationResult resultWithValue:@((int) ref)];
    }

    case 'I': {
      unsigned int ref;
      [invocation getReturnValue:(void **) &ref];
      return [LPInvocationResult resultWithValue:@((unsigned int) ref)];
    }

    case 's': {
      short ref;
      [invocation getReturnValue:(void **) &ref];
      return [LPInvocationResult resultWithValue:@((short) ref)];
    }

    case 'S': {
      unsigned short ref;
      [invocation getReturnValue:(void **) &ref];
      return [LPInvocationResult resultWithValue:@((unsigned short) ref)];
    }

    case 'd' : {
      double ref;
      [invocation getReturnValue:(void **) &ref];
      return [LPInvocationResult resultWithValue:@((double) ref)];
    }

    case 'f' : {
      float ref;
      [invocation getReturnValue:(void **) &ref];
      return [LPInvocationResult resultWithValue:@((float) ref)];
    }

    case 'l' : {
      long ref;
      [invocation getReturnValue:(void **) &ref];
      return [LPInvocationResult resultWithValue:@((long) ref)];
    }

    case 'L' : {
      unsigned long ref;
      [invocation getReturnValue:(void **) &ref];
      return [LPInvocationResult resultWithValue:@((unsigned long) ref)];
    }

    case 'q' : {
      long long ref;
      [invocation getReturnValue:(void **) &ref];
      return [LPInvocationResult resultWithValue:@((long long) ref)];
    }

    case 'Q' : {
      unsigned long long ref;
      [invocation getReturnValue:(void **) &ref];
      return [LPInvocationResult resultWithValue:@((unsigned long long) ref)];
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
      return [LPInvocationResult resultWithValue:name];
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

        LPInvocationResult *result = [LPInvocationResult resultWithValue:dictionary];

        free(buffer);

        return result;
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

        LPInvocationResult *result = [LPInvocationResult resultWithValue:dictionary];

        free(buffer);
        return result;
      } else if ([encoding isEqualToString:@"{?=dd}"]) {
        // The '?' in this context indicates "unknown type".
        // A concrete example this encoding is CLLocation2D

        double *doubles = (double *) buffer;
        double d1 = *doubles;
        doubles++;
        double d2 = *doubles;

        NSArray *array = @[@(d1), @(d2)];
        LPInvocationResult *result = [LPInvocationResult resultWithValue:array];

        free(buffer);
        return result;
      } else {
        LPInvocationResult *result;

        // A struct or NSObject class e.g. {NSObject=#}
        NSArray *tokens = [encoding componentsSeparatedByString:@"="];
        if (tokens.count == 2) {
          NSString *name = [tokens[0] stringByReplacingOccurrencesOfString:@"{"
                                                                withString:@""];
          NSString *values = [tokens[1] stringByReplacingOccurrencesOfString:@"}"
                                                                  withString:@""];
          if ([values isEqualToString:@"#"]) {
            // {NSObject=#} - return the '#'
            result = [LPInvocationResult resultWithValue:@"#"];
          } else {
            // typedef struct Face Face;
            // struct Face {
            //  NSUInteger eyes;
            //  short nose;
            //  float mouthWidth;
            // };
            // Encoding => {Face=Isf}
            // Returns => @"{Face=Isf}
            result = [LPInvocationResult resultWithValue:name];
          }
        } else {
          result = [LPInvocationError cannotCoerceReturnValueToObject];
        }

        free(buffer);
        return result;
      }
      break;
    }

    default: {
      LPLogWarn(@"Unexpected type encoding: '%@'.", encoding);
    }
  }

  return [LPInvocationError hasUnknownReturnTypeEncoding];
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

  // 'r' means constant
  // @encode(typeof(const char *))
  if ([encoding hasPrefix:@"r"]) {
    // 'const char *' is supported, but nothing else is
    return [encoding isEqualToString:@"r*"];
  }

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

- (BOOL) selectorArgumentCountMatchesArgumentsCount:(NSArray *) arguments {
  NSUInteger numberOfArguments = [self numberOfArguments];
  return numberOfArguments == arguments.count;
}

+ (LPInvocationResult *) invokeSelector:(SEL) selector
                             withTarget:(id) receiver
                              arguments:(NSArray *) arguments {

  LPInvoker *invoker = [[LPInvoker alloc] initWithSelector:selector
                                                    target:receiver];

  if (![invoker targetRespondsToSelector]) {
    LPLogWarn(@"Target '%@' does not respond to selector '%@'",
              [invoker.target class], NSStringFromSelector(invoker.selector));

    return [LPInvocationError targetDoesNotRespondToSelector];
  }

  if (![invoker selectorArgumentCountMatchesArgumentsCount:arguments]) {
    LPLogWarn(@"Selector '%@' on target '%@' requires %@ arguments but was provided with %@.",
              NSStringFromSelector(invoker.selector),
              [invoker.target class],
              @([invoker numberOfArguments]),
              @(arguments.count));
    return [LPInvocationError incorectNumberOfArgumentsProvided];
  }

  if ([invoker selectorReturnTypeEncodingIsUnhandled]) {
    LPLogWarn(@"Return type encoding '%@' for selector '%@' on target '%@' is unhandled.",
              [invoker encodingForSelectorReturnType],
              NSStringFromSelector(invoker.selector),
              [invoker.target class]);
    return [LPInvocationError cannotCoerceReturnValueToObject];
  }

  if ([invoker selectorHasArgumentWithUnhandledEncoding]) {
    LPLogWarn(@"Selector '%@' on target '%@' has at least one argument with an encoding that is not handled",
              NSStringFromSelector(invoker.selector),
              [invoker.target class]);
    return [LPInvocationError hasAnArgumentTypeEncodingThatCannotBeHandled];
  }

  @try {
    [invoker populateInvocationWithArguments:arguments];
  } @catch (NSException *exception) {
    LPLogError(@"Could not populate the arguments of the invocation.");
    LPLogError(@"  target  => %@", [receiver class]);
    LPLogError(@"selector  => %@", NSStringFromSelector(selector));
    LPLogError(@"arguments => %@", arguments);
    return [LPInvocationError hasAnArgumentTypeEncodingThatCannotBeHandled];
  }

  return [invoker invokeAndCoerce];
}

- (void) populateInvocationWithArguments:(NSArray *) arguments {

  NSUInteger numberOfArguments = [self numberOfArguments];
  NSMethodSignature *signature = self.signature;
  NSInvocation *invocation = self.invocation;

  for (NSUInteger index = 0; index < numberOfArguments; index++) {
    id argument = arguments[index];
    NSUInteger invocationArgIndex = index + 2;

    NSString *encoding = [LPInvoker encodingAtIndex:invocationArgIndex
                                          signature:signature];
    char char_encoding = [encoding cStringUsingEncoding:NSASCIIStringEncoding][0];

    switch (char_encoding) {

      case '@': {
        if ([argument isEqual:@"__self__"]) {
          argument = self.target;
        } else if ([argument isEqualToString:@"__nil__"]) {
          argument = nil;
        }
        [invocation setArgument:&argument atIndex:invocationArgIndex];
        break;
      }

      case 'i': {
        NSInteger intVal = [argument integerValue];
        [invocation setArgument:&intVal atIndex:invocationArgIndex];
        break;
      }

      case 'I': {
        NSInteger uIntVal = [argument unsignedIntegerValue];
        [invocation setArgument:&uIntVal atIndex:invocationArgIndex];
        break;
      }
      case 's': {
        short shVal = [argument shortValue];
        [invocation setArgument:&shVal atIndex:invocationArgIndex];
        break;
      }

      case 'd': {
        double dbVal = [argument doubleValue];
        [invocation setArgument:&dbVal atIndex:invocationArgIndex];
        break;
      }

      case 'D': {
        // http://stackoverflow.com/questions/6488956/store-nsnumber-in-a-long-double-type
        // There is no Objective-C support for encoding a long double as a object
        LPLogInfo(@"Handling an argument with encoding long double!");
        long double longDouble = (long double)[argument doubleValue];
        [invocation setArgument:&longDouble atIndex:invocationArgIndex];
        break;
      }

      case 'f': {
        float fltVal = [argument floatValue];
        [invocation setArgument:&fltVal atIndex:invocationArgIndex];
        break;
      }

      case 'l': {
        long lngVal = [argument longValue];
        [invocation setArgument:&lngVal atIndex:invocationArgIndex];
        break;
      }

        // Fall through!
      case 'r':
      case '*': {
        // 'char *' and 'const char *'
        if (![encoding isEqualToString:@"r*"] && ![encoding isEqualToString:@"*"]) {
          NSString *name = @"Argument encoding";
          NSString *reason;
          reason =
          [NSString stringWithFormat:@"Unhandled encoding '%@'", encoding];

          LPLogError(@"%@", reason);
          @throw [NSException exceptionWithName:name
                                         reason:reason
                                       userInfo:nil];
        }

        const char *cstringValue = [argument cStringUsingEncoding:NSUTF8StringEncoding];
        [invocation setArgument:&cstringValue atIndex:invocationArgIndex];
        break;
      }

      case 'C' : {
        unichar chVal;
        if ([argument respondsToSelector:@selector(unsignedCharValue)]) {
          chVal = [argument unsignedCharValue];
        } else if ([argument respondsToSelector:@selector(characterAtIndex:)]) {
          chVal = [argument characterAtIndex:0];
        } else {
          NSString *name = @"Argument encoding";
          NSString *reason;
          reason =
          [NSString stringWithFormat:@"Cannot coerce '%@' of class '%@' into a unichar",
           argument, [argument class]];

          LPLogError(@"%@", reason);
          @throw [NSException exceptionWithName:name
                                         reason:reason
                                       userInfo:nil];
        }

        [invocation setArgument:&chVal atIndex:invocationArgIndex];
        break;
      }

      case 'c': {
        char chVal;
        if ([argument respondsToSelector:@selector(charValue)]) {
          chVal = [argument charValue];
        } else if ([argument respondsToSelector:@selector(characterAtIndex:)]) {
          chVal = (char)[argument characterAtIndex:0];
        } else {
          NSString *name = @"Argument encoding";
          NSString *reason;
          reason =
          [NSString stringWithFormat:@"Cannot coerce '%@' of class '%@' into a char",
           argument, [argument class]];

          LPLogError(@"%@", reason);
          @throw [NSException exceptionWithName:name
                                         reason:reason
                                       userInfo:nil];
        }

        [invocation setArgument:&chVal atIndex:invocationArgIndex];
        break;
      }

      case 'S': {
        unsigned short SValue;
        if ([argument respondsToSelector:@selector(unsignedShortValue)]) {
          SValue = [argument unsignedShortValue];
        } else if ([argument respondsToSelector:@selector(characterAtIndex:)]) {
          SValue = (unsigned short)[argument characterAtIndex:0];
        } else {

          NSString *name = @"Argument encoding";
          NSString *reason;
          reason =
          [NSString stringWithFormat:@"Cannot coerce '%@' of class '%@' into an unsiged short",
           argument, [argument class]];

          LPLogError(@"%@", reason);
          @throw [NSException exceptionWithName:name
                                         reason:reason
                                       userInfo:nil];
        }

        [invocation setArgument:&SValue atIndex:invocationArgIndex];
        break;
      }

      case 'B': {
        _Bool Bvalue = [argument boolValue];
        [invocation setArgument:&Bvalue atIndex:invocationArgIndex];
        break;
      }

      case 'Q': {
        unsigned long long Qvalue = [argument unsignedLongLongValue];
        [invocation setArgument:&Qvalue atIndex:invocationArgIndex];
        break;
      }

      case 'q': {
        long long qvalue = [argument longLongValue];
        [invocation setArgument:&qvalue atIndex:invocationArgIndex];
        break;
      }

      case 'L': {
        unsigned long Lvalue = [argument unsignedLongValue];
        [invocation setArgument:&Lvalue atIndex:invocationArgIndex];
        break;
      }

      case '#': {
        Class klass = nil;
        if ([argument isKindOfClass:[NSString class]]) {
          klass = NSClassFromString(argument);
        } else if (class_isMetaClass(object_getClass(argument))) {
          klass = argument;
        } else {
          NSString *name = @"Argument encoding";
          NSString *reason;
          reason =
          [NSString stringWithFormat:@"Cannot coerce '%@' of class '%@' into Class",
           argument, [argument class]];

          LPLogError(@"%@", reason);
          @throw [NSException exceptionWithName:name
                                         reason:reason
                                       userInfo:nil];

        }
        [invocation setArgument:&klass atIndex:invocationArgIndex];
        break;
      }

      case '{': {
        BOOL isPointEncoding = [LPInvoker isCGPointEncoding:encoding];
        BOOL isRectEncoding = [LPInvoker isCGRectEncoding:encoding];
        BOOL argumentIsDictionary = [argument isKindOfClass:[NSDictionary class]];

        if ((isPointEncoding || isRectEncoding) && !argumentIsDictionary) {
          NSString *name = @"Argument encoding";
          NSString *reason;
          if (isPointEncoding) {
            reason =
            [NSString stringWithFormat:@"Cannot coerce '%@' of class '%@' into CGPoint",
             argument, [argument class]];
          } else {
            reason =
            [NSString stringWithFormat:@"Cannot coerce '%@' of class '%@' into CGRect",
             argument, [argument class]];
          }
          LPLogError(@"%@", reason);
          @throw [NSException exceptionWithName:name
                                         reason:reason
                                       userInfo:nil];
        }

        if (isPointEncoding) {
          CGPoint point = [self pointFromDictonary:argument];
          [invocation setArgument:&point atIndex:invocationArgIndex];
          break;
        } else if (isRectEncoding) {
          CGRect rect = [self rectFromDictionary:argument];
          [invocation setArgument:&rect atIndex:invocationArgIndex];
          break;
        } else {
          // TODO: Can we support the '{?=dd}' encoding?
          NSString *name = @"Unsupported argument encoding";
          NSString *reason;
          reason = [NSString stringWithFormat:@"Encoding for '%@' struct  is not supported.",
                    encoding];
          LPLogError(@"%@", reason);
          @throw [NSException exceptionWithName:name
                                         reason:reason
                                       userInfo:nil];
        }
      }
    }

    [invocation retainArguments];
  }
}

#pragma mark - Invoke and Coerce

- (LPInvocationResult *) invokeAndCoerce {
  if ([self selectorReturnsObject]) {
    NSInvocation *invocation = self.invocation;

    id invocationResult = nil;
    LPInvocationResult *result = nil;
    @try {
      void *buffer;
      [invocation invoke];
      [invocation getReturnValue:&buffer];
      invocationResult = (__bridge id)buffer;
      result = [LPInvocationResult resultWithValue:invocationResult];
    } @catch (NSException *exception) {
      LPLogError(@"LPInvoker caught an exception: %@", exception);
      LPLogError(@"=== INVOCATION DETAILS ===");
      LPLogError(@"target class = %@", [self.target class]);
      LPLogError(@"selector = %@", NSStringFromSelector(self.selector));
      result = [LPInvocationError invokingSelectorOnTargetRaisedAnException];
    }

    return result;
  }

  if ([self selectorReturnsVoid]) {
    NSInvocation *invocation = self.invocation;

    LPInvocationResult *result = nil;
    @try {
      [invocation invoke];
      result = [LPInvocationResult resultWithValue:LPVoidSelectorReturnValue];
    } @catch (NSException *exception) {
      LPLogError(@"LPInvoker caught an exception: %@", exception);
      LPLogError(@"=== INVOCATION DETAILS ===");
      LPLogError(@"target class = %@", [self.target class]);
      LPLogError(@"selector = %@", NSStringFromSelector(self.selector));
      result = [LPInvocationError invokingSelectorOnTargetRaisedAnException];
    }
    return result;
  }

  if ([self selectorReturnValueCanBeCoerced]) {
    return [self resultByCoercingReturnValue];
  }

  return [LPInvocationError unspecifiedInvocationError];
}

#pragma mark - Convert Dictionaries to CGPoint and CGRect

- (CGPoint) pointFromDictonary:(NSDictionary *) dictionary {
  if ((dictionary[@"x"] || dictionary[@"X"]) &&
      (dictionary[@"y"] || dictionary[@"Y"])) {
    NSNumber *x = dictionary[@"x"];
    if (!x) { x = dictionary[@"X"]; }

    NSNumber *y = dictionary[@"y"];
    if (!y) { y = dictionary[@"Y"]; }

    CGPoint point;
#if CGFLOAT_IS_DOUBLE
    point = CGPointMake([x doubleValue], [y doubleValue]);
#else
    point = CGPointMake([x floatValue], [y floatValue]);
#endif
    return point;
  } else {
    CGPoint point;
    CGPointMakeWithDictionaryRepresentation((CFDictionaryRef)dictionary, &point);
    return point;
  }
}

- (CGRect) rectFromDictionary:(NSDictionary *) dictionary {
  if ((dictionary[@"x"] || dictionary[@"X"]) &&
      (dictionary[@"y"] || dictionary[@"Y"]) &&
      (dictionary[@"width"] || dictionary[@"Width"]) &&
      (dictionary[@"height"] || dictionary[@"Height"])) {
    NSNumber *x = dictionary[@"x"];
    if (!x) { x = dictionary[@"X"]; }

    NSNumber *y = dictionary[@"y"];
    if (!y) { y = dictionary[@"Y"]; }

    NSNumber *width = dictionary[@"width"];
    if (!width) { width = dictionary[@"Width"]; }

    NSNumber *height = dictionary[@"height"];
    if (!height) { height = dictionary[@"Height"]; }

    CGRect rect;
#if CGFLOAT_IS_DOUBLE
    rect = CGRectMake([x doubleValue], [y doubleValue],
                      [width doubleValue], [height doubleValue]);
#else
    rect = CGRectMake([x floatValue], [y floatValue],
                      [width floatValue], [height floatValue]);
#endif
    return rect;
  } else {
    CGRect rect;
    CGRectMakeWithDictionaryRepresentation((CFDictionaryRef)dictionary, &rect);
    return rect;
  }
}

@end
