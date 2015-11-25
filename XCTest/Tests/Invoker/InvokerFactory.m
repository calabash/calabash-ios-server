#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "InvokerFactory.h"
#import "LPInvoker.h"

@interface InvokerFactory ()

@property(strong, nonatomic, readonly) NSDictionary *selectorForReturnTypeMap;
@property(strong, nonatomic, readonly) NSDictionary *selectorForArgTypeMap;

- (id) init_private;
- (Target *) instance_targetWithSelectorReturnValue:(NSString *) key;
- (LPInvoker *) instance_invokerWithSelectorReturnValue:(NSString *) key;
- (LPInvoker *) instance_invokerWithArgmentValue:(NSString *) key;

@end

@implementation InvokerFactory

@synthesize selectorForReturnTypeMap = _selectorForReturnTypeMap;
@synthesize selectorForArgTypeMap = _selectorForArgTypeMap;

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

- (NSDictionary *) selectorForReturnTypeMap {
  if (_selectorForReturnTypeMap) { return _selectorForReturnTypeMap; }

  _selectorForReturnTypeMap =
  @{
    // Handled
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
    @"CGPoint" : NSStringFromSelector(@selector(selectorThatReturnsCGPoint)),
    @"CGRect" : NSStringFromSelector(@selector(selectorThatReturnsCGRect)),
    @"struct" : NSStringFromSelector(@selector(selectorThatReturnsAStruct)),
    @"Class" : NSStringFromSelector(@selector(selectorThatReturnsClass)),
    @"Location2D" : NSStringFromSelector(@selector(selectorThatReturnsCoreLocation2D)),
    @"void raises" : NSStringFromSelector(@selector(selectorThatReturnsVoidAndRaises)),
    @"pointer raises" : NSStringFromSelector(@selector(selectorThatReturnsPointerAndRaises)),

    // Not handled
    @"void *" : NSStringFromSelector(@selector(selectorThatReturnsVoidStar))
    };

  return _selectorForReturnTypeMap;
}

- (NSDictionary *) selectorForArgTypeMap {
  if (_selectorForArgTypeMap) { return _selectorForArgTypeMap; }

  _selectorForArgTypeMap =
  @{

    // Handled
    @"BOOL YES" : NSStringFromSelector(@selector(selectorBOOL_YES:)),
    @"BOOL NO" : NSStringFromSelector(@selector(selectorBOOL_NO:)),
    @"bool true" : NSStringFromSelector(@selector(selectorBool_true:)),
    @"bool false" : NSStringFromSelector(@selector(selectorBool_false:)),
    @"NSInteger" : NSStringFromSelector(@selector(selectorNSInteger:)),
    @"NSUInteger" : NSStringFromSelector(@selector(selectorNSUInteger:)),
    @"short" : NSStringFromSelector(@selector(selectorShort:)),
    @"unsigned short" : NSStringFromSelector(@selector(selectorUnsignedShort:)),
    @"CGFloat" : NSStringFromSelector(@selector(selectorCGFloat:)),
    @"double" : NSStringFromSelector(@selector(selectorDouble:)),
    @"float" : NSStringFromSelector(@selector(selectorFloat:)),
    @"char" : NSStringFromSelector(@selector(selectorChar:)),
    @"char *" : NSStringFromSelector(@selector(selectorCharStar:)),
    @"const char *" : NSStringFromSelector(@selector(selectorConstCharStar:)),
    @"unsigned char" : NSStringFromSelector(@selector(selectorUnsignedChar:)),
    @"long" : NSStringFromSelector(@selector(selectorLong:)),
    @"unsigned long" : NSStringFromSelector(@selector(selectorUnsignedLong:)),
    @"long long" : NSStringFromSelector(@selector(selectorLongLong:)),
    @"unsigned long long" : NSStringFromSelector(@selector(selectorUnsignedLongLong:)),
    @"CGPoint" : NSStringFromSelector(@selector(selectorCGPoint:)),
    @"CGRect" : NSStringFromSelector(@selector(selectorCGRect:)),
    @"Class" : NSStringFromSelector(@selector(selectorClass:)),
    @"object pointer" : NSStringFromSelector(@selector(selectorObjectPointer:)),
    @"self" : NSStringFromSelector(@selector(selectorArgumentIsSelf:)),
    @"self" : NSStringFromSelector(@selector(selectorArgumentIsNil:)),

    // Not handled
    @"void *" : NSStringFromSelector(@selector(selectorVoidStar:)),
    @"float *" : NSStringFromSelector(@selector(selectorFloatStar:)),
    @"NSError **" : NSStringFromSelector(@selector(selectorObjectStarStar:)),
    @"SEL" : NSStringFromSelector(@selector(selectorSelector:)),
    @"int []" : NSStringFromSelector(@selector(selectorPrimativeArray:)),
    @"struct" : NSStringFromSelector(@selector(selectorStruct:))

    };

  return _selectorForArgTypeMap;
}

+ (Target *) targetWithSelectorReturnValue:(NSString *) key {
  InvokerFactory *factory = [InvokerFactory shared];
  return [factory instance_targetWithSelectorReturnValue:key];
}

- (Target *) instance_targetWithSelectorReturnValue:(NSString *) key {
  NSDictionary *map = self.selectorForReturnTypeMap;
  NSString *selector = [map objectForKey:key];
  if (!selector) {
    NSString *reason = [NSString stringWithFormat:@"Key '%@' is not one of '%@'",
                        key, [map allKeys]];
    @throw [NSException exceptionWithName:@"LPNoObjectForKey"
                                   reason:reason
                                 userInfo:nil];
  }

  Target *target = [Target new];
  target.selector = NSSelectorFromString(selector);
  return target;
}

+ (SEL) selectorForArgumentType:(NSString *) key {
  InvokerFactory *factory = [InvokerFactory shared];
  NSDictionary *map = factory.selectorForArgTypeMap;
  NSString *selector = [map objectForKey:key];
  if (!selector) {
    NSString *reason = [NSString stringWithFormat:@"Key '%@' is not one of '%@'",
                        key, [map allKeys]];
    @throw [NSException exceptionWithName:@"LPNoObjectForKey"
                                   reason:reason
                                 userInfo:nil];
  }
  return NSSelectorFromString(selector);
}

#pragma mark - Testing Return Types

+ (LPInvoker *) invokerWithSelectorReturnValue:(NSString *) key {
  InvokerFactory *factory = [InvokerFactory shared];
  return [factory instance_invokerWithSelectorReturnValue:key];
}

- (LPInvoker *) instance_invokerWithSelectorReturnValue:(NSString *) key {
  Target *target = [self instance_targetWithSelectorReturnValue:key];
  return [[LPInvoker alloc] initWithSelector:target.selector
                                      target:target];
}

#pragma mark - Testing Argument Types

+ (LPInvoker *) invokerWithArgmentValue:(NSString *) key {
  InvokerFactory *factory = [InvokerFactory shared];
  return [factory instance_invokerWithArgmentValue:key];
}

- (LPInvoker *) instance_invokerWithArgmentValue:(NSString *) key {
  NSDictionary *map = self.selectorForArgTypeMap;

  NSString *selector = [map objectForKey:key];
  if (!selector) {
    NSString *reason = [NSString stringWithFormat:@"Key '%@' is not one of '%@'",
                        key, [map allKeys]];
    @throw [NSException exceptionWithName:@"LPNoObjectForKey"
                                   reason:reason
                                 userInfo:nil];
  }

  Target *target = [Target new];
  target.selector = NSSelectorFromString(selector);
  return [[LPInvoker alloc] initWithSelector:target.selector target:target];
}


@end

@implementation Target

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

// Handled

- (void) selectorThatReturnsVoid { return; }
- (void) selectorThatReturnsVoidAndRaises {
  @throw [NSException exceptionWithName:@"Exceptional"
                                 reason:@"Just because"
                               userInfo:nil];
}
- (id) selectorThatReturnsPointerAndRaises {
  @throw [NSException exceptionWithName:@"Exceptional"
                                 reason:@"Just because"
                               userInfo:nil];
}
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
- (CGPoint) selectorThatReturnsCGPoint { return CGPointMake(17, 42); }
- (CGRect) selectorThatReturnsCGRect { return CGRectMake(17, 42, 11, 13); }
- (InvokerFactoryStruct) selectorThatReturnsAStruct {
  InvokerFactoryStruct factoryStruct;
  factoryStruct.pillar = 1;
  return factoryStruct;
}
- (Class) selectorThatReturnsClass { return [NSArray class]; }
- (CLLocationCoordinate2D) selectorThatReturnsCoreLocation2D {
  return CLLocationCoordinate2DMake((CLLocationDegrees)56.17216,
                                    (CLLocationDegrees)10.18754);
}

// Not handled
- (void *) selectorThatReturnsVoidStar {
  void *buffer = malloc(8);
  return buffer;
}


#pragma mark - Handled Argument Types

- (BOOL) selectorBOOL_YES:(BOOL) arg {
  return arg == YES;
}

- (BOOL) selectorBOOL_NO:(BOOL) arg {
  return arg == NO;
}

- (BOOL) selectorBool_true:(bool) arg {
  return arg == true;
}

- (BOOL) selectorBool_false:(bool) arg {
  return arg == false;
}

- (BOOL) selectorNSInteger:(NSInteger) arg {
  return arg == NSIntegerMin;
}

- (BOOL) selectorNSUInteger:(NSUInteger) arg {
  return arg == NSNotFound;
}

- (BOOL) selectorShort:(short) arg {
  return arg == SHRT_MIN;
}

- (BOOL) selectorUnsignedShort:(unsigned short) arg {
  return arg == USHRT_MAX;
}

- (BOOL) selectorCGFloat:(CGFloat) arg {
  return arg == CGFLOAT_MAX;
}

- (BOOL) selectorDouble:(double) arg {
  return arg == DBL_MAX;
}

- (BOOL) selectorFloat:(float) arg {
  return arg == FLT_MAX;
}

- (BOOL) selectorChar:(char) arg {
  return arg == CHAR_MIN;
}

- (BOOL) selectorCharStar:(char *) arg {
  NSString *argObjC = [NSString stringWithCString:(const char *)arg
                                        encoding:NSASCIIStringEncoding];
  return [argObjC isEqualToString:@"char *"];
}

- (BOOL) selectorConstCharStar:(const char *) arg {
  NSString *argObjC = [NSString stringWithCString:arg
                                         encoding:NSASCIIStringEncoding];
  return [argObjC isEqualToString:@"const char *"];
}

- (BOOL) selectorUnsignedChar:(unsigned char) arg {
  return arg == UCHAR_MAX;
}

- (BOOL) selectorLong:(long) arg {
  return arg == LONG_MIN;
}

- (BOOL) selectorUnsignedLong:(unsigned long) arg {
  return arg == ULONG_MAX;
}

- (BOOL) selectorLongLong:(long long) arg {
  return arg == LONG_LONG_MIN;
}

- (BOOL) selectorUnsignedLongLong:(unsigned long long) arg {
  return arg == ULONG_LONG_MAX;
}

- (BOOL) selectorCGPoint:(CGPoint) arg {
  return arg.x == 1 && arg.y == 2;
}

- (BOOL) selectorCGRect:(CGRect) arg {
  return arg.origin.x == 1 && arg.origin.y == 2 && arg.size.width == 3 && arg.size.height == 4;
}

- (BOOL) selectorClass:(Class) arg {
  NSString *arrayClassName = NSStringFromClass([NSArray class]);
  NSString *argClassname = NSStringFromClass(arg);
  return [arrayClassName isEqualToString:argClassname];
}

- (BOOL) selectorObjectPointer:(id) arg {
  return arg == [InvokerFactory shared];
}

- (BOOL) selectorArgumentIsSelf:(id) arg {
  return arg == self;
}

- (BOOL) selectorArgumentIsNil:(id) arg {
  return arg == nil;
}

#pragma mark - Unhandled Argument Types

- (void) selectorVoidStar:(void *) arg { };
- (void) selectorFloatStar:(float *) arg { };
- (BOOL) selectorObjectStarStar:(NSError *__autoreleasing*) arg { return NO; }
- (void) selectorSelector:(SEL) arg { }
- (void) selectorPrimativeArray:(int []) arg { }
- (void) selectorStruct:(InvokerFactoryStruct) arg { }

@end
