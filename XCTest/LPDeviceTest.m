#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPDevice.h"

@interface LPDevice (LPXCTEST)

- (id) init_private;

@end

SpecBegin(LPDevice)

describe(@"LPDevice", ^{

  describe(@"init", ^{
    expect(^{
      LPDevice __unused *tmp = [[LPDevice alloc] init];
    }).to.raiseAny();
  });
});

SpecEnd
