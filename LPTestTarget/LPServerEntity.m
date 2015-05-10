#import "LPServerEntity.h"

@implementation LPServerEntity

@dynamic name;
@dynamic address;
@dynamic lastPing;

// Apple does not recommend overriding description and accessing entity
// properties.  We are trying to catch these exceptions and _not_ crash.
//
// The exception here is test the JSON serialization code.
- (NSString *) description {
  if ([self isFault]) {
    @throw [NSException exceptionWithName:@"MyCoreDataException"
     reason:@"called description when object is a fault"
                                 userInfo:@{}];
  }
  return [super description];
//  return [NSString stringWithFormat:@"<LPServerEntity %@ %@ %@ %@>",
//          self.objectID, self.name, self.address, @(self.lastPing)];
}

@end
