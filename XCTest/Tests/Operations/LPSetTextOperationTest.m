#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPSetTextOperation.h"

@interface LPSetTextOperation (LPXCTEST)

- (NSArray *) arguments;

@end

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

      __block LPSetTextOperation *operation;
      __block NSDictionary *dictionary;
      __block UITextField *textField;

      before(^{
        textField = [[UITextField alloc] initWithFrame:CGRectZero];
      });

      describe(@"has correct arguments", ^{
        it(@"argument is an NSString", ^{
          dictionary = @{@"method_name" : @"setText",
                         @"arguments": @[@"new text"]};
          operation = [[LPSetTextOperation alloc] initWithOperation:dictionary];
          id result = [operation performWithTarget:textField error:nil];
          expect(result).to.equal(textField);
          expect(textField.text).to.equal(@"new text");
        });

        it(@"argument is not an NSString", ^{
          dictionary = @{@"method_name" : @"setText",
                         @"arguments": @[@(5)]};
          operation = [[LPSetTextOperation alloc] initWithOperation:dictionary];
          id result = [operation performWithTarget:textField error:nil];
          expect(result).to.equal(textField);
          expect(textField.text).to.equal(@"5");
        });
      });

      describe(@"does not have correct arguments", ^{
        it(@"missing argument key", ^{
          dictionary = @{@"method_name" : @"setText"};
          operation = [[LPSetTextOperation alloc] initWithOperation:dictionary];
          id result = [operation performWithTarget:textField error:nil];
          expect(result).to.equal(nil);
        });

        it(@"argument does not have at least 1 value", ^{
          dictionary = @{@"method_name" : @"setText",
                         @"arguments": @[]};
          operation = [[LPSetTextOperation alloc] initWithOperation:dictionary];
          id result = [operation performWithTarget:textField error:nil];
          expect(result).to.equal(nil);
        });
      });
    });

    it(@"target does not respond to setText", ^{
      UISlider *slider = [[UISlider alloc] initWithFrame:CGRectZero];
      LPSetTextOperation *op = [[LPSetTextOperation alloc] init];
      expect([op performWithTarget:slider error:nil]).to.equal(nil);
    });
  });
});
SpecEnd
