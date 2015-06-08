//
//  LPAccessorRouteTest.m
//  calabash
//
//  Created by Chris Fuentes on 6/5/15.
//  Copyright (c) 2015 Xamarin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "LPIntrospectionRoute.h"
#import "LPIntrospectionTestView.h"
#import "LPJSONUtils+Introspection.h"

@interface LPIntrospectionRouteTest : XCTestCase

@end

@implementation LPIntrospectionRouteTest

- (void)setUp {
  [super setUp];
}

- (void)tearDown {
  [super tearDown];
}

- (void)testExample {
  
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end

SpecBegin(LPIntrospectionRoute)

describe(@"LPAccessorRoute", ^{
  describe(@"#JSONResponsForMethod:URI:data:", ^{
    __block LPIntrospectionRoute *route;
    __block LPIntrospectionTestView *view;
    __block NSDictionary *results;
    
    before(^{
      route   = [LPIntrospectionRoute new];
      view    = [LPIntrospectionTestView new];
      results = [LPJSONUtils objectIntrospection:view];
    });
    
    it(@"returnsAllSelectorsFromNewClass", ^{
      NSArray *methods = results[@"methods"];
      expect(methods).to.contain(@"privateMethod");
      expect(methods).to.contain(@"privateMethodWithArg:");
      expect(methods).to.contain(@"privateMethodWithArg:andAnother:");
      expect(methods).to.contain(@"voidMethodNoArgs");
      expect(methods).to.contain(@"voidMethodWithArg:");
      expect(methods).to.contain(@"voidMethodWithArg:andAnother:");
      expect(methods).to.contain(@"idMethodNoArgs");
      expect(methods).to.contain(@"idMethodWithArg:");
      expect(methods).to.contain(@"idMethodWithArg:andAnother:");
    });
    
    it(@"returnsAllPropertiesFromNewClass", ^{
      NSDictionary *properties = results[@"properties"];
      for (NSString *propName in @[@"string",
                                   @"readonlyString",
                                   @"customGetterString",
                                   @"customSetterString",
                                   @"customGetterCustomGetterString"]) {
        expect(properties).to.contain(propName);
      }
      
      expect(properties[@"string"]).to.equal(@{@"getter" : @"string", @"setter" : @"setString:"});
      expect(properties[@"readonlyString"]).to.equal(@{@"getter" : @"readonlyString", @"setter" : @"READONLY"});
      expect(properties[@"customGetterString"]).to.equal(@{@"getter" : @"customStringGetter", @"setter" : @"setCustomGetterString:"});
      expect(properties[@"customSetterString"]).to.equal(@{@"getter" : @"customSetterString", @"setter" : @"customStringSetter:"});
      expect(properties[@"customGetterCustomGetterString"]).to.equal(@{@"getter" : @"customStringGetter", @"setter" : @"customStringSetter:"});
    });
    
    it(@"alwaysReturnsAValidSetterAndGetterOrREADONLY", ^{
      NSDictionary *properties = results[@"properties"];
      for (NSString *propName in properties) {
        NSString *setter = results[propName][@"setter"];
        NSString *getter = results[propName][@"getter"];
        expect([view respondsToSelector:NSSelectorFromString(getter)]).to.beTruthy;
        if (![setter isEqualToString:@"READONLY"]) {
          expect([view respondsToSelector:NSSelectorFromString(setter)]).to.beTruthy;
        }
      }
    });
  });
});

SpecEnd
