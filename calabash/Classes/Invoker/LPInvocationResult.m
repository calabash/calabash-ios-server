#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPInvocationResult.h"

NSString *const LPVoidSelectorReturnValue = @"<VOID>";

@implementation LPInvocationResult

- (BOOL) isError { return NO; }

@end
