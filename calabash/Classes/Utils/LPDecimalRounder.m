#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPDecimalRounder.h"

static NSRoundingMode const LPDecimalRounderMode = NSRoundPlain;
static NSUInteger const LPDecimalRounderDefaultScale = 2;

@interface LPDecimalRounder ()

- (NSDecimalNumberHandler *)handlerWithMode:(NSRoundingMode)mode
                                       scale:(NSUInteger)scale;
- (NSDecimalNumber *)roundDecimalNumber:(NSDecimalNumber *)decimal
                                handler:(NSDecimalNumberHandler *)handler;
- (CGFloat)cgFloatFromDecimalNumber:(NSDecimalNumber *)decimalNumber;
- (NSDecimalNumber *)decimalNumberFromCGFloat:(CGFloat)cgFloat;

@end

@implementation LPDecimalRounder

- (NSDecimalNumberHandler *)handlerWithMode:(NSRoundingMode)mode
                                      scale:(NSUInteger)scale {
  return [NSDecimalNumberHandler
          decimalNumberHandlerWithRoundingMode:mode
          scale:scale
          raiseOnExactness:YES
          raiseOnOverflow:YES
          raiseOnUnderflow:YES
          raiseOnDivideByZero:YES];
}

- (NSDecimalNumber *)roundDecimalNumber:(NSDecimalNumber *)decimalNumber
                                handler:(NSDecimalNumberHandler *)handler {
  return [decimalNumber decimalNumberByRoundingAccordingToBehavior:handler];
}

- (NSDecimalNumber *)decimalNumberFromCGFloat:(CGFloat)cgFloat {
#if CGFLOAT_IS_DOUBLE
  return [[NSDecimalNumber alloc] initWithDouble:cgFloat];
#else
  return [[NSDecimalNumber alloc] initWithFloat:cgFloat];
#endif
}

- (CGFloat)cgFloatFromDecimalNumber:(NSDecimalNumber *)decimalNumber {
#if CGFLOAT_IS_DOUBLE
  return (CGFloat)[decimalNumber doubleValue];
#else
  return (CGFloat)[decimalNumber floatValue];
#endif
}

- (CGFloat)round:(CGFloat)cgFloat {
  return [self round:cgFloat withScale:LPDecimalRounderDefaultScale];
}

- (CGFloat)round:(CGFloat)cgFloat withScale:(NSUInteger)scale {
  NSDecimalNumberHandler *handler;
  handler = [self handlerWithMode:LPDecimalRounderMode
                            scale:scale];

  NSDecimalNumber *decimal = [self decimalNumberFromCGFloat:cgFloat];

  NSDecimalNumber *rounded;
  rounded = [self roundDecimalNumber:decimal handler:handler];
  return [self cgFloatFromDecimalNumber:rounded];
}

@end
