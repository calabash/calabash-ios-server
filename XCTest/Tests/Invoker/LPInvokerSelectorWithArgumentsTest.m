#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPInvoker.h"
#import "InvokerFactory.h"
#import "LPInvocationResult.h"
#import "LPInvocationError.h"

@interface LPInvokerSelectorWithArgumentsTest : XCTestCase

@property(nonatomic, strong) Target *target;

@end

@implementation LPInvokerSelectorWithArgumentsTest

- (void) setUp {
  [super setUp];
  self.target = [Target new];
}

- (void) tearDown {
  self.target = nil;
  [super tearDown];
}

#pragma mark - Exceptional Cases

- (void) testTargetDoesNotRespondToSelector {
  SEL selector = NSSelectorFromString(@"unknownSelector:");
  NSString *string = @"target";
  LPInvocationResult *actual = [LPInvoker invokeSelector:selector
                                              withTarget:string
                                               arguments:@[@(1)]];
  expect([actual isError]).to.equal(YES);
  expect([actual description]).to.equal(LPTargetDoesNotRespondToSelector);
  expect(actual.value).to.equal([NSNull null]);
}

- (void) testArgumentCountDoesNotMatch {
  SEL selector = @selector(substringFromIndex:);
  NSString *string = @"target";
  LPInvocationResult *actual = [LPInvoker invokeSelector:selector
                                              withTarget:string
                                               arguments:@[]];
  expect([actual isError]).to.equal(YES);
  expect([actual description]).to.equal(LPIncorrectNumberOfArgumentsProvidedToSelector);
  expect(actual.value).to.equal([NSNull null]);
}

- (void) testReturnTypeEncodingNotHandled {
  SEL selector = @selector(selectorThatReturnsVoidStar);

  LPInvocationResult *actual = [LPInvoker invokeSelector:selector
                                              withTarget:self.target
                                               arguments:@[]];
  expect([actual isError]).to.equal(YES);
  expect([actual description]).to.equal(LPCannotCoerceSelectorReturnValueToObject);
  expect(actual.value).to.equal([NSNull null]);
}

- (void) testSelectorHasArgumentWithUnhandledEncoding {
  SEL selector = @selector(selectorVoidStar:);

  LPInvocationResult *actual = [LPInvoker invokeSelector:selector
                                              withTarget:self.target
                                               arguments:@[@(1)]];
  expect([actual isError]).to.equal(YES);
  expect([actual description]).to.equal(LPSelectorHasArgumentsWhoseTypeCannotBeHandled);
  expect(actual.value).to.equal([NSNull null]);
}

#pragma mark - Handled Cases

- (void) testArgBOOL_YES {
  SEL selector = [InvokerFactory selectorForArgumentType:@"BOOL YES"];

  LPInvocationResult *actual = [LPInvoker invokeSelector:selector
                                              withTarget:self.target
                                               arguments:@[@(YES)]];
  expect(actual.value).to.equal(@(YES));
}

- (void) testArgBOOL_NO {
  SEL selector = [InvokerFactory selectorForArgumentType:@"BOOL NO"];
  LPInvocationResult *actual =  [LPInvoker invokeSelector:selector
                                               withTarget:self.target
                                                arguments:@[@(NO)]];
  expect(actual.value).to.equal(@(YES));
}

- (void) testArgBool_true {
  SEL selector = [InvokerFactory selectorForArgumentType:@"bool true"];
  LPInvocationResult *actual =  [LPInvoker invokeSelector:selector
                                               withTarget:self.target
                                                arguments:@[@(true)]];
  expect(actual.value).to.equal(@(YES));
}

- (void) testArgBool_false {
  SEL selector = [InvokerFactory selectorForArgumentType:@"bool false"];
  LPInvocationResult *actual =  [LPInvoker invokeSelector:selector
                                               withTarget:self.target
                                                arguments:@[@(false)]];
  expect(actual.value).to.equal(YES);
}

- (void) testArgNSInteger {
  SEL selector = [InvokerFactory selectorForArgumentType:@"NSInteger"];
  LPInvocationResult *actual =  [LPInvoker invokeSelector:selector
                                               withTarget:self.target
                                                arguments:@[@(NSIntegerMin)]];
  expect(actual.value).to.equal(@(YES));
}

- (void) testArgNSUInteger {
  SEL selector = [InvokerFactory selectorForArgumentType:@"NSUInteger"];
  LPInvocationResult *actual =  [LPInvoker invokeSelector:selector
                                               withTarget:self.target
                                                arguments:@[@(NSNotFound)]];
  expect(actual.value).to.equal(YES);
}

- (void) testArgShort {
  SEL selector = [InvokerFactory selectorForArgumentType:@"short"];
  LPInvocationResult *actual =  [LPInvoker invokeSelector:selector
                                               withTarget:self.target
                                                arguments:@[@(SHRT_MIN)]];
  expect(actual.value).to.equal(YES);
}

- (void) testArgUnsignedShort {
  SEL selector = [InvokerFactory selectorForArgumentType:@"unsigned short"];
  LPInvocationResult *actual =  [LPInvoker invokeSelector:selector
                                               withTarget:self.target
                                                arguments:@[@(USHRT_MAX)]];
  expect(actual.value).to.equal(YES);
}

- (void) testArgCGFloat {
  SEL selector = [InvokerFactory selectorForArgumentType:@"CGFloat"];
  LPInvocationResult *actual =  [LPInvoker invokeSelector:selector
                                               withTarget:self.target
                                                arguments:@[@(CGFLOAT_MAX)]];
  expect(actual.value).to.equal(YES);
}

- (void) testArgDouble {
  SEL selector = [InvokerFactory selectorForArgumentType:@"double"];
  LPInvocationResult *actual =  [LPInvoker invokeSelector:selector
                                               withTarget:self.target
                                                arguments:@[@(DBL_MAX)]];
  expect(actual.value).to.equal(YES);
}

- (void) testArgFloat {
  SEL selector = [InvokerFactory selectorForArgumentType:@"float"];
  LPInvocationResult *actual =  [LPInvoker invokeSelector:selector
                                               withTarget:self.target
                                                arguments:@[@(FLT_MAX)]];
  expect(actual.value).to.equal(YES);
}

- (void) testArgChar {
  SEL selector = [InvokerFactory selectorForArgumentType:@"char"];
  LPInvocationResult *actual =  [LPInvoker invokeSelector:selector
                                               withTarget:self.target
                                                arguments:@[@(CHAR_MIN)]];
  expect(actual.value).to.equal(YES);
}

- (void) testArgCharStar {
  SEL selector = [InvokerFactory selectorForArgumentType:@"char *"];
  LPInvocationResult *actual =  [LPInvoker invokeSelector:selector
                                               withTarget:self.target
                                                arguments:@[@"char *"]];
  expect(actual.value).to.equal(YES);
}

- (void) testArgConstCharStar {
  SEL selector = [InvokerFactory selectorForArgumentType:@"const char *"];
  LPInvocationResult *actual =  [LPInvoker invokeSelector:selector
                                               withTarget:self.target
                                                arguments:@[@"const char *"]];
  expect(actual.value).to.equal(YES);
}

- (void) testArgUnsignedChar {
  SEL selector = [InvokerFactory selectorForArgumentType:@"unsigned char"];
  LPInvocationResult *actual =  [LPInvoker invokeSelector:selector
                                               withTarget:self.target
                                                arguments:@[@(UCHAR_MAX)]];
  expect(actual.value).to.equal(YES);
}

- (void) testArgLong {
  SEL selector = [InvokerFactory selectorForArgumentType:@"long"];
  LPInvocationResult *actual =  [LPInvoker invokeSelector:selector
                                               withTarget:self.target
                                                arguments:@[@(LONG_MIN)]];
  expect(actual.value).to.equal(YES);
}

- (void) testArgUnsignedLong {
  SEL selector = [InvokerFactory selectorForArgumentType:@"unsigned long"];
  LPInvocationResult *actual =  [LPInvoker invokeSelector:selector
                                               withTarget:self.target
                                                arguments:@[@(ULONG_MAX)]];
  expect(actual.value).to.equal(YES);
}

- (void) testArgLongLong {
  SEL selector = [InvokerFactory selectorForArgumentType:@"long long"];
  LPInvocationResult *actual =  [LPInvoker invokeSelector:selector
                                               withTarget:self.target
                                                arguments:@[@(LONG_LONG_MIN)]];
  expect(actual.value).to.equal(YES);
}

- (void) testArgUnsignedLongLong {
  SEL selector = [InvokerFactory selectorForArgumentType:@"unsigned long long"];
  LPInvocationResult *actual =  [LPInvoker invokeSelector:selector
                                               withTarget:self.target
                                                arguments:@[@(ULONG_LONG_MAX)]];
  expect(actual.value).to.equal(YES);
}

- (void) testArgCGPointWithCGRectCreate {
  CGPoint point = CGPointMake(1, 2);
  NSDictionary *dict;
  dict = (__bridge_transfer NSDictionary *)CGPointCreateDictionaryRepresentation(point);

  SEL selector = [InvokerFactory selectorForArgumentType:@"CGPoint"];
  LPInvocationResult *actual =  [LPInvoker invokeSelector:selector
                                               withTarget:self.target
                                                arguments:@[dict]];
  expect(actual.value).to.equal(YES);
}

- (void) testArgCGPointWith_xy_Dictionary {
  NSDictionary *point = @{@"x" : @(1), @"y" : @(2)};
  SEL selector = [InvokerFactory selectorForArgumentType:@"CGPoint"];
  LPInvocationResult *actual =  [LPInvoker invokeSelector:selector
                                               withTarget:self.target
                                                arguments:@[point]];
  expect(actual.value).to.equal(YES);
}

- (void) testArgCGPointWith_XY_Dictionary {
  NSDictionary *point = @{@"X" : @(1), @"Y" : @(2)};
  SEL selector = [InvokerFactory selectorForArgumentType:@"CGPoint"];
  LPInvocationResult *actual =  [LPInvoker invokeSelector:selector
                                               withTarget:self.target
                                                arguments:@[point]];
  expect(actual.value).to.equal(YES);
}

- (void) testArgCGRectWithCGRectCreate {
  CGRect rect = CGRectMake(1, 2, 3, 4);

  NSDictionary *dict;
  dict = (__bridge_transfer NSDictionary *)CGRectCreateDictionaryRepresentation(rect);

  SEL selector = [InvokerFactory selectorForArgumentType:@"CGRect"];
  LPInvocationResult *actual =  [LPInvoker invokeSelector:selector
                                               withTarget:self.target
                                                arguments:@[dict]];
  expect(actual.value).to.equal(YES);
}

- (void) testArgCGRectWith_xy_Dictionary {
  NSDictionary *rect =
  @{
    @"x" : @(1),
    @"y" : @(2),
    @"width" : @(3),
    @"height" : @(4)
    };
  SEL selector = [InvokerFactory selectorForArgumentType:@"CGRect"];
  LPInvocationResult *actual =  [LPInvoker invokeSelector:selector
                                               withTarget:self.target
                                                arguments:@[rect]];
  expect(actual.value).to.equal(YES);
}

- (void) testArgCGRectWith_XY_Dictionary {
  NSDictionary *rect =
  @{
    @"X" : @(1),
    @"Y" : @(2),
    @"Width" : @(3),
    @"Height" : @(4)
    };
  SEL selector = [InvokerFactory selectorForArgumentType:@"CGRect"];
  LPInvocationResult *actual =  [LPInvoker invokeSelector:selector
                                               withTarget:self.target
                                                arguments:@[rect]];
  expect(actual.value).to.equal(YES);
}

- (void) testIsPointRaisesIfNotDictionary {
  SEL selector = [InvokerFactory selectorForArgumentType:@"CGPoint"];

  LPInvocationResult *actual = [LPInvoker invokeSelector:selector
                                              withTarget:self.target
                                               arguments:@[@"not a dictionary"]];
  expect([actual isError]).to.equal(YES);
  expect([actual description]).to.equal(LPSelectorHasArgumentsWhoseTypeCannotBeHandled);
  expect(actual.value).to.equal([NSNull null]);
}

- (void) testIsRectRaisesIfNotDictionary {
  SEL selector = [InvokerFactory selectorForArgumentType:@"CGRect"];

  LPInvocationResult *actual = [LPInvoker invokeSelector:selector
                                              withTarget:self.target
                                               arguments:@[@"not a dictionary"]];
  expect([actual isError]).to.equal(YES);
  expect([actual description]).to.equal(LPSelectorHasArgumentsWhoseTypeCannotBeHandled);
  expect(actual.value).to.equal([NSNull null]);
}

- (void) testArgClassWithClass {
  SEL selector = [InvokerFactory selectorForArgumentType:@"Class"];
  LPInvocationResult *actual =  [LPInvoker invokeSelector:selector
                                               withTarget:self.target
                                                arguments:@[[NSArray class]]];
  expect(actual.value).to.equal(YES);
}

- (void) testArgClassWithString {
  SEL selector = [InvokerFactory selectorForArgumentType:@"Class"];
  LPInvocationResult *actual =  [LPInvoker invokeSelector:selector
                                               withTarget:self.target
                                                arguments:@[@"NSArray"]];
  expect(actual.value).to.equal(YES);
}

- (void) testArgId {
  SEL selector = [InvokerFactory selectorForArgumentType:@"object pointer"];
  LPInvocationResult *actual =  [LPInvoker invokeSelector:selector
                                               withTarget:self.target
                                                arguments:@[[InvokerFactory shared]]];

  expect(actual.value).to.equal(YES);
}

- (void) testSelfArg {
  SEL selector = [InvokerFactory selectorForArgumentType:@"self"];
  LPInvocationResult *actual =  [LPInvoker invokeSelector:selector
                                               withTarget:self.target
                                                arguments:@[@"__self__"]];
  expect(actual.value).to.equal(YES);
}

- (void) selfNilArg {
  SEL selector = [InvokerFactory selectorForArgumentType:@"nil"];
  LPInvocationResult *actual =  [LPInvoker invokeSelector:selector
                                               withTarget:self.target
                                                arguments:@[@"__nil__"]];
  expect(actual.value).to.equal(YES);
}

@end
