#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPPluginLoader.h"
#import "LPDevice.h"

@interface LPPluginLoader (LPXCTEST)

- (NSPredicate *) filterPredicate;
- (NSArray *) arrayOfCabalshDylibPaths;
- (BOOL) loadDylibAtPath:(NSString *) path;

@end

@interface LPPluginLoaderTest : XCTestCase

@end

@implementation LPPluginLoaderTest

@end

SpecBegin(LPPluginLoader)

describe(@"LPPluginLoader", ^{

  __block NSArray *examples;
  __block NSArray *calabshDylibs;

  before(^{
    examples = @[
                 @"/some/path/to/file",
                 @"/some/path/to/file.dylib",
                 @"/some/path/to/fileCalabash.dylib",
                 @"/some/path/to/otherCalabash.dylib"
                 ];
    calabshDylibs = [examples subarrayWithRange:NSMakeRange(2, 2)];
  });

  describe(@"#filterPredicate", ^{
    __block NSPredicate *predicate;

    before(^{
      predicate = [[LPPluginLoader new] filterPredicate];
    });

    it(@"returns a predicate", ^{
      expect(predicate).to.beAKindOf([NSPredicate class]);
    });

    it(@"predicate can filter an array", ^{
      NSArray *actual = [examples filteredArrayUsingPredicate:predicate];
      expect(actual).to.haveACountOf([calabshDylibs count]);
      expect(actual).to.beSupersetOf(calabshDylibs);
    });
  });

  it(@"#arrayOfCalabashDylibPaths", ^{
    id bundleMock = OCMPartialMock([NSBundle mainBundle]);
    [[[bundleMock stub] andReturn:examples] pathsForResourcesOfType:@"dylib"
                                                        inDirectory:nil];
    LPPluginLoader *loader = [LPPluginLoader new];
    NSArray *dylibs = [loader arrayOfCabalshDylibPaths];
    expect(dylibs).to.haveACountOf([calabshDylibs count]);
    expect(dylibs).to.beSupersetOf(calabshDylibs);
    [bundleMock stopMocking];
  });

  describe(@"#loadDylibAtPath:", ^{
    __block LPPluginLoader *loader;

    before(^{
      loader = [LPPluginLoader new];
    });

    it(@"returns false when dylib cannot be loaded", ^{
      NSBundle *main = [NSBundle mainBundle];
      NSString *path = [main pathForResource:@"badPlugin" ofType:@"dylib"];
      expect(path).notTo.equal(nil);
      expect([loader loadDylibAtPath:path]).to.equal(NO);
    });

    it(@"returns true when dylib is loaded", ^{
      if ([[LPDevice sharedDevice] simulator]) {
        NSBundle *main = [NSBundle mainBundle];
        NSString *path = [main pathForResource:@"examplePlugin" ofType:@"dylib"];
        expect(path).notTo.equal(nil);
        expect([loader loadDylibAtPath:path]).to.equal(YES);
      } else {
        // nop for devices because the dylibs are not signed.
      }
    });
  });

  describe(@"#loadCalabashPlugins", ^{
    it(@"returns true if all plug-ins were loaded", ^{
      if ([[LPDevice sharedDevice] simulator]) {
        LPPluginLoader *loader = [LPPluginLoader new];
        expect([loader loadCalabashPlugins]).to.equal(YES);
      } else {
        // nop for devices because the dylibs are not signed.
      }
    });

    it(@"returns false if a plug fails to load", ^{
      LPPluginLoader *loader = [LPPluginLoader new];
      id mock = OCMPartialMock(loader);
      BOOL no = NO;
      [[[mock stub] andReturnValue:OCMOCK_VALUE(no)] loadDylibAtPath:OCMOCK_ANY];
      expect([loader loadCalabashPlugins]).to.equal(NO);
    });
  });

});

SpecEnd