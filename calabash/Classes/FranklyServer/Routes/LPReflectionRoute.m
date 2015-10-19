#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPReflectionRoute.h"
#import <objc/runtime.h>

@interface LPReflectionRoute ()

- (NSArray *) libraryNames;
- (NSArray *) classNames;

@end

@implementation LPReflectionRoute

- (BOOL) supportsMethod:(NSString *) method atPath:(NSString *) path {
  return [method isEqualToString:@"GET"];
}

- (NSDictionary *) JSONResponseForMethod:(NSString *) method
                                     URI:(NSString *) path
                                    data:(NSDictionary *) data {

  return nil;
}

- (NSArray *) libraryNames {
  unsigned int number = 0;

  const char **names = objc_copyImageNames(&number);

  NSMutableArray *array = [NSMutableArray arrayWithCapacity:number];
  for (unsigned int index = 0; index < number; index++) {
    const char *cName = names[index];
    NSString *name = [[NSString alloc] initWithUTF8String:cName];
    [array addObject:name];
  }

  SEL sorter = @selector(localizedCaseInsensitiveCompare:);
  NSArray *sorted = [array sortedArrayUsingSelector:sorter];
  free(names);
  return sorted;
}

- (NSArray *) classNames {
  unsigned int number = 0;

  Class *classes = objc_copyClassList(&number);

  NSMutableArray *array = [NSMutableArray arrayWithCapacity:number];
  for (unsigned int index = 0; index < number; index++) {
    Class class = classes[index];
    NSString *name = NSStringFromClass(class);
    [array addObject:name];
  }

  SEL sorter = @selector(localizedCaseInsensitiveCompare:);
  NSArray *sorted = [array sortedArrayUsingSelector:sorter];
  free(classes);
  return sorted;
}

@end
