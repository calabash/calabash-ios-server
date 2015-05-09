#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPCJSONSerializer.h"
#import "LPJSONRepresentation.h"

@interface LPJsonifiable : NSObject <LPJSONRepresentation>

@end

@implementation LPJsonifiable

- (NSData *) JSONDataRepresentation {
  return [[NSString stringWithFormat:@"data"]
          dataUsingEncoding:NSUTF8StringEncoding];
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

      it(@"NSDictionary", ^{
        [[[mock expect] andReturn:mockData] serializeDictionary:OCMOCK_ANY
                                                          error:[OCMArg setTo:nil]];

        data = [mock serializeObject:@{} error:&error];
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

      });

      it(@"NULL", ^{

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
});

SpecEnd
