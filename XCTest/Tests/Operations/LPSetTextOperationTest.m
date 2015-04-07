#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPSetTextOperation.h"

SpecBegin(LPSetTextOperation)

describe(@"LPSetTextOperation", ^{

  describe(@"performWithTarget:error:", ^{
    describe(@"target represents a WebView; it is a dictionary", ^{

      describe(@"dict has invalid keys", ^{

      });

      describe(@"dict has valid keys", ^{

      });
    });

    describe(@"target responds to setText", ^{

    });

    it(@"target does not respond to setText", ^{
      UISlider *slider = [[UISlider alloc] initWithFrame:CGRectZero];
      LPSetTextOperation *op = [[LPSetTextOperation alloc] init];
      expect([op performWithTarget:slider error:nil]).to.equal(nil);
    });
  });
});
SpecEnd
