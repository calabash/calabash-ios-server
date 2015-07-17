#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPInvocationError.h"

@interface LPInvocationErrorTest : XCTestCase

@end

@implementation LPInvocationErrorTest

- (void)setUp {
  [super setUp];
}

- (void)tearDown {
  [super tearDown];
}

- (void) testIsInvocationError {
  LPInvocationError *error = [LPInvocationError new];

  expect([LPInvocationError isInvocationError:error]).to.equal(YES);

  NSObject *object = [NSObject new];

  expect([LPInvocationError isInvocationError:object]).to.equal(NO);
}

- (void) testInitWithType {
  LPInvocationError *error = [[LPInvocationError alloc] initWithType:LPInvocationErrorCannotCoerceSelectorReturnValueToObject];
  expect(error.type).to.equal(LPInvocationErrorCannotCoerceSelectorReturnValueToObject);
}

- (void) testConvenienceInitializers {
  LPInvocationError *error;

  error = [LPInvocationError targetDoesNotRespondToSelector];
  expect(error.type).to.equal(LPInvocationErrorTargetDoesNotRespondToSelector);

  error = [LPInvocationError cannotCoerceReturnValueToObject];
  expect(error.type).to.equal(LPInvocationErrorCannotCoerceSelectorReturnValueToObject);

  error = [LPInvocationError hasAnArgumentTypeEncodingThatCannotBeHandled];
  expect(error.type).to.equal(LPInvocationErrorSelectorHasArgumentsWhoseTypeCannotBeHandled);

  error = [LPInvocationError incorectNumberOfArgumentsProvided];
  expect(error.type).to.equal(LPInvocationErrorIncorrectNumberOfArgumentsProvidedToSelector);

  error = [LPInvocationError unspecifiedInvocationError];
  expect(error.type).to.equal(LPInvocationErrorUnspecifiedInvocationError);
}

@end
