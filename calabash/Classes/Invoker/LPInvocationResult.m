#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPInvocationResult.h"

NSString *const LPVoidSelectorReturnValue = @"<VOID>";

@implementation LPInvocationResult

#pragma mark - Memory Management

@synthesize value = _value;

+ (LPInvocationResult *) resultWithValue:(id) value {
  return [[LPInvocationResult alloc] initWithValue:value];
}

- (id) initWithValue:(id) value {
  self = [super init];
  if (self) {
    if (value) {
      _value = value;
    } else {
      _value = [NSNull null];
    }
  }
  return self;
}

- (BOOL) isError { return NO; }

- (BOOL) isNSNull { return self.value == [NSNull null]; }

- (NSString *) description {
  NSString *className = NSStringFromClass([LPInvocationResult class]);
  if ([self isNSNull]) {
    return [NSString stringWithFormat:@"#<%@ : NSNull>", className];
  } else {
    return [NSString stringWithFormat:@"#<%@ : '%@'>", className, self.value];
  }
}

@end
