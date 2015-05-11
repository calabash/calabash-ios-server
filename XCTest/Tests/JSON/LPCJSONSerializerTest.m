#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPCJSONSerializer.h"
#import "LPJSONRepresentation.h"
#import "AppDelegate.h"
#import <CoreData/CoreData.h>

@interface LPCJSONSerializer (LPXCTEST)

- (BOOL)isValidJSONObject:(id)inObject;
- (Class) classForNSManagedObject;
- (BOOL) isCoreDataStackAvailable;
- (BOOL) isNSManagedObject:(id) object;
- (SEL) descriptionSelector;

- (NSData *) serializeNull:(NSNull *) inNull error:(NSError **) outError;
- (NSData *) serializeNumber:(NSNumber *) inNumber error:(NSError **) outError;
- (NSData *) serializeString:(NSString *) inString error:(NSError **) outError;
- (NSData *) serializeDate:(NSDate *) date error:(NSError **) outError;
- (NSData *) serializeDictionary:(NSDictionary *) inDictionary error:(NSError **) outError;
- (NSData *) serializeArray:(NSArray *) inArray error:(NSError **) outError;
- (NSData *) serializeInvalidJSONObject:(id) object error:(NSError **) outError;
- (NSData *) serializeObject:(id)inObject error:(NSError **) outError;

- (NSString *) stringByDecodingNSData:(NSData *) data;

@end

@interface LPJsonifiable : NSObject <LPJSONRepresentation>

@end

@implementation LPJsonifiable

- (NSData *) JSONDataRepresentation {
  return [[NSString stringWithFormat:@"LPJsonifiable: JSONRepresentation"]
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

@interface LPDescriptionRaisesException : NSObject

@end

@implementation LPDescriptionRaisesException

- (NSString *) description {
  NSString *reason = @"Simulating case where calling `description` raises an error";
  @throw [NSException exceptionWithName:@"Testing Exception"
                                 reason:reason
                               userInfo:@{}];
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
    mockData = [[NSString stringWithFormat:@"mock data"]
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
    });
  });

  describe(@"#serializeObject:error:", ^{

    describe(@"valid JSON objects", ^{
      it(@"NSNull", ^{
        [[[mock expect] andReturn:mockData] serializeNull:OCMOCK_ANY
                                                    error:[OCMArg setTo:error]];
        data = [mock serializeObject:[NSNull null] error:&error];
        [mock verify];
        expect(data).to.beIdenticalTo(mockData);
        expect(error).to.equal(nil);
      });

      it(@"NSNumber", ^{
        [[[mock expect] andReturn:mockData] serializeNumber:OCMOCK_ANY
                                                      error:[OCMArg setTo:error]];
        data = [mock serializeObject:@(1) error:&error];
        [mock verify];
        expect(data).to.beIdenticalTo(mockData);
        expect(error).to.equal(nil);
      });

      it(@"NSString", ^{
        [[[mock stub] andReturn:mockData] serializeString:OCMOCK_ANY
                                                    error:[OCMArg setTo:error]];
        data = [mock serializeObject:@"Right on!" error:&error];
        [mock verify];
        expect(data).to.beIdenticalTo(mockData);
        expect(error).to.equal(nil);

      });

      it(@"NSArray", ^{
        [[[mock expect] andReturn:mockData] serializeArray:OCMOCK_ANY
                                                     error:[OCMArg setTo:error]];
        data = [mock serializeObject:@[] error:&error];
        [mock verify];
        expect(data).to.beIdenticalTo(mockData);
        expect(error).to.equal(nil);
      });

      it(@"NSDictionary", ^{
        [[[mock expect] andReturn:mockData] serializeDictionary:OCMOCK_ANY
                                                          error:[OCMArg setTo:error]];

        data = [mock serializeObject:@{} error:&error];
        [mock verify];
        expect(data).to.beIdenticalTo(mockData);
        expect(error).to.equal(nil);
      });

      it(@"NSData", ^{
        [[[mock expect] andReturn:mockData] serializeString:OCMOCK_ANY
                                                      error:[OCMArg setTo:error]];
        data = [mock serializeObject:[[NSData alloc] init] error:&error];
        [mock verify];
        expect(data).to.beIdenticalTo(mockData);
        expect(error).to.equal(nil);
      });

      it(@"NSDate", ^{
        [[[mock expect] andReturn:mockData] serializeDate:OCMOCK_ANY
                                                    error:[OCMArg setTo:error]];
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
                                                    error:[OCMArg setTo:error]];
        data = [mock serializeObject:nil error:&error];
        [mock verify];
        expect(data).to.beIdenticalTo(mockData);
        expect(error).to.equal(nil);
      });

      it(@"NULL", ^{
        [[[mock expect] andReturn:mockData] serializeNull:OCMOCK_ANY
                                                    error:[OCMArg setTo:error]];
        data = [mock serializeObject:NULL error:&error];
        [mock verify];
        expect(data).to.beIdenticalTo(mockData);
        expect(error).to.equal(nil);
      });
    });

    describe(@"Returns NULL when object is invalid JSON object", ^{
      it(@"NSObject", ^{
        data = [serializer serializeObject:[NSObject new] error:&error];
        expect(data).to.equal(NULL);
        expect(error).notTo.equal(nil);
      });

      it(@"UIView", ^{
        data = [serializer serializeObject:[[UIView alloc] initWithFrame:CGRectZero]
                                     error:&error];
        expect(data).to.equal(NULL);
        expect(error).notTo.equal(nil);
      });
    });
  });

  it(@"#serializeDate:error:", ^{
    [[[mock expect] andReturn:mockData] serializeString:OCMOCK_ANY
                                                  error:[OCMArg setTo:error]];
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
                                                  error:[OCMArg setTo:error]];
      data = [mock serializeInvalidJSONObject:hasNil error:&error];
      expect(data).to.beIdenticalTo(mockData);
      expect(error).to.equal(nil);
      [mock verify];
    });

    it(@"description is non-nil", ^{
      [[[mock expect] andReturn:mockData] serializeString:OCMOCK_ANY
                                                    error:[OCMArg setTo:error]];

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
      LPDescriptionRaisesException *object = [LPDescriptionRaisesException new];
      BOOL yes = YES;
      [[[mock expect] andReturnValue:OCMOCK_VALUE(yes)] isCoreDataStackAvailable];
      [[[mock expect] andReturnValue:OCMOCK_VALUE(yes)] isNSManagedObject:object];
      NSString *expected = [NSString stringWithFormat:@"\"%@\"",
                            [NSString stringWithFormat:LPJSONSerializerNSManageObjectDescriptionFaultFormatString,
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

  describe(@"Handling NSManagedObjects", ^{
    __block NSManagedObjectContext *context;
    before(^{
      AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication]
                                              delegate];
      context = delegate.managedObjectContext;
      [context reset];
      NSError *coreDataSaveError = nil;
      BOOL success = [context save:&coreDataSaveError];
      if (!success) {
        NSLog(@"%@", coreDataSaveError);
        abort();
      }
    });

    it(@"#isNSManagedObject:", ^{
      NSManagedObject *server =
      [NSEntityDescription insertNewObjectForEntityForName:@"Server"
                                    inManagedObjectContext:context];
      expect([serializer isNSManagedObject:server]).to.equal(YES);
    });

    describe(@"#serializeInvalidJSONObject:error", ^{
      it(@"calling description raises no exception", ^{
        NSManagedObject *server =
        [NSEntityDescription insertNewObjectForEntityForName:@"Server"
                                      inManagedObjectContext:context];
        data = [serializer serializeInvalidJSONObject:server error:&error];
        NSString *actual = [[NSString alloc] initWithBytes:[data bytes]
                                                    length:[data length]
                                                  encoding:NSUTF8StringEncoding];

        expect([actual hasPrefix:@"\"<LPServerEntity"]).to.equal(YES);
      });

      it(@"calling description raises an exception", ^{
        NSManagedObject *server =
        [NSEntityDescription insertNewObjectForEntityForName:@"Server"
                                      inManagedObjectContext:context];

        // Turn the server into a fault.
        [context deleteObject:server];
        expect([context save:&error]).to.equal(YES);
        expect(error).to.equal(nil);

        NSString *expected = [NSString stringWithFormat:@"\"%@\"",
                              [NSString stringWithFormat:LPJSONSerializerNSManageObjectDescriptionFaultFormatString,
                               NSStringFromClass([server class])]];

        data = [serializer serializeInvalidJSONObject:server error:&error];
        NSString *actual = [[NSString alloc] initWithBytes:[data bytes]
                                                    length:[data length]
                                                  encoding:NSUTF8StringEncoding];
        expect(actual).to.equal(expected);
      });
    });
  });

  describe(@"#serilizeArray:error", ^{
    it(@"can serialize an array of valid JSON objects", ^{
      NSArray *array = @[@(9999),
                         @"string",
                         [NSDate date],
                         mockData,
                         @{@"key" : @"value"},
                         @[@(1), @(2), @(3)],
                         [LPJsonifiable new],
                         [NSNull null]];
      data = [serializer serializeArray:array error:&error];

      NSString *actual = [[NSString alloc] initWithBytes:[data bytes]
                                                  length:[data length]
                                                encoding:NSUTF8StringEncoding];

      // Skip the date checking; too difficult.
      expect([actual rangeOfString:@"9999"].location).notTo.equal(NSNotFound);
      expect([actual rangeOfString:@"\"string\""].location).notTo.equal(NSNotFound);
      expect([actual rangeOfString:@"\"mock data\""].location).notTo.equal(NSNotFound);
      expect([actual rangeOfString:@"{\"key\":\"value\"}"].location).notTo.equal(NSNotFound);
      expect([actual rangeOfString:@"LPJsonifiable: JSONRepresentation"].location).notTo.equal(NSNotFound);
      expect([actual rangeOfString:@"[1,2,3]"].location).notTo.equal(NSNotFound);
      expect([actual rangeOfString:@"null"].location).notTo.equal(NSNotFound);

      expect(error).to.equal(nil);
    });

    it(@"can serialize an array of invalid JSON objects", ^{
      // Skipping NSManagedObject.
      NSArray *array = @[[NSObject new],
                         [[UIView alloc] initWithFrame:CGRectZero],
                         [LPHasNilDescription new]];
      data = [serializer serializeArray:array error:&error];
      NSString *actual = [[NSString alloc] initWithBytes:[data bytes]
                                                  length:[data length]
                                                encoding:NSUTF8StringEncoding];

      expect([actual rangeOfString:@"\"<NSObject"].location).notTo.equal(NSNotFound);
      expect([actual rangeOfString:@"\"<UIView"].location).notTo.equal(NSNotFound);
      expect([actual rangeOfString:@"null"].location).notTo.equal(NSNotFound);
      expect(error).to.equal(nil);
    });
  });

  describe(@"#serializeDictionary:error:", ^{
    it(@"can serialize a dictionary of valid JSON objects", ^{
      NSDictionary *dictionary =  @{@"number" : @(9999),
                                    @"string" : @"string",
                                    @"date" : [NSDate date],
                                    @"data" : mockData,
                                    @"dictionary" : @{@"key" : @"value"},
                                    @"LPJSONRepresentation protocol" : [LPJsonifiable new],
                                    @"array" : @[@(1), @(2), @(3)],
                                    @"NSNull" : [NSNull null]
                                    };
      data = [serializer serializeDictionary:dictionary error:&error];
      NSString *actual = [[NSString alloc] initWithBytes:[data bytes]
                                                  length:[data length]
                                                encoding:NSUTF8StringEncoding];

      // Skip the date checking; too difficult.
      expect([actual rangeOfString:@"\"number\":9999"].location).notTo.equal(NSNotFound);
      expect([actual rangeOfString:@"\"string\":\"string\""].location).notTo.equal(NSNotFound);
      expect([actual rangeOfString:@"\"mock data\""].location).notTo.equal(NSNotFound);
      expect([actual rangeOfString:@"\"NSNull\":null"].location).notTo.equal(NSNotFound);
      expect([actual rangeOfString:@"\"LPJSONRepresentation protocol\":LPJsonifiable"].location).notTo.equal(NSNotFound);
      expect([actual rangeOfString:@"\"array\":[1,2,3]"].location).notTo.equal(NSNotFound);

      expect(error).to.equal(nil);
    });

    it(@"can serialize a dictionary of invalid JSON objects", ^{
      // Skipping NSManagedObject.
      NSDictionary *dictionary = @{@"object" : [NSObject new],
                                   @"view" : [[UIView alloc] initWithFrame:CGRectZero],
                                   @"has nil description" : [LPHasNilDescription new]
                                   };
      data = [serializer serializeDictionary:dictionary error:&error];
      NSString *actual = [[NSString alloc] initWithBytes:[data bytes]
                                                  length:[data length]
                                                encoding:NSUTF8StringEncoding];

      expect([actual rangeOfString:@"\"has nil description\":null"].location).notTo.equal(NSNotFound);
      expect([actual rangeOfString:@"\"object\":\"<NSObject"].location).notTo.equal(NSNotFound);
      expect([actual rangeOfString:@"\"view\":\"<UIView"].location).notTo.equal(NSNotFound);
      expect(error).to.equal(nil);
    });
  });

  describe(@"#stringByDecodingNSData:", ^{
    it(@"can handle nil data argument", ^{
      NSString *actual = [serializer stringByDecodingNSData:nil];
      expect(actual).to.equal(@"null");
    });

    it(@"can handle NULL data argument", ^{
      NSString *actual = [serializer stringByDecodingNSData:NULL];
      expect(actual).to.equal(@"null");
    });

    it(@"can handle arbitrary data", ^{
      NSString *actual = [serializer stringByDecodingNSData:mockData];
      expect(actual).to.equal(@"mock data");
    });
  });

  describe(@"#stringByEnsuringSerializationOfDictionary:", ^{
    it(@"can handling being passed a non-dictionary instance", ^{
      id array = @[@(1), @(2), @(3)];
      NSString *actual = [serializer stringByEnsuringSerializationOfDictionary:array];
      expect(actual).notTo.equal(nil);
      expect(actual.length).notTo.equal(0);
    });

    it(@"can handle nil argument", ^{
      NSString *actual = [serializer stringByEnsuringSerializationOfDictionary:nil];
      expect(actual).notTo.equal(nil);
      expect(actual.length).notTo.equal(0);
    });

    it(@"can handle NULL argument", ^{
      NSString *actual = [serializer stringByEnsuringSerializationOfDictionary:NULL];
      expect(actual).notTo.equal(nil);
      expect(actual.length).notTo.equal(0);
    });

    it(@"serializes the dictionary", ^{
      [[[mock expect] andReturn:mockData] serializeDictionary:OCMOCK_ANY
                                                        error:[OCMArg setTo:error]];

      NSString *actual = [mock stringByEnsuringSerializationOfDictionary:@{}];
      [mock verify];
      expect(actual).to.equal(@"mock data");
    });
  });

  describe(@"#stringByEnsuringSerializationOfArray:", ^{
    it(@"can handling being passed a non-array instance", ^{
      id dictionary = @{@"array" : @[@(1), @(2), @(3)]};
      NSString *actual = [serializer stringByEnsuringSerializationOfArray:dictionary];
      expect(actual).notTo.equal(nil);
      expect(actual.length).notTo.equal(0);
    });

    it(@"can handle nil argument", ^{
      NSString *actual = [serializer stringByEnsuringSerializationOfArray:nil];
      expect(actual).notTo.equal(nil);
      expect(actual.length).notTo.equal(0);
    });

    it(@"can handle NULL argument", ^{
      NSString *actual = [serializer stringByEnsuringSerializationOfArray:NULL];
      expect(actual).notTo.equal(nil);
      expect(actual.length).notTo.equal(0);
    });

    it(@"serializes the array", ^{
      [[[mock expect] andReturn:mockData] serializeArray:OCMOCK_ANY
                                                   error:[OCMArg setTo:error]];

      NSString *actual = [mock stringByEnsuringSerializationOfArray:@[]];
      [mock verify];
      expect(actual).to.equal(@"mock data");
    });
  });

  describe(@"#stringByEnsuringSerializationOfObject:", ^{
    it(@"can handle nil argument", ^{
      NSString *actual = [serializer stringByEnsuringSerializationOfObject:nil];
      expect(actual).notTo.equal(nil);
      expect(actual.length).notTo.equal(0);
    });

    it(@"can handle NULL argument", ^{
      NSString *actual = [serializer stringByEnsuringSerializationOfObject:NULL];
      expect(actual).notTo.equal(nil);
      expect(actual.length).notTo.equal(0);
    });

    it(@"valid JSON object", ^{
      id object = [NSObject new];
      BOOL yes = YES;
      [[[mock expect] andReturnValue:OCMOCK_VALUE(yes)] isValidJSONObject:object];
      [[[mock expect] andReturn:mockData] serializeObject:OCMOCK_ANY
                                                    error:[OCMArg setTo:error]];

      NSString *actual = [mock stringByEnsuringSerializationOfObject:object];
      [mock verify];
      expect(actual).to.equal(@"mock data");
    });

    it(@"invalid JSON object", ^{
      id object = [NSObject new];
      BOOL no = NO;
      [[[mock expect] andReturnValue:OCMOCK_VALUE(no)] isValidJSONObject:object];
      [[[mock expect] andReturn:mockData] serializeInvalidJSONObject:OCMOCK_ANY
                                                               error:[OCMArg setTo:error]];

      NSString *actual = [mock stringByEnsuringSerializationOfObject:object];
      [mock verify];
      expect(actual).to.equal(@"mock data");
    });

    describe(@"unable to serialze", ^{
      it(@"there was no error", ^{
        id object = [NSObject new];
        [[[mock expect] andReturn:nil] serializeInvalidJSONObject:OCMOCK_ANY
                                                            error:[OCMArg setTo:nil]];

        NSString *actual = [mock stringByEnsuringSerializationOfObject:object];
        [mock verify];
        expect([actual rangeOfString:@"Invalid JSON for 'NSObject' instance."].location).notTo.equal(NSNotFound);
      });

      it (@"there was an error", ^{
        id object = [NSObject new];

        error = [NSError errorWithDomain:@"Domain" code:1 userInfo:@{}];

        [[[mock expect] andReturn:nil] serializeInvalidJSONObject:OCMOCK_ANY
                                                            error:[OCMArg setTo:error]];

        NSString *actual = [mock stringByEnsuringSerializationOfObject:object];
        [mock verify];
        expect([actual rangeOfString:@"Invalid JSON for 'NSObject' instance."].location).notTo.equal(NSNotFound);
      });
    });
  });
});

SpecEnd
