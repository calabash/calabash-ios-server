#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPWKWebViewRuntimeLoader.h"
#import "LPJSONUtils.h"
#import <WebKit/WebKit.h>
#import "LPWebViewProtocol.h"
#import "LPCJSONDeserializer.h"
#import "LPDevice.h"

@interface WKWebView (LPXCTEST)

- (NSString *) lpStringWithDate:(NSDate *) date;
- (NSString *) lpStringWithDictionary:(NSDictionary *) dictionary;
- (NSString *) lpStringWithArray:(NSArray *) array;
- (NSString *) calabashStringByEvaluatingJavaScript:(NSString *) javascript;

@end

@interface LPMockEvaluator : NSObject

@property(strong, nonatomic, readonly) id result;
@property(assign, nonatomic, readonly) BOOL raiseError;

- (void) mockEvaluateJavascript:(NSString *) javascript
              completionHandler:(void (^)(id, NSError *))completionHandler;

- (id) initWithResult:(id) result;
- (id) initWithResult:(id) result
                raise:(BOOL) raiseError;

@end

@implementation LPMockEvaluator

- (id) initWithResult:(id) result {
  return [self initWithResult:result raise:NO];
}

- (id) initWithResult:(id)result raise:(BOOL)raiseError {
  self = [super init];
  if (self) {
    _result = result;
    _raiseError = raiseError;
  }
  return self;
}

- (void) mockEvaluateJavascript:(NSString *)javascript
              completionHandler:(void (^)(id, NSError *))completionHandler {
  __weak __typeof__(self) weakSelf = self;
  if (weakSelf.raiseError) {
    NSError *error = [NSError errorWithDomain:@"MY DOMAIN!"
                                         code:11
                                     userInfo:@{NSLocalizedDescriptionKey :
                                                  @"Another day, another misunderstood JavaScript programmer."}];
    completionHandler(nil, error);
  } else {
    completionHandler(weakSelf.result, nil);
  }
}

@end

@interface WKWebView_LPWebViewTest : XCTestCase

@end

@implementation WKWebView_LPWebViewTest

@end

SpecBegin(WKWebView_LPWebViewTest)

describe(@"WKWebView+LPWebView", ^{

  if (lp_ios_version_lt(@"8.0")) {
    // nop for iOS < 8
  } else {

    describe(@"helper methods", ^{
      __block WKWebView *webView;
      before(^{ webView = [[WKWebView alloc] initWithFrame:CGRectZero]; });

      it(@"#lpStringFromDate:", ^{
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:LPWKWebViewISO8601DateFormat];
        NSString *expectedDateString = @"2015-03-26 16:39:06 +0100";
        NSDate *expected = [formatter dateFromString:expectedDateString];
        NSString *actualDateString = [webView lpStringWithDate:expected];
        NSDate *actual = [formatter dateFromString:actualDateString];
        expect([actual compare:expected]).to.equal(NSOrderedSame);
      });

      it(@"lpStringFromDictionary:", ^{
        NSDictionary *dict = @{@"one" : @(1),
                               @"two" : @(2),
                               @"three" : @(3)};
        NSString *expected = [LPJSONUtils serializeDictionary:dict];
        NSString *actual = [webView lpStringWithDictionary:dict];
        expect(actual).to.equal(expected);
      });

      it(@"lpStringFromArray:", ^{
        NSArray *arr = @[@(1), @(2), @(3)];
        NSString *expected = [LPJSONUtils serializeArray:arr];
        NSString *actual = [webView lpStringWithArray:arr];
        expect(actual).to.equal(expected);
      });
    });

    describe(@"#calabashStringByEvaulatingJavaScript:", ^{

      __block WKWebView *webView;
      __block SEL mockSel;
      __block LPMockEvaluator *evaluator;
      __block NSString *expected;
      __block NSString *actual;
      __block id viewMock;

      before(^{
        webView = [[WKWebView alloc] initWithFrame:CGRectZero];
        mockSel = @selector(mockEvaluateJavascript:completionHandler:);
      });


      describe(@"can report errors", ^{
        it(@"when javascript is not nil", ^{
          evaluator = [[LPMockEvaluator alloc] initWithResult:nil raise:YES];
          viewMock = [OCMockObject partialMockForObject:webView];
          [[[viewMock stub] andCall:mockSel onObject:evaluator]
           evaluateJavaScript:OCMOCK_ANY completionHandler:OCMOCK_ANY];
          actual = [viewMock calabashStringByEvaluatingJavaScript:@"invalid javascript"];
          expected = @"{\"error\":\"Another day, another misunderstood JavaScript programmer.\",\"javascript\":\"invalid javascript\"}";

          NSData *actualData = [actual dataUsingEncoding:NSUTF8StringEncoding];
          NSData *expectedData = [expected dataUsingEncoding:NSUTF8StringEncoding];

          LPCJSONDeserializer *parser = [LPCJSONDeserializer new];

          NSDictionary *actualDict = [parser deserializeAsDictionary:actualData error:nil];
          NSDictionary *expectedDict = [parser deserializeAsDictionary:expectedData error:nil];

          expect(actualDict[@"error"]).to.equal(expectedDict[@"error"]);
          expect(actualDict[@"javascript"]).to.equal(expectedDict[@"javascript"]);
        });

        it(@"when javascript is nil", ^{
          evaluator = [[LPMockEvaluator alloc] initWithResult:nil raise:YES];
          viewMock = [OCMockObject partialMockForObject:webView];
          [[[viewMock stub] andCall:mockSel onObject:evaluator]
           evaluateJavaScript:OCMOCK_ANY completionHandler:OCMOCK_ANY];
          actual = [viewMock calabashStringByEvaluatingJavaScript:nil];
          expected = @"{\"error\":\"Another day, another misunderstood JavaScript programmer.\",\"javascript\":null}";

          NSData *actualData = [actual dataUsingEncoding:NSUTF8StringEncoding];
          NSData *expectedData = [expected dataUsingEncoding:NSUTF8StringEncoding];

          LPCJSONDeserializer *parser = [LPCJSONDeserializer new];

          NSDictionary *actualDict = [parser deserializeAsDictionary:actualData error:nil];
          NSDictionary *expectedDict = [parser deserializeAsDictionary:expectedData error:nil];

          expect(actualDict[@"error"]).to.equal(expectedDict[@"error"]);
          expect(actualDict[@"javascript"]).to.equal(expectedDict[@"javascript"]);
        });
      });

      describe(@"can handle various return types", ^{

        it(@"returns empty string for 'nil'", ^{
          evaluator = [[LPMockEvaluator alloc] initWithResult:nil];
          viewMock = [OCMockObject partialMockForObject:webView];
          [[[viewMock stub] andCall:mockSel onObject:evaluator]
           evaluateJavaScript:OCMOCK_ANY completionHandler:OCMOCK_ANY];
          actual = [viewMock calabashStringByEvaluatingJavaScript:@""];
          expect(actual).to.equal(@"");
        });

        it(@"returns empty string for NSNull", ^{
          evaluator = [[LPMockEvaluator alloc] initWithResult:[NSNull null]];
          viewMock = [OCMockObject partialMockForObject:webView];
          [[[viewMock stub] andCall:mockSel onObject:evaluator]
           evaluateJavaScript:OCMOCK_ANY completionHandler:OCMOCK_ANY];
          actual = [viewMock calabashStringByEvaluatingJavaScript:@""];
          expect(actual).to.equal(@"");
        });

        it(@"returns a string for NSString", ^{
          evaluator = [[LPMockEvaluator alloc] initWithResult:@"a string"];
          viewMock = [OCMockObject partialMockForObject:webView];
          [[[viewMock stub] andCall:mockSel onObject:evaluator]
           evaluateJavaScript:OCMOCK_ANY completionHandler:OCMOCK_ANY];
          NSString *actual = [viewMock calabashStringByEvaluatingJavaScript:@""];
          expect(actual).to.equal(@"a string");
        });

        it(@"returns an iso 8601 string for NSDate", ^{
          NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
          [formatter setDateFormat:LPWKWebViewISO8601DateFormat];
          NSString *expectedDateString = @"2015-03-26 16:39:06 +0100";
          NSDate *expectedDate = [formatter dateFromString:expectedDateString];

          NSDate *dateToReturn = [formatter dateFromString:expected];
          evaluator = [[LPMockEvaluator alloc] initWithResult:dateToReturn];
          viewMock = [OCMockObject partialMockForObject:webView];
          [[[viewMock stub] andCall:mockSel onObject:evaluator]
           evaluateJavaScript:OCMOCK_ANY completionHandler:OCMOCK_ANY];
          NSString *actualDateString = [viewMock calabashStringByEvaluatingJavaScript:@""];

          NSDate *actualDate = [formatter dateFromString:actualDateString];
          expect([actualDate compare:expectedDate]).to.equal(NSOrderedSame);
        });

        it(@"returns JSON representation of NSDictionary", ^{
          NSDictionary *dict = @{@"one" : @(1),
                                 @"two" : @(2),
                                 @"three" : @(3)};
          expected = [LPJSONUtils serializeDictionary:dict];

          evaluator = [[LPMockEvaluator alloc] initWithResult:dict];
          viewMock = [OCMockObject partialMockForObject:webView];
          [[[viewMock stub] andCall:mockSel onObject:evaluator]
           evaluateJavaScript:OCMOCK_ANY completionHandler:OCMOCK_ANY];
          actual = [viewMock calabashStringByEvaluatingJavaScript:@""];
          expect(actual).to.equal(expected);
        });

        it(@"returns JSON representation of NSArray", ^{
          NSArray *arr = @[@(1), @(2), @(3)];
          expected = [LPJSONUtils serializeArray:arr];
          evaluator = [[LPMockEvaluator alloc] initWithResult:arr];
          viewMock = [OCMockObject partialMockForObject:webView];
          [[[viewMock stub] andCall:mockSel onObject:evaluator]
           evaluateJavaScript:OCMOCK_ANY completionHandler:OCMOCK_ANY];
          actual = [viewMock calabashStringByEvaluatingJavaScript:@""];
          expect(actual).to.equal(expected);
        });

        describe(@"returns string for NSNumber", ^{
          it(@"CGFloat", ^{
            CGFloat val = 44.5;
            NSNumber *number = @(val);
            evaluator = [[LPMockEvaluator alloc] initWithResult:number];
            viewMock = [OCMockObject partialMockForObject:webView];
            [[[viewMock stub] andCall:mockSel onObject:evaluator]
             evaluateJavaScript:OCMOCK_ANY completionHandler:OCMOCK_ANY];

            actual = [viewMock calabashStringByEvaluatingJavaScript:@""];
            expect(actual).to.equal(@"44.5");
          });

          it(@"NSUInteger", ^{
            NSUInteger val = 44;
            NSNumber *number = @(val);
            evaluator = [[LPMockEvaluator alloc] initWithResult:number];
            viewMock = [OCMockObject partialMockForObject:webView];
            [[[viewMock stub] andCall:mockSel onObject:evaluator]
             evaluateJavaScript:OCMOCK_ANY completionHandler:OCMOCK_ANY];
            actual = [viewMock calabashStringByEvaluatingJavaScript:@""];
            expect(actual).to.equal(@"44");
          });

          it(@"NSInteger", ^{
            NSInteger val = -44;
            NSNumber *number = @(val);
            evaluator = [[LPMockEvaluator alloc] initWithResult:number];
            viewMock = [OCMockObject partialMockForObject:webView];
            [[[viewMock stub] andCall:mockSel onObject:evaluator]
             evaluateJavaScript:OCMOCK_ANY completionHandler:OCMOCK_ANY];
            NSString *actual = [viewMock calabashStringByEvaluatingJavaScript:@""];
            expect(actual).to.equal(@"-44");
          });
        });

        it(@"returns description if all else fails", ^{
          UIColor *color = [UIColor whiteColor];
          evaluator = [[LPMockEvaluator alloc] initWithResult:color];
          viewMock = [OCMockObject partialMockForObject:webView];
          [[[viewMock stub] andCall:mockSel onObject:evaluator]
           evaluateJavaScript:OCMOCK_ANY completionHandler:OCMOCK_ANY];
          NSString *actual = [viewMock calabashStringByEvaluatingJavaScript:@""];
          NSUInteger idx = [actual rangeOfString:@"UIDeviceWhiteColorSpace"].location;
          expect(idx).notTo.equal(NSNotFound);
        });
      });

      describe(@"can eval actual JavaScript", ^{
        it(@"returns string for numbers", ^{
          NSString *actual;
          actual = [webView calabashStringByEvaluatingJavaScript:@"1 + 2"];
          expect(actual).to.equal(@"3");
          actual = [webView calabashStringByEvaluatingJavaScript:@"new Number(4)"];
          expect(actual).to.equal(@"{}");
        });

        it(@"returns string for string concat", ^{
          NSString *javascript = @"eval(\"'a' + 'b'\")";
          actual = [webView calabashStringByEvaluatingJavaScript:javascript];
          expect(actual).to.equal(@"ab");
        });

        it(@"returns JSON representation of arrays", ^{
          expected = @"[\"a\",\"b\",1]";
          NSString *javascript = @"['a', 'b', 1]";

          actual = [webView calabashStringByEvaluatingJavaScript:javascript];
          expect(actual).to.equal(expected);
        });

        it(@"returns JSON representation of associate arrays", ^{
          expected =  @"{\"trout\":\"yummy\"}";
          NSString *javascript = @"var a = {}; var fish = 'trout'; a[fish] = 'yummy'; a;";
          actual = [webView calabashStringByEvaluatingJavaScript:javascript];
          expect(actual).to.equal(expected);
        });
      });
    });
  }
});

SpecEnd
