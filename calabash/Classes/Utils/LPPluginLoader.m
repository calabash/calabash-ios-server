#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPPluginLoader.h"


@interface LPPluginLoader ()

@property(strong, nonatomic, readonly) NSPredicate *filterPredicate;

@end

@implementation LPPluginLoader

@synthesize filterPredicate = _filterPredicate;

- (NSPredicate *) filterPredicate {
  if (_filterPredicate) { return _filterPredicate; }
  _filterPredicate = [NSPredicate predicateWithFormat:@"SELF ENDSWITH %@",
                      @"Calabash.dylib"];
  return _filterPredicate;
}

@end
