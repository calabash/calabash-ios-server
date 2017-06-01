#include <Foundation/Foundation.h>

/**
 An object wrapper around mach_absolute_time()

 This is a singleton class.  Calling `init` will raise an exception.
 */
@interface LPMachClock : NSObject

/**
 The shared clock.

 This is a singleton class.  Calling init will throw an exception.
 @return the MachClock
 */
+ (instancetype)sharedClock;

/**
 What is the time right now?

 @return the mach absolute time as an NSTimeInterval
 */
- (NSTimeInterval)absoluteTime;

@end
