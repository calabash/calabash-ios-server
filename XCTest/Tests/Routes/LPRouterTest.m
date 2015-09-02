#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPRouter.h"
#import "LPRoute.h"

@interface TestRoute : NSObject <LPRoute>

@end

@implementation TestRoute

@end

@interface LPRouter (LPXCTEST)

+ (id<LPRoute>) routeForKey:(NSString *) key;

@end

@interface LPRouterTest : XCTestCase

@end

@implementation LPRouterTest

- (void)setUp {
  [super setUp];
}

- (void)tearDown {
  [super tearDown];
}

#pragma mark - Adding and Fetching Routes

- (void) testManagingRoutes {
  id <LPRoute> route = [TestRoute new];
  NSString *key = @"test route";

  [LPRouter addRoute:route forPath:key];

  id <LPRoute> fetched = [LPRouter routeForKey:key];
  expect(fetched).to.equal(route);
}

@end
