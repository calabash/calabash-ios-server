#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPQueryAllOperation.h"

@interface LPQueryAllOperation (LPXCTEST)

- (SEL) selectorByParsingValuesFromArray:(NSArray *) array
                    arguments:(NSMutableArray *) arguments;
- (void) setQueryArguments:(NSArray *) arguments;

@end

@interface TestObject : NSObject

- (NSArray *) arrayWithCount:(NSUInteger) count
                      length:(NSUInteger) length
                        name:(NSString *) name;

- (NSUInteger) collectionView:(id) view numberOfItemsInSection:(NSInteger) section;
@end

@implementation TestObject

- (NSArray *) arrayWithCount:(NSUInteger) count
                      length:(NSUInteger) length
                        name:(NSString *) name {
  return @[@(count), @(length), name];
}

- (NSUInteger) collectionView:(id) view numberOfItemsInSection:(NSInteger) section {
  return section;
}

@end

@interface LPQueryAllOperationTest : XCTestCase

@end

@implementation LPQueryAllOperationTest

- (void)setUp {
  [super setUp];
  // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each test method in the class.
  [super tearDown];
}

- (void) testSelectorWithArgument {
  NSArray *array = @[@{@"setText" : @"new text"}];
  NSMutableArray *arguments = [@[] mutableCopy];
  NSString *expected = @"setText:";

  LPQueryAllOperation *operation = [[LPQueryAllOperation alloc] init];
  SEL selector = [operation selectorByParsingValuesFromArray:array
                                                   arguments:arguments];
  NSString *actual = NSStringFromSelector(selector);
  expect(actual).to.equal(expected);
}

// [{collectionView:'__self__'},  {numberOfItemsInSection:0}])
- (void) testSelectorWithLastArgIsPrimative {
  NSArray *array = @[@{@"collectionView" : @"__self__"},
                     @{@"numberOfItemsInSection" : @(0)}];
  NSMutableArray *arguments = [@[] mutableCopy];
  NSString *expected = @"collectionView:numberOfItemsInSection:";

  LPQueryAllOperation *operation = [[LPQueryAllOperation alloc] init];
  SEL selector = [operation selectorByParsingValuesFromArray:array
                                                   arguments:arguments];
  NSString *actual = NSStringFromSelector(selector);
  expect(actual).to.equal(expected);
}

- (void) testSelectorWithFirstArgumentIsPrimative {
  NSArray *array =  @[@{@"arrayWithCount" : @(0)},
                      @{@"length" : @(1)},
                      @{@"name" : @"name"}];
  NSMutableArray *arguments = [@[] mutableCopy];
  NSString *expected = @"arrayWithCount:length:name:";
  LPQueryAllOperation *operation = [[LPQueryAllOperation alloc] init];
  SEL selector = [operation selectorByParsingValuesFromArray:array
                                                   arguments:arguments];

  NSString *actual = NSStringFromSelector(selector);

  expect(actual).to.equal(expected);
}

@end
