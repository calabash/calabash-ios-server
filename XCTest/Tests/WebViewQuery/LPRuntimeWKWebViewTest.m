#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "LPRuntimeWKWebView.h"
#import <WebKit/WebKit.h>
#import "LPInvoker.h"
#import "LPWebViewProtocol.h"

@interface LPRuntimeWKWebView (LPXCTest)

+ (Class) lpClassForWKWebView;

+ (BOOL) addLPWebViewProtocol:(Class) klass;

+ (BOOL) addWithDateMethod:(Class) klass
                  encoding:(const char *) encoding;

+ (BOOL) addWithDictionaryMethod:(Class) klass
                        encoding:(const char *) encoding;

+ (BOOL) addWithArrayMethod:(Class) klass
                   encoding:(const char *) encoding;

+ (BOOL) addEvaluateJavaScriptMethod:(Class) klass
                            encoding:(const char *) encoding;

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

  __block const char *encoding;

  before(^{
    Method descript = class_getInstanceMethod([NSObject class],
                                              @selector(description));
    encoding = method_getTypeEncoding(descript);
  });

  describe(@"Construct Class at Runtime", ^{

    it(@"addLPWebViewProtocol", ^{
      BOOL success = [LPRuntimeWKWebView addLPWebViewProtocol:[LPTestProtocol class]];
      expect(success).to.equal(YES);
      id obj = [LPTestProtocol new];
      BOOL conforms = [obj conformsToProtocol:@protocol(LPWebViewProtocol)];
      expect(conforms).to.equal(YES);
    });

    it(@"addWithDateMethod:", ^{
      BOOL success = [LPRuntimeWKWebView addWithDateMethod:[LPTestWithDate class]
                                                  encoding:encoding];
      expect(success).to.equal(YES);
      id obj = [LPTestWithDate new];
      SEL sel = NSSelectorFromString(@"lpStringWithDate:");
      expect([obj respondsToSelector:sel]).to.equal(YES);
    });

    it(@"addWithDictionaryMethod:", ^{
      BOOL success = [LPRuntimeWKWebView addWithDictionaryMethod:[LPTestWithDictionary class]
                                                        encoding:encoding];
      expect(success).to.equal(YES);
      id obj = [LPTestWithDictionary new];
      SEL sel = NSSelectorFromString(@"lpStringWithDictionary:");
      expect([obj respondsToSelector:sel]).to.equal(YES);
    });

    it(@"addWithArrayMethod:", ^{
      BOOL success = [LPRuntimeWKWebView addWithArrayMethod:[LPTestWithArray class]
                                                   encoding:encoding];
      expect(success).to.equal(YES);
      id obj = [LPTestWithArray new];
      SEL sel = NSSelectorFromString(@"lpStringWithArray:");
      expect([obj respondsToSelector:sel]).to.equal(YES);
    });

    it(@"addEvaluateJavaScriptMethod:", ^{
      BOOL success = [LPRuntimeWKWebView addEvaluateJavaScriptMethod:[LPTestEvalJS class]
                                                            encoding:encoding];
      expect(success).to.equal(YES);
      id obj = [LPTestEvalJS new];
      SEL sel = NSSelectorFromString(@"calabashStringByEvaluatingJavaScript:");
      expect([obj respondsToSelector:sel]).to.equal(YES);
    });
  });

  fdescribe(@"implementLPWebViewProtocolOnWKWebView", ^{
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
      [[[mock stub] andReturnValue:@YES] addWithDateMethod:klass
                                                  encoding:encoding];
      [[[mock stub] andReturnValue:@YES] addWithDictionaryMethod:klass
                                                        encoding:encoding];
      [[[mock stub] andReturnValue:@YES] addWithArrayMethod:klass
                                                   encoding:encoding];
      [[[mock stub] andReturnValue:@YES] addEvaluateJavaScriptMethod:klass
                                                            encoding:encoding];

      LPWKWebViewWebViewProtocolImplementation state;
      state = [[mock class] implementLPWebViewProtocolOnWKWebView];
      expect(state).to.equal(LPWKWebViewDidImplementProtocol);
    });
  });
});

SpecEnd
