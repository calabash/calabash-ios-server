#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPInvoker.h"

NSString *const LPReceiverDoesNotRespondToSelectorEncoding = @"*****";

@interface LPInvoker ()

@property(strong, nonatomic, readonly) NSString *encoding;

@end

@implementation LPInvoker

@synthesize encoding = _encoding;

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
  }
  return self;
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

@end
