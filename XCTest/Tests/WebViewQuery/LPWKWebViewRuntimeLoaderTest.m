#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "LPWKWebViewRuntimeLoader.h"
#import <WebKit/WebKit.h>
#import "LPInvoker.h"
#import "LPWebViewProtocol.h"
#import "LPJSONUtils.h"


@interface LPWKWebViewRuntimeLoader (LPXCTest)

+ (LPWKWebViewWebViewProtocolImplementation) implementLPWebViewProtocolOnWKWebView;
+ (Class) lpClassForWKWebView;
+ (BOOL) addLPWebViewProtocol:(Class) klass;
+ (BOOL) addWithDateMethod:(Class) klass;
+ (BOOL) addWithDictionaryMethod:(Class) klass;
+ (BOOL) addWithArrayMethod:(Class) klass;
+ (BOOL) addEvaluateJavaScriptMethod:(Class) klass;
- (void) setState:(LPWKWebViewWebViewProtocolImplementation) newState;

@end

@interface LPTestProtocol : NSObject @end
@implementation LPTestProtocol @end

@interface LPTestWithDate : NSObject @end
@implementation LPTestWithDate @end

@interface LPTestWithDictionary : NSObject @end
@implementation LPTestWithDictionary @end

@interface LPTestWithArray : NSObject @end
@implementation LPTestWithArray @end

@interface LPTestEvalJS : NSObject

- (void) evaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^)(id, NSError *))completionHandler;

@end

@implementation LPTestEvalJS

- (void)evaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^)(id, NSError *))completionHandler {
  id result = nil;
  NSError *error = nil;
  if ([javaScriptString isEqualToString:@"date"]) {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:LPWKWebViewISO8601DateFormat];
    NSString *expectedDateString = @"2015-03-26 16:39:06 +0100";
    result = [formatter dateFromString:expectedDateString];
  } else if ([javaScriptString isEqualToString:@"dictionary"]) {
    result = @{@"one" : @(1), @"two" : @(2), @"three" : @(3)};
  } else if ([javaScriptString isEqualToString:@"array"]) {
    result = @[@(1), @(2), @(3)];
  } else if ([javaScriptString isEqualToString:@"string"]) {
    result = [NSString stringWithFormat:@"Received javascript: %@!", javaScriptString];
  } else if ([javaScriptString isEqualToString:@"nil"]) {
    result = @"Recieved nil";
  } else if ([javaScriptString isEqualToString:@"error"]) {
    error = [NSError errorWithDomain:@"MY DOMAIN!"
                                code:11
                            userInfo:@{NSLocalizedDescriptionKey :
                                         @"Another day, another misunderstood JavaScript programmer."}];
  }
  completionHandler(result, error);
}

- (NSString *) lpStringWithDate:(NSDate *) date {
  return @"Received a date!";
}

- (NSString *) lpStringWithDictionary:(NSDictionary *) dictionary {
  return @"Received a dictionary!";
}

- (NSString *) lpStringWithArray:(NSArray *) array {
  return @"Received an array!";
}

@end

@interface LPTestImplemented : NSObject @end
@implementation LPTestImplemented @end

@interface LPWKWebViewRuntimeLoaderTest : XCTestCase

@end

@implementation LPWKWebViewRuntimeLoaderTest

@end

SpecBegin(LPWKWebViewRuntimeLoader)

describe(@"LPWKWebViewRuntimeLoaderTest", ^{

  describe(@"Implements Singleton Pattern", ^{
    it(@"#init", ^{
      expect(^{
        id __unused obj = [[LPWKWebViewRuntimeLoader alloc] init];
      }).to.raiseAny();
    });

    it(@"shared", ^{
      id a = [LPWKWebViewRuntimeLoader shared];
      id b = [LPWKWebViewRuntimeLoader shared];
      expect(a).to.equal(b);
      expect([a isKindOfClass:[LPWKWebViewRuntimeLoader class]]).to.equal(YES);
    });
  });

  describe(@"#loadImplementation", ^{
    it(@"Skips loading if implementation is already loaded", ^{
      LPWKWebViewRuntimeLoader *loader = [LPWKWebViewRuntimeLoader shared];
      LPWKWebViewWebViewProtocolImplementation originalState = loader.state;

      id mock = OCMPartialMock(loader);
      LPWKWebViewWebViewProtocolImplementation mockState = LPWKWebViewNotAvailable;
      [[[mock stub] andReturnValue:OCMOCK_VALUE(mockState)] state];

      @try {
        expect([mock loadImplementation]).to.equal(LPWKWebViewNotAvailable);
        [mock verify];
      }

      @finally {
        [mock stopMocking];
        [loader setState:originalState];
      }
    });

    it(@"Implementation has been loaded by CalabashServer.start", ^{
      LPWKWebViewRuntimeLoader *loader = [LPWKWebViewRuntimeLoader shared];
      expect(loader.state).to.equal(LPWKWebViewDidImplementProtocol);
    });
  });

  describe(@"Construct Class at Runtime", ^{

    it(@"addLPWebViewProtocol", ^{
      BOOL success = [LPWKWebViewRuntimeLoader addLPWebViewProtocol:[LPTestProtocol class]];
      expect(success).to.equal(YES);
      id obj = [LPTestProtocol new];
      BOOL conforms = [obj conformsToProtocol:@protocol(LPWebViewProtocol)];
      expect(conforms).to.equal(YES);
    });

    it(@"addWithDateMethod:", ^{
      BOOL success = [LPWKWebViewRuntimeLoader addWithDateMethod:[LPTestWithDate class]];

      expect(success).to.equal(YES);
      id obj = [LPTestWithDate new];
      SEL sel = NSSelectorFromString(@"lpStringWithDate:");
      expect([obj respondsToSelector:sel]).to.equal(YES);

      NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
      [formatter setDateFormat:LPWKWebViewISO8601DateFormat];
      NSString *expectedDateString = @"2015-03-26 16:39:06 +0100";
      NSDate *expected = [formatter dateFromString:expectedDateString];
      NSString *actualDateString;
      actualDateString = [LPWKWebViewMethodInvoker stringByInvokingSelector:sel
                                                                     target:obj
                                                                   argument:expected];

      NSDate *actual = [formatter dateFromString:actualDateString];
      expect([actual compare:expected]).to.equal(NSOrderedSame);
    });

    it(@"addWithDictionaryMethod:", ^{
      BOOL success = [LPWKWebViewRuntimeLoader addWithDictionaryMethod:[LPTestWithDictionary class]];
      expect(success).to.equal(YES);
      id obj = [LPTestWithDictionary new];
      SEL sel = NSSelectorFromString(@"lpStringWithDictionary:");
      expect([obj respondsToSelector:sel]).to.equal(YES);

      NSDictionary *dict = @{@"one" : @(1),
                             @"two" : @(2),
                             @"three" : @(3)};
      NSString *expected = [LPJSONUtils serializeDictionary:dict];
      NSString *actual = [LPWKWebViewMethodInvoker stringByInvokingSelector:sel
                                                                     target:obj
                                                                   argument:dict];
      expect(actual).to.equal(expected);
    });

    it(@"addWithArrayMethod:", ^{
      BOOL success = [LPWKWebViewRuntimeLoader addWithArrayMethod:[LPTestWithArray class]];
      expect(success).to.equal(YES);
      id obj = [LPTestWithArray new];
      SEL sel = NSSelectorFromString(@"lpStringWithArray:");
      expect([obj respondsToSelector:sel]).to.equal(YES);

      NSArray *arr = @[@(1), @(2), @(3)];
      NSString *expected = [LPJSONUtils serializeArray:arr];
      NSString *actual = [LPWKWebViewMethodInvoker stringByInvokingSelector:sel
                                                                     target:obj
                                                                   argument:arr];
      expect(actual).to.equal(expected);
    });

    it(@"addEvaluateJavaScriptMethod:", ^{
      BOOL success = [LPWKWebViewRuntimeLoader addEvaluateJavaScriptMethod:[LPTestEvalJS class]];
      expect(success).to.equal(YES);
      id obj = [LPTestEvalJS new];
      SEL sel = NSSelectorFromString(@"calabashStringByEvaluatingJavaScript:");
      expect([obj respondsToSelector:sel]).to.equal(YES);

      NSString *actual;
      // nil
      actual = [LPWKWebViewMethodInvoker stringByInvokingSelector:sel
                                                           target:obj
                                                         argument:@"nil"];
      expect(actual).to.equal(@"Recieved nil");

      // date
      actual = [LPWKWebViewMethodInvoker stringByInvokingSelector:sel
                                                           target:obj
                                                         argument:@"date"];
      expect(actual).to.equal(@"Received a date!");

      // dictionary
      actual = [LPWKWebViewMethodInvoker stringByInvokingSelector:sel
                                                           target:obj
                                                         argument:@"dictionary"];
      expect(actual).to.equal(@"Received a dictionary!");

      // array
      actual = [LPWKWebViewMethodInvoker stringByInvokingSelector:sel
                                                           target:obj
                                                         argument:@"array"];
      expect(actual).to.equal(@"Received an array!");

      // string
      actual = [LPWKWebViewMethodInvoker stringByInvokingSelector:sel
                                                           target:obj
                                                         argument:@"string"];
      expect(actual).to.equal(@"Received javascript: string!");

      // error
      actual = [LPWKWebViewMethodInvoker stringByInvokingSelector:sel
                                                           target:obj
                                                         argument:@"error"];
      NSString *expected = @"{\"error\":\"Another day, another misunderstood JavaScript programmer.\",\"javascript\":\"error\"}";
      expect(actual).to.equal(expected);
    });
  });

  describe(@"implementLPWebViewProtocolOnWKWebView", ^{
    it(@"returns not available when WKWebView is not defined", ^{
      id mock = [OCMockObject niceMockForClass:[LPWKWebViewRuntimeLoader class]];
      [[[mock stub] andReturn:nil] lpClassForWKWebView];
      LPWKWebViewWebViewProtocolImplementation state;
      state = [[mock class] implementLPWebViewProtocolOnWKWebView];
      expect(state).to.equal(LPWKWebViewNotAvailable);
    });

    it(@"returns implemented if runtime implementation was successful", ^{
      id mock = [OCMockObject niceMockForClass:[LPWKWebViewRuntimeLoader class]];
      Class klass = [LPTestImplemented class];
      [[[mock stub] andReturn:klass] lpClassForWKWebView];
      [[[mock stub] andReturnValue:@YES] addLPWebViewProtocol:klass];
      [[[mock stub] andReturnValue:@YES] addWithDateMethod:klass];
      [[[mock stub] andReturnValue:@YES] addWithDictionaryMethod:klass];
      [[[mock stub] andReturnValue:@YES] addWithArrayMethod:klass];
      [[[mock stub] andReturnValue:@YES] addEvaluateJavaScriptMethod:klass];

      LPWKWebViewWebViewProtocolImplementation state;
      state = [[mock class] implementLPWebViewProtocolOnWKWebView];
      expect(state).to.equal(LPWKWebViewDidImplementProtocol);
    });
  });
});

SpecEnd
