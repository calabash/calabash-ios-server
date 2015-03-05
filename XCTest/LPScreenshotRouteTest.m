#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPScreenshotRoute.h"
#import "LPHTTPResponse.h"

@interface LPScreenshotRoute (LPTEST)

- (NSObject <LPHTTPResponse> *) httpResponseForMethod:(NSString *) method
                                                  URI:(NSString *) path;
- (NSData *) takeScreenshot;

@end

SpecBegin(LPScreenshotRoute)

__block LPScreenshotRoute *route;

describe(@"LPScreenshotRoute", ^{

  before(^{
    route = [LPScreenshotRoute new];
  });

  describe(@"#supportsMethod:atPath:", ^{
    it(@"returns true for GET", ^{
      BOOL expected = [route supportsMethod:@"GET" atPath:nil];
      expect(expected).to.equal(YES);
    });

    it(@"returns false otherwise", ^{
      BOOL expected = [route supportsMethod:@"BAR" atPath:nil];
      expect(expected).to.equal(NO);
    });
  });

  describe(@"#httpResponseForMethod:URI:", ^{
    it(@"returns an object that conforms to LPHTTPResponse", ^{
      id mock = OCMPartialMock(route);
      OCMExpect([mock takeScreenshot]).andReturn([NSData data]);

      id result = [mock httpResponseForMethod:nil URI:nil];
      XCTAssertNotNil(result);
      expect(result).to.conformTo(@protocol(LPHTTPResponse));
      OCMVerify([mock takeScreenshot]);
    });
  });

  describe(@"#takeScreenshot", ^{
    it(@"returns data", ^{
      NSData *result = [route takeScreenshot];
      XCTAssertNotNil(result);
      expect(result).to.beKindOf([NSData class]);
    });
  });
});

SpecEnd
