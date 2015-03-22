#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPPluginLoader.h"

@interface LPPluginLoader (LPXCTEST)

- (NSPredicate *) filterPredicate;

@end

@interface LPPluginLoaderTest : XCTestCase

@end

@implementation LPPluginLoaderTest

@end

SpecBegin(LPPluginLoader)

describe(@"LPPluginLoader", ^{

  describe(@"#filterPredicate", ^{
    __block NSPredicate *predicate;

    before(^{
      predicate = [[LPPluginLoader new] filterPredicate];
    });

    it(@"returns a predicate", ^{
      expect(predicate).to.beAKindOf([NSPredicate class]);
    });

    it(@"predicate can filter an array", ^{
      NSArray *examples = @[
                            @"/some/path/to/file",
                            @"/some/path/to/file.dylib",
                            @"/some/path/to/fileCalabash.dylib",
                            @"/some/path/to/otherCalabash.dylib"
                            ];
      NSArray *expected = [examples subarrayWithRange:NSMakeRange(2, 2)];
      NSArray *actual = [examples filteredArrayUsingPredicate:predicate];
      expect(actual).to.haveACountOf(2);
      expect(actual).to.beSupersetOf(expected);
    });
  });

});

SpecEnd