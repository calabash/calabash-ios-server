#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "LPRuntimeWKWebView.h"
#import <WebKit/WebKit.h>
#import "LPInvoker.h"
#import "LPWebViewProtocol.h"
#import "LPJSONUtils.h"

@interface LPRuntimeWKWebView (LPXCTest)

+ (Class) lpClassForWKWebView;

+ (BOOL) addLPWebViewProtocol:(Class) klass;

+ (BOOL) addWithDateMethod:(Class) klass;

+ (BOOL) addWithDictionaryMethod:(Class) klass;

+ (BOOL) addWithArrayMethod:(Class) klass;

+ (BOOL) addEvaluateJavaScriptMethod:(Class) klass;

@end


@interface LPTestProtocol : NSObject @end
@implementation LPTestProtocol @end

@interface LPTestWithDate : NSObject @end
@implementation LPTestWithDate @end

@interface LPTestWithDictionary : NSObject @end
@implementation LPTestWithDictionary @end

@interface LPTestWithArray : NSObject @end
@implementation LPTestWithArray @end

@interface LPTestEvalJS : NSObject @end
@implementation LPTestEvalJS @end

@interface LPTestImplemented : NSObject @end
@implementation LPTestImplemented @end

@interface LPRuntimeWKWebViewTest : XCTestCase

@end

@implementation LPRuntimeWKWebViewTest

@end

SpecBegin(LPRuntimeWKWebViewTest)

describe(@"LPRuntimeWKWebView", ^{

  describe(@"Construct Class at Runtime", ^{

    it(@"addLPWebViewProtocol", ^{
      BOOL success = [LPRuntimeWKWebView addLPWebViewProtocol:[LPTestProtocol class]];
      expect(success).to.equal(YES);
      id obj = [LPTestProtocol new];
      BOOL conforms = [obj conformsToProtocol:@protocol(LPWebViewProtocol)];
      expect(conforms).to.equal(YES);
    });

    it(@"addWithDateMethod:", ^{
      BOOL success = [LPRuntimeWKWebView addWithDateMethod:[LPTestWithDate class]];

      expect(success).to.equal(YES);
      id obj = [LPTestWithDate new];
      SEL sel = NSSelectorFromString(@"lpStringWithDate:");
      expect([obj respondsToSelector:sel]).to.equal(YES);

      NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
      [formatter setDateFormat:LPRuntimeWKWebViewISO8601DateFormat];
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
      BOOL success = [LPRuntimeWKWebView addWithDictionaryMethod:[LPTestWithDictionary class]];
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
      BOOL success = [LPRuntimeWKWebView addWithArrayMethod:[LPTestWithArray class]];
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
      BOOL success = [LPRuntimeWKWebView addEvaluateJavaScriptMethod:[LPTestEvalJS class]];
      expect(success).to.equal(YES);
      id obj = [LPTestEvalJS new];
      SEL sel = NSSelectorFromString(@"calabashStringByEvaluatingJavaScript:");
      expect([obj respondsToSelector:sel]).to.equal(YES);
    });
  });

  describe(@"implementLPWebViewProtocolOnWKWebView", ^{
    it(@"returns not available when WKWebView is not defined", ^{
      id mock = [OCMockObject niceMockForClass:[LPRuntimeWKWebView class]];
      [[[mock stub] andReturn:nil] lpClassForWKWebView];
      LPWKWebViewWebViewProtocolImplementation state;
      state = [[mock class] implementLPWebViewProtocolOnWKWebView];
      expect(state).to.equal(LPWKWebViewNotAvailable);
    });

    it(@"returns implemented if runtime implementation was successful", ^{
      id mock = [OCMockObject niceMockForClass:[LPRuntimeWKWebView class]];
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
