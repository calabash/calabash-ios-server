#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPInvoker.h"
#import "LPCoercion.h"
#import "InvokerFactory.h"


@interface LPInvokerSelectorWithArgumentsTest : XCTestCase

@end

@implementation LPInvokerSelectorWithArgumentsTest

- (void) testTargetDoesNotRespondToSelector {
  SEL selector = NSSelectorFromString(@"unknownSelector:");
  NSString *target = @"target";
  id actual = [LPInvoker invokeSelector:selector
                             withTarget:target
                              arguments:@[@(1)]];

  expect(actual).to.equal(LPTargetDoesNotRespondToSelector);
}

- (void) testArgumentCountDoesNotMatch {
  SEL selector = @selector(substringFromIndex:);
  NSString *target = @"target";
  id actual = [LPInvoker invokeSelector:selector
                             withTarget:target
                              arguments:@[]];

  expect(actual).to.equal(LPIncorrectNumberOfArgumentsProvidedToSelector);
}

- (void) testReturnTypeEncodingNotHandled {
  id target = [Target new];
  SEL selector = @selector(selectorThatReturnsVoidStar);

  id actual = [LPInvoker invokeSelector:selector
                             withTarget:target
                              arguments:@[]];
  expect(actual).to.equal(LPSelectorHasUnknownReturnTypeEncoding);
}

- (void) testSelectorHasArgumentWithUnhandledEncoding {
  id target = [Target new];
  SEL selector = @selector(selectorVoidStar:);

  id actual = [LPInvoker invokeSelector:selector
                             withTarget:target
                              arguments:@[@(1)]];
  expect(actual).to.equal(LPSelectorHasArgumentsWhoseTypeCannotBeHandled);
}

@end
