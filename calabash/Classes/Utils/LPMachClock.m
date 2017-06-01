#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import <mach/mach.h>
#import <mach/mach_time.h>
#import "LPMachClock.h"

// http://stackoverflow.com/questions/889380/how-can-i-get-a-precise-time-for-example-in-milliseconds-in-objective-c

@interface LPMachClock()

- (NSTimeInterval)machAbsoluteToTimeInterval:(uint64_t)machAbsolute;
- (instancetype)initPrivate;

@end

@implementation LPMachClock

mach_timebase_info_data_t _clock_timebase;

+ (instancetype)sharedClock {
  static LPMachClock *clock;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    clock = [[LPMachClock alloc] initPrivate];
  });
  return clock;
}

- (instancetype)initPrivate {
  self = [super init];
  if (self) {
    mach_timebase_info(&_clock_timebase);
  }
  return self;
}

- (id)init {
  @throw [NSException exceptionWithName:@"SingletonException"
                                 reason:@"This is a singleton class. init is not available."
                               userInfo:nil];
}

- (NSTimeInterval)machAbsoluteToTimeInterval:(uint64_t)machAbsolute {
  uint64_t nanos = (machAbsolute * _clock_timebase.numer) / _clock_timebase.denom;
  return nanos/1.0e9;
}

- (NSTimeInterval)absoluteTime {
  uint64_t machTime = mach_absolute_time();
  return [self machAbsoluteToTimeInterval:machTime];
}

@end
