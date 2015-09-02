#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPInvocationError.h"

@interface LPInvocationError (LPXCTEST)

- (id) initWithType:(LPInvocationErrorType) type;

@end

@interface LPInvocationErrorTest : XCTestCase

@end

@implementation LPInvocationErrorTest

- (void)setUp {
  [super setUp];
}

- (void)tearDown {
  [super tearDown];
}


#pragma mark - Initializers

- (void) testInitWithType {
  LPInvocationError *error = [[LPInvocationError alloc] initWithType:LPInvocationErrorCannotCoerceSelectorReturnValueToObject];
  expect(error.type).to.equal(LPInvocationErrorCannotCoerceSelectorReturnValueToObject);
  expect(error.value).to.equal([NSNull null]);
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

  error = [LPInvocationError invokingSelectorOnTargetRaisedAnException];
  expect(error.type).to.equal(LPInvocationErrorInvokingSelectorOnTargetRaisedAnException);

  error = [LPInvocationError unspecifiedInvocationError];
  expect(error.type).to.equal(LPInvocationErrorUnspecifiedInvocationError);
}

#pragma mark - State

- (void) testIsError {
  LPInvocationError *error = [LPInvocationError new];
  expect([error isError]).to.equal(YES);
}

- (void) testIsNSNull {
  LPInvocationError *error = [LPInvocationError new];
  expect([error isNSNull]).to.equal(YES);
}

- (void) testDebugDescription {
  LPInvocationError *error;

  error = [LPInvocationError targetDoesNotRespondToSelector];

  expect([error debugDescription]).to.equal([error description]);
}

- (void) testDescription {
  LPInvocationError *error;

  error = [LPInvocationError targetDoesNotRespondToSelector];
  expect([error description]).to.equal(LPTargetDoesNotRespondToSelector);

  error = [LPInvocationError cannotCoerceReturnValueToObject];
  expect([error description]).to.equal(LPCannotCoerceSelectorReturnValueToObject);

  error = [LPInvocationError hasAnArgumentTypeEncodingThatCannotBeHandled];
  expect([error description]).to.equal(LPSelectorHasArgumentsWhoseTypeCannotBeHandled);

  error = [LPInvocationError incorectNumberOfArgumentsProvided];
  expect([error description]).to.equal(LPIncorrectNumberOfArgumentsProvidedToSelector);

  error = [LPInvocationError invokingSelectorOnTargetRaisedAnException];
  expect([error description]).to.equal(LPInvokingSelectorOnTargetRaisedAnException);

  error = [LPInvocationError unspecifiedInvocationError];
  expect([error description]).to.equal(LPUnspecifiedInvocationError);
}

@end
