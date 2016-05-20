#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPScreenshotRoute.h"
#import "LPHTTPResponse.h"

@interface LPScreenshotRoute (LPTEST)

- (NSObject <LPHTTPResponse> *) httpResponseForMethod:(NSString *) method
                                                  URI:(NSString *) path;
- (NSData *) takeScreenshot;
- (NSData *) takeScreenshotUsingSnapshotAPI;
- (NSData *) takeScreenshotUsingRenderInContext;

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
    it(@"uses snapshot api", ^{
      NSData *expected = [NSData data];
      id mock = OCMPartialMock(route);
      OCMExpect([mock takeScreenshotUsingSnapshotAPI]).andReturn(expected);

      NSData *actual = [mock takeScreenshot];
      expect(actual).to.equal(expected);
      OCMVerifyAll(mock);
    });

    it(@"falls back to render in context on exception", ^{
      NSData *expected = [NSData data];
      id mock = OCMPartialMock(route);
      OCMStub([mock takeScreenshotUsingSnapshotAPI]).andThrow([NSException new]);
      OCMExpect([mock takeScreenshotUsingRenderInContext]).andReturn(expected);

      NSData *actual = [mock takeScreenshot];
      expect(actual).to.equal(expected);
      OCMVerifyAll(mock);
    });
  });
});

SpecEnd
