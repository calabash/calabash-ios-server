//
//  LPAccessorRouteTest.m
//  calabash
//
//  Created by Chris Fuentes on 6/5/15.
//  Copyright (c) 2015 Xamarin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "LPAccessorRoute.h"

@interface LPAccessorRouteTest : XCTestCase

@end

@implementation LPAccessorRouteTest

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

SpecBegin(LPAccessorRoute)

describe(@"LPAccessorRoute", ^{
  describe(@"#JSONResponsForMethod:URI:data:", ^{
    
    __block LPAccessorRoute *route;
    __block NSDictionary *response;
    
    before(^{
      route = [LPAccessorRoute new];
      response = [route JSONResponseForMethod:@"POST" URI:@"/accessors" data:nil];
    });
    
    it(@"works", ^{
      NSLog(@"%@", response);
    });
  });
});

SpecEnd
