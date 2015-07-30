#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPKeyboardLanguageRoute.h"

@interface LPKeyboardLanguageRoute (LPXCTEST)

- (BOOL) canHandlePostForPath:(NSArray *) path;
- (UIWindow *) findKeyboardWindow;
- (UIView *) findKeyboardViewWithWindow:(UIWindow *) window;
- (NSString *) primaryLanguageFromKeyboardView:(UIView *) keyboardView;

@end


@interface LPKeyboardLanguageRouteTest : XCTestCase

@end

@implementation LPKeyboardLanguageRouteTest

- (void)setUp {
  [super setUp];
}

- (void)tearDown {
  [super tearDown];
}

- (void) testCanHandlePostForPath {
  LPKeyboardLanguageRoute *route = [LPKeyboardLanguageRoute new];
  NSArray *path = @[@"cannot-handle"];
  expect([route canHandlePostForPath:path]).to.equal(NO);

  path = @[@"keyboard-language"];
  expect([route canHandlePostForPath:path]).to.equal(YES);
}

- (void) testJSONResponseForMethodFailure {
  LPKeyboardLanguageRoute *route = [LPKeyboardLanguageRoute new];

  id mock = OCMPartialMock(route);
  [[[mock expect] andReturn:nil] findKeyboardWindow];

  NSDictionary *response;
  response = [mock JSONResponseForMethod:nil URI:nil data:nil];

  expect([response count]).to.equal(3);
  expect(response[@"outcome"]).to.equal(@"FAILURE");
  expect(response[@"details"]).notTo.equal(nil);
  expect(response[@"reason"]).notTo.equal(nil);
  [mock verify];
}

- (void) testJSONResponseForMethodSuccess {
  LPKeyboardLanguageRoute *route = [LPKeyboardLanguageRoute new];

  id mock = OCMPartialMock(route);
  UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectZero];
  [[[mock expect] andReturn:window] findKeyboardWindow];

  UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
  [[[mock expect] andReturn:view] findKeyboardViewWithWindow:window];

  [[[mock expect] andReturn:@"en"] primaryLanguageFromKeyboardView:view];


  NSDictionary *response;
  response = [mock JSONResponseForMethod:nil URI:nil data:nil];

  expect([response count]).to.equal(2);
  expect(response[@"outcome"]).to.equal(@"SUCCESS");
  expect(response[@"results"][@"input_mode"]).to.equal(@"en");
  [mock verify];
}


@end
