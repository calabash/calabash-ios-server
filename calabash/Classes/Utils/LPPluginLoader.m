#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPPluginLoader.h"
#import <dlfcn.h>

@interface LPPluginLoader ()

@property(strong, nonatomic, readonly) NSPredicate *filterPredicate;

- (NSArray *) arrayOfCabalshDylibPaths;
- (BOOL) loadDylibAtPath:(NSString *) path;

@end

@implementation LPPluginLoader

@synthesize filterPredicate = _filterPredicate;

- (NSPredicate *) filterPredicate {
  if (_filterPredicate) { return _filterPredicate; }
  _filterPredicate = [NSPredicate predicateWithFormat:@"SELF ENDSWITH %@",
                      @"Calabash.dylib"];
  return _filterPredicate;
}

- (NSArray *) arrayOfCabalshDylibPaths {
  NSBundle *main = [NSBundle mainBundle];
  NSArray *dylibs = [main pathsForResourcesOfType:@"dylib"
                                      inDirectory:nil];
  return [dylibs filteredArrayUsingPredicate:self.filterPredicate];
}

- (BOOL) loadDylibAtPath:(NSString *) path {
  NSURL *url = [NSURL fileURLWithPath:path];

  char *error;
  const char *cFileSystemRep = [url fileSystemRepresentation];
  NSLog(@"Loading Calabash plugin - %@",
        [NSString stringWithUTF8String:cFileSystemRep]);

  dlopen(cFileSystemRep, RTLD_LOCAL);
  error = dlerror();
  if (error) {
    NSLog(@"Warning: Could not load Calabash plugin %@.",
          [path lastPathComponent]);
    NSLog(@"Warning: %@", [NSString stringWithUTF8String:error]);
    return NO;
  } else {
    return YES;
  }
}

@end
