#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPInvoker.h"
#import "LPCoercion.h"
#import "InvokerFactory.h"


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
  id actual = [LPInvoker invokeSelector:selector
                             withTarget:string
                              arguments:@[@(1)]];

  expect(actual).to.equal(LPTargetDoesNotRespondToSelector);
}

- (void) testArgumentCountDoesNotMatch {
  SEL selector = @selector(substringFromIndex:);
  NSString *string = @"target";
  id actual = [LPInvoker invokeSelector:selector
                             withTarget:string
                              arguments:@[]];

  expect(actual).to.equal(LPIncorrectNumberOfArgumentsProvidedToSelector);
}

- (void) testReturnTypeEncodingNotHandled {
  SEL selector = @selector(selectorThatReturnsVoidStar);

  id actual = [LPInvoker invokeSelector:selector
                             withTarget:self.target
                              arguments:@[]];
  expect(actual).to.equal(LPSelectorHasUnknownReturnTypeEncoding);
}

- (void) testSelectorHasArgumentWithUnhandledEncoding {
  SEL selector = @selector(selectorVoidStar:);

  id actual = [LPInvoker invokeSelector:selector
                             withTarget:self.target
                              arguments:@[@(1)]];
  expect(actual).to.equal(LPSelectorHasArgumentsWhoseTypeCannotBeHandled);
}

#pragma mark - Handled Cases

- (void) testArgBOOL_YES {
  SEL selector = [InvokerFactory selectorForArgumentType:@"BOOL YES"];

  id actual = [LPInvoker invokeSelector:selector
                             withTarget:self.target
                              arguments:@[@(YES)]];
  expect(actual).to.equal(@(YES));
}

- (void) testArgBOOL_NO {
  SEL selector = [InvokerFactory selectorForArgumentType:@"BOOL NO"];
  id actual =  [LPInvoker invokeSelector:selector
                              withTarget:self.target
                               arguments:@[@(NO)]];
  expect(actual).to.equal(@(YES));
}

- (void) testArgBool_true {
  SEL selector = [InvokerFactory selectorForArgumentType:@"bool true"];
  id actual =  [LPInvoker invokeSelector:selector
                              withTarget:self.target
                               arguments:@[@(true)]];
  expect(actual).to.equal(@(YES));
}

- (void) testArgBool_false {
  SEL selector = [InvokerFactory selectorForArgumentType:@"bool false"];
  id actual =  [LPInvoker invokeSelector:selector
                              withTarget:self.target
                               arguments:@[@(false)]];
  expect(actual).to.equal(YES);
}

- (void) testArgNSInteger {
  SEL selector = [InvokerFactory selectorForArgumentType:@"NSInteger"];
  id actual =  [LPInvoker invokeSelector:selector
                              withTarget:self.target
                               arguments:@[@(NSIntegerMin)]];
  expect(actual).to.equal(@(YES));
}

- (void) testArgNSUInteger {
  SEL selector = [InvokerFactory selectorForArgumentType:@"NSUInteger"];
  id actual =  [LPInvoker invokeSelector:selector
                              withTarget:self.target
                               arguments:@[@(NSNotFound)]];
  expect(actual).to.equal(YES);
}

- (void) testArgShort {
  SEL selector = [InvokerFactory selectorForArgumentType:@"short"];
  id actual =  [LPInvoker invokeSelector:selector
                              withTarget:self.target
                               arguments:@[@(SHRT_MIN)]];
  expect(actual).to.equal(YES);
}

- (void) testArgUnsignedShort {
  SEL selector = [InvokerFactory selectorForArgumentType:@"unsigned short"];
  id actual =  [LPInvoker invokeSelector:selector
                              withTarget:self.target
                               arguments:@[@(USHRT_MAX)]];
  expect(actual).to.equal(YES);
}

- (void) testArgCGFloat {
  SEL selector = [InvokerFactory selectorForArgumentType:@"CGFloat"];
  id actual =  [LPInvoker invokeSelector:selector
                              withTarget:self.target
                               arguments:@[@(CGFLOAT_MAX)]];
  expect(actual).to.equal(YES);
}

- (void) testArgDouble {
  SEL selector = [InvokerFactory selectorForArgumentType:@"double"];
  id actual =  [LPInvoker invokeSelector:selector
                              withTarget:self.target
                               arguments:@[@(DBL_MAX)]];
  expect(actual).to.equal(YES);
}

- (void) testArgFloat {
  SEL selector = [InvokerFactory selectorForArgumentType:@"float"];
  id actual =  [LPInvoker invokeSelector:selector
                              withTarget:self.target
                               arguments:@[@(FLT_MAX)]];
  expect(actual).to.equal(YES);
}

- (void) testArgChar {
  SEL selector = [InvokerFactory selectorForArgumentType:@"char"];
  id actual =  [LPInvoker invokeSelector:selector
                              withTarget:self.target
                               arguments:@[@(CHAR_MIN)]];
  expect(actual).to.equal(YES);
}

- (void) testArgCharStar {
  SEL selector = [InvokerFactory selectorForArgumentType:@"char *"];
  id actual =  [LPInvoker invokeSelector:selector
                              withTarget:self.target
                               arguments:@[@"char *"]];
  expect(actual).to.equal(YES);
}

- (void) testArgConstCharStar {
  SEL selector = [InvokerFactory selectorForArgumentType:@"const char *"];
  id actual =  [LPInvoker invokeSelector:selector
                              withTarget:self.target
                               arguments:@[@"const char *"]];
  expect(actual).to.equal(YES);
}

- (void) testArgUnsignedChar {
  SEL selector = [InvokerFactory selectorForArgumentType:@"unsigned char"];
  id actual =  [LPInvoker invokeSelector:selector
                              withTarget:self.target
                               arguments:@[@(UCHAR_MAX)]];
  expect(actual).to.equal(YES);
}

- (void) testArgLong {
  SEL selector = [InvokerFactory selectorForArgumentType:@"long"];
  id actual =  [LPInvoker invokeSelector:selector
                              withTarget:self.target
                               arguments:@[@(LONG_MIN)]];
  expect(actual).to.equal(YES);
}

- (void) testArgUnsignedLong {
  SEL selector = [InvokerFactory selectorForArgumentType:@"unsigned long"];
  id actual =  [LPInvoker invokeSelector:selector
                              withTarget:self.target
                               arguments:@[@(ULONG_MAX)]];
  expect(actual).to.equal(YES);
}

- (void) testArgLongLong {
  SEL selector = [InvokerFactory selectorForArgumentType:@"long long"];
  id actual =  [LPInvoker invokeSelector:selector
                              withTarget:self.target
                               arguments:@[@(LONG_LONG_MIN)]];
  expect(actual).to.equal(YES);
}

- (void) testArgUnsignedLongLong {
  SEL selector = [InvokerFactory selectorForArgumentType:@"unsigned long long"];
  id actual =  [LPInvoker invokeSelector:selector
                              withTarget:self.target
                               arguments:@[@(ULONG_LONG_MAX)]];
  expect(actual).to.equal(YES);
}

- (void) testArgCGPointWithCGRectCreate {
  CGPoint point = CGPointMake(1, 2);
  NSDictionary *dict;
  dict = (__bridge_transfer NSDictionary *)CGPointCreateDictionaryRepresentation(point);

  SEL selector = [InvokerFactory selectorForArgumentType:@"CGPoint"];
  id actual =  [LPInvoker invokeSelector:selector
                              withTarget:self.target
                               arguments:@[dict]];
  expect(actual).to.equal(YES);
}

- (void) testArgCGRectWithCGRectCreate {
  CGRect rect = CGRectMake(1, 2, 3, 4);

  NSDictionary *dict;
  dict = (__bridge_transfer NSDictionary *)CGRectCreateDictionaryRepresentation(rect);

  SEL selector = [InvokerFactory selectorForArgumentType:@"CGRect"];
  id actual =  [LPInvoker invokeSelector:selector
                              withTarget:self.target
                               arguments:@[dict]];
  expect(actual).to.equal(YES);
}

- (void) testArgClassWithClass {
  SEL selector = [InvokerFactory selectorForArgumentType:@"Class"];
  id actual =  [LPInvoker invokeSelector:selector
                              withTarget:self.target
                               arguments:@[[NSArray class]]];
  expect(actual).to.equal(YES);
}

- (void) testArgClassWithString {
  SEL selector = [InvokerFactory selectorForArgumentType:@"Class"];
  id actual =  [LPInvoker invokeSelector:selector
                              withTarget:self.target
                               arguments:@[@"NSArray"]];
  expect(actual).to.equal(YES);
}

- (void) testArgId {
  SEL selector = [InvokerFactory selectorForArgumentType:@"object pointer"];
  id actual =  [LPInvoker invokeSelector:selector
                              withTarget:self.target
                               arguments:@[[InvokerFactory shared]]];
  expect(actual).to.equal(YES);
}

@end
