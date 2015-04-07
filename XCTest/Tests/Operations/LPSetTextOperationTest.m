#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPSetTextOperation.h"

@interface LPSetTextOperation (LPXCTEST)

- (NSArray *) arguments;

@end

SpecBegin(LPSetTextOperation)

describe(@"LPSetTextOperation", ^{

  __block LPSetTextOperation *operation;
  __block NSDictionary *dictionary;

  describe(@"performWithTarget:error:", ^{

    describe(@"returns nil when invalid arguments", ^{
      __block id target;

      before(^{
        target = [NSObject new];
      });

      it(@"arguments are nil", ^{
        dictionary = @{@"method_name" : @"setText"};
        operation = [[LPSetTextOperation alloc] initWithOperation:dictionary];
        id result = [operation performWithTarget:target error:nil];
        expect(result).to.equal(nil);
      });

      it(@"arguments does not have at least 1 value", ^{
        dictionary = @{@"method_name" : @"setText",
                       @"arguments": @[]};
        operation = [[LPSetTextOperation alloc] initWithOperation:dictionary];
        id result = [operation performWithTarget:target error:nil];
        expect(result).to.equal(nil);
      });
    });

    describe(@"target represents a WebView; it is a dictionary", ^{
      describe(@"dict has invalid keys", ^{

      });

      describe(@"dict has valid keys", ^{

      });
    });

    describe(@"target responds to setText", ^{

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
    });

    it(@"target does not respond to setText", ^{
      dictionary = @{@"method_name" : @"setText",
                     @"arguments": @[@"new text"]};
      operation = [[LPSetTextOperation alloc] init];
      UISlider *slider = [[UISlider alloc] initWithFrame:CGRectZero];
      expect([operation performWithTarget:slider error:nil]).to.equal(nil);
    });
  });
});

SpecEnd
