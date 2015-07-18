#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPOperation.h"

@interface LPOperationTest : XCTestCase

@end

@implementation LPOperationTest

- (void)setUp {
  [super setUp];
}

- (void)tearDown {
  [super tearDown];
}

- (void) testDescription {
  NSDictionary *dictionary =
  @{@"method_name" : @"appendString:withString:",
    @"arguments" : @[@"A string", @": appended"]};

  LPOperation *operation = [[LPOperation alloc] initWithOperation:dictionary];

  NSString *actual = [operation description];
  NSString *expected = @"<LPOperation 'appendString:withString:' with arguments 'A string, : appended'>";
  expect(actual).to.equal(expected);
}

- (void) testPerformSelectorNoArguments {
  NSDictionary *dictionary = @{@"method_name" : @"length",
                               @"arguments" : @[]};

  LPOperation *operation = [[LPOperation alloc] initWithOperation:dictionary];
  NSError *error = nil;
  id actual = [operation performWithTarget:@"string" error:&error];

  expect(actual).to.equal(@(@"string".length));
  expect(error).to.equal(nil);
}

- (void) testPerformSelectorOneArgument {
  NSDictionary *dictionary = @{@"method_name" : @"addObject:",
                               @"arguments" : @[@"arg!"]};

  LPOperation *operation = [[LPOperation alloc] initWithOperation:dictionary];
  NSError *error = nil;

  NSMutableArray *array = [@[] mutableCopy];
  id actual = [operation performWithTarget:array error:&error];

  //expect(actual).to.equal(@(@"string".length));
  expect(error).to.equal(nil);
  expect(actual).to.equal(@"<VOID>");
  expect(array[0]).to.equal(@"arg!");
}

@end
