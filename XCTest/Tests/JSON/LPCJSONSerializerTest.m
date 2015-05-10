#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPCJSONSerializer.h"
#import "LPJSONRepresentation.h"

@interface LPCJSONSerializer (LPXCTEST)

- (Class) classForNSManagedObject;
- (BOOL) isCoreDataStackAvailable;
- (BOOL) isNSManagedObject:(id) object;
- (SEL) descriptionSelector;
- (NSData *) serializeInvalidJSONObject:(id) object error:(NSError **) outError;

@end

@interface LPJsonifiable : NSObject <LPJSONRepresentation>

@end

@implementation LPJsonifiable

- (NSData *) JSONDataRepresentation {
  return [[NSString stringWithFormat:@"data"]
          dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSString *) description {
  return @"json";
}

@end

@interface LPHasNilDescription : NSObject

@end

@implementation LPHasNilDescription

- (NSString *) description {
  return nil;
}

@end

SpecBegin(LPCJSONSerializer)

describe(@"LPCJSONSerializer", ^{

  __block LPCJSONSerializer *serializer;
  __block NSError *error;
  __block NSData *data;
  __block NSData *mockData;
  __block id mock;
  before(^{
    serializer = [LPCJSONSerializer serializer];
    error = nil;
    mockData = [[NSString stringWithFormat:@"data"]
                dataUsingEncoding:NSUTF8StringEncoding];
    mock = OCMPartialMock(serializer);
  });

  describe(@"#isValidJSONObject:", ^{
    describe(@"returns true for", ^{
      describe(@"NSNull, nil, and NULL", ^{
        it(@"NSNull", ^{
          expect([serializer isValidJSONObject:[NSNull null]]).to.equal(YES);
        });

        it(@"nil", ^{
          expect([serializer isValidJSONObject:nil]).to.equal(YES);
        });

        it(@"NULL", ^{
          expect([serializer isValidJSONObject:NULL]).to.equal(YES);
        });
      });

      it(@"NSNumber", ^{
        expect([serializer isValidJSONObject:@(1)]).to.equal(YES);
      });

      it(@"NSString", ^{
        expect([serializer isValidJSONObject:@"Hey!"]).to.equal(YES);
      });

      it(@"NSArray", ^{
        expect([serializer isValidJSONObject:@[]]).to.equal(YES);
      });

      it(@"NSDictionary", ^{
        expect([serializer isValidJSONObject:@{}]).to.equal(YES);
      });

      it(@"NSData", ^{
        expect([serializer isValidJSONObject:[[NSData alloc] init]]).to.equal(YES);
      });

      it(@"NSDate", ^{
        expect([serializer isValidJSONObject:[NSDate date]]).to.equal(YES);
      });

      it(@"responds to JSONDataRepresentation", ^{
        LPJsonifiable *json = [LPJsonifiable new];
        expect([serializer isValidJSONObject:json]).to.equal(YES);
      });
    });

    describe(@"returns false for", ^{
      it(@"NSObject", ^{
        expect([serializer isValidJSONObject:[NSObject new]]).to.equal(NO);
      });

      it(@"UIView", ^{
        UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
        expect([serializer isValidJSONObject:view]).to.equal(NO);
      });

      it(@"NSManagedObject", ^{

      });
    });

  });

  describe(@"#serializeObject:error:", ^{

    describe(@"valid JSON objects", ^{
      it(@"NSNull", ^{
        [[[mock expect] andReturn:mockData] serializeNull:OCMOCK_ANY
                                                    error:[OCMArg setTo:nil]];
        data = [mock serializeObject:[NSNull null] error:&error];
        [mock verify];
        expect(data).to.beIdenticalTo(mockData);
        expect(error).to.equal(nil);
      });

      it(@"NSNumber", ^{
        [[[mock expect] andReturn:mockData] serializeNumber:OCMOCK_ANY
                                                      error:[OCMArg setTo:nil]];
        data = [mock serializeObject:@(1) error:&error];
        [mock verify];
        expect(data).to.beIdenticalTo(mockData);
        expect(error).to.equal(nil);
      });

      it(@"NSString", ^{
        [[[mock stub] andReturn:mockData] serializeString:OCMOCK_ANY
                                                    error:[OCMArg setTo:nil]];
        data = [mock serializeObject:@"Right on!" error:&error];
        [mock verify];
        expect(data).to.beIdenticalTo(mockData);
        expect(error).to.equal(nil);

      });

      it(@"NSArray", ^{
        [[[mock expect] andReturn:mockData] serializeArray:OCMOCK_ANY
                                                     error:[OCMArg setTo:nil]];
        data = [mock serializeObject:@[] error:&error];
        [mock verify];
        expect(data).to.beIdenticalTo(mockData);
        expect(error).to.equal(nil);
      });

      it(@"NSDictionary", ^{
        [[[mock expect] andReturn:mockData] serializeDictionary:OCMOCK_ANY
                                                          error:[OCMArg setTo:nil]];

        data = [mock serializeObject:@{} error:&error];
        [mock verify];
        expect(data).to.beIdenticalTo(mockData);
        expect(error).to.equal(nil);
      });

      it(@"NSData", ^{
        [[[mock expect] andReturn:mockData] serializeString:OCMOCK_ANY
                                                      error:[OCMArg setTo:nil]];
        data = [mock serializeObject:[[NSData alloc] init] error:&error];
        [mock verify];
        expect(data).to.beIdenticalTo(mockData);
        expect(error).to.equal(nil);
      });

      it(@"NSDate", ^{
        [[[mock expect] andReturn:mockData] serializeDate:OCMOCK_ANY
                                                    error:[OCMArg setTo:nil]];
        data = [mock serializeObject:[NSDate date] error:&error];
        [mock verify];
        expect(data).to.beIdenticalTo(mockData);
        expect(error).to.equal(nil);
      });

      it(@"responds to JSONDataRepresentation", ^{
        LPJsonifiable *json = [LPJsonifiable new];
        mock = OCMPartialMock(json);
        [[[mock expect] andReturn:mockData] JSONDataRepresentation];
        data = [serializer serializeObject:mock error:&error];
        [mock verify];
        expect(data).to.beIdenticalTo(mockData);
        expect(error).to.equal(nil);
      });
    });

    describe(@"nil and NULL", ^{
      it(@"nil", ^{
        [[[mock expect] andReturn:mockData] serializeNull:OCMOCK_ANY
                                                    error:[OCMArg setTo:nil]];
        data = [mock serializeObject:nil error:&error];
        [mock verify];
        expect(data).to.beIdenticalTo(mockData);
        expect(error).to.equal(nil);
      });

      it(@"NULL", ^{
        [[[mock expect] andReturn:mockData] serializeNull:OCMOCK_ANY
                                                    error:[OCMArg setTo:nil]];
        data = [mock serializeObject:NULL error:&error];
        [mock verify];
        expect(data).to.beIdenticalTo(mockData);
        expect(error).to.equal(nil);
      });
    });

    describe(@"arbitrary NSObjects", ^{
      it(@"NSObject", ^{

      });

      it(@"UIView", ^{

      });

      it(@"NSManagedObject", ^{

      });
    });
  });

  it(@"#serializeDate:error:", ^{
    [[[mock expect] andReturn:mockData] serializeString:OCMOCK_ANY
                                                  error:[OCMArg setTo:nil]];
    data = [mock serializeDate:[NSDate date] error:&error];
    [mock verify];
    expect(data).to.beIdenticalTo(mockData);
    expect(error).to.equal(nil);
  });

  describe(@"#isCoreDataStackAvailable", ^{
    it(@"returns YES when stack is available", ^{
      [[[mock expect] andReturn:[self class] ] classForNSManagedObject];
      expect([mock isCoreDataStackAvailable]).to.equal(YES);
      [mock verify];
    });

    it(@"returns NO when stack is not available", ^{
      [[[mock expect] andReturn:nil] classForNSManagedObject];
      expect([mock isCoreDataStackAvailable]).to.equal(NO);
      [mock verify];
    });
  });

  describe(@"#isNSManagedObject:", ^{
    it(@"returns YES when object is an NSManagedObject", ^{
      [[[mock expect] andReturn:[self class] ] classForNSManagedObject];
      expect([mock isNSManagedObject:self]).to.equal(YES);
      [mock verify];
    });

    it(@"returns NO when object is not an NSManagedObject", ^{
      expect([mock isNSManagedObject:self]).to.equal(NO);
    });
  });

  it(@"descriptionSelector", ^{
    expect([serializer descriptionSelector]).to.equal(@selector(description));
  });

  describe(@"#serializeInvalidJSONObject:error:", ^{
    it(@"does not respond to description selector", ^{
      SEL mockSelector = NSSelectorFromString(@"noSuchSelector");
      [[[mock expect] andReturnValue:OCMOCK_VALUE(mockSelector)] descriptionSelector];
      NSObject *object = [NSObject new];

      NSString *expected = [NSString stringWithFormat:@"\"%@\"",
                            [NSString stringWithFormat:LPJSONSerializerDoesNotRespondToDescriptionFormatString,
                             NSStringFromClass([object class])]];
      data = [mock serializeInvalidJSONObject:object error:&error];

      NSString *actual = [[NSString alloc] initWithBytes:[data bytes]
                                                  length:[data length]
                                                encoding:NSUTF8StringEncoding];

      expect(actual).to.equal(expected);
      expect(error).to.equal(nil);
      [mock verify];
    });

    it(@"description selector returns nil", ^{
      LPHasNilDescription *hasNil = [LPHasNilDescription new];
      [[[mock expect] andReturn:mockData] serializeNull:OCMOCK_ANY
                                                  error:[OCMArg setTo:nil]];
      data = [mock serializeInvalidJSONObject:hasNil error:&error];
      expect(data).to.beIdenticalTo(mockData);
      expect(error).to.equal(nil);
      [mock verify];
    });

    it(@"description is non-nil", ^{
      [[[mock expect] andReturn:mockData] serializeString:OCMOCK_ANY
                                                    error:[OCMArg setTo:nil]];

      NSObject *object = [NSObject new];
      data = [mock serializeInvalidJSONObject:object error:&error];
      expect(data).to.beIdenticalTo(mockData);
      expect(error).to.equal(nil);
      [mock verify];
    });

    it(@"NSObject", ^{
      LPJsonifiable *json = [LPJsonifiable new];
      data = [serializer serializeInvalidJSONObject:json error:&error];
      NSString *string = [[NSString alloc] initWithBytes:[data bytes]
                                                  length:[data length]
                                                  encoding:NSUTF8StringEncoding];
      expect(string).to.equal([NSString stringWithFormat:@"\"%@\"",
                               [json description]]);
      expect(error).to.equal(nil);
    });

    it(@"UIView", ^{
      UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
      data = [serializer serializeInvalidJSONObject:view error:&error];
      NSString *string = [[NSString alloc] initWithBytes:[data bytes]
                                                  length:[data length]
                                                encoding:NSUTF8StringEncoding];
      expect(string).to.equal([NSString stringWithFormat:@"\"%@\"",
                               [view description]]);
      expect(error).to.equal(nil);

    });

    it(@"NSManagedObject", ^{
      NSObject *object = [NSObject new];
      BOOL yes = YES;
      [[[mock expect] andReturnValue:OCMOCK_VALUE(yes)] isCoreDataStackAvailable];
      [[[mock expect] andReturnValue:OCMOCK_VALUE(yes)] isNSManagedObject:object];
      NSString *expected = [NSString stringWithFormat:@"\"%@\"",
                            [NSString stringWithFormat:LPJSONSerializerNSManageObjectFormatString,
                             NSStringFromClass([object class])]];

      data = [mock serializeInvalidJSONObject:object error:&error];
      NSString *actual = [[NSString alloc] initWithBytes:[data bytes]
                                                  length:[data length]
                                                encoding:NSUTF8StringEncoding];
      expect(actual).to.equal(expected);
      expect(error).to.equal(nil);
      [mock verify];
    });
  });
});

SpecEnd
