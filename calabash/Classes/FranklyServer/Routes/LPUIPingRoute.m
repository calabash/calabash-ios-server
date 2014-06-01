//
//  LPUIPingRoute.m
//  calabash
//
//  Created by Karl Krukow on 6/1/14.
//  Copyright (c) 2014 Xamarin. All rights reserved.
//

#import "LPUIPingRoute.h"
#include <mach/mach.h>
#include <unistd.h>
#include <mach/mach_time.h>

@implementation LPUIPingRoute

- (BOOL) supportsMethod:(NSString *) method atPath:(NSString *) path {
  return [method isEqualToString:@"GET"] || [method isEqualToString:@"POST"];
}

-(BOOL)inNetworkThread{return YES;}

- (NSDictionary *) JSONResponseForMethod:(NSString *) method
                                     URI:(NSString *) path
                                    data:(NSDictionary *) data {
  
  mach_timebase_info_data_t timebaseInfo;
  mach_timebase_info(&timebaseInfo);
  __block uint64_t machTimeAfter;
  dispatch_semaphore_t synchronizationSemaphore = dispatch_semaphore_create(0);
  
  uint64_t machTimeBefore = mach_absolute_time();
  
  dispatch_async(dispatch_get_main_queue(), ^{
    machTimeAfter = mach_absolute_time();
    dispatch_semaphore_signal(synchronizationSemaphore);
  });
  
  BOOL success = (0 == dispatch_semaphore_wait(synchronizationSemaphore, dispatch_time(DISPATCH_TIME_NOW, 5000000000)));
  dispatch_release(synchronizationSemaphore);

  // Convert the mach time to milliseconds
  uint64_t durationMachTime = machTimeAfter -  machTimeBefore;
  uint64_t result = (durationMachTime/1000000 * timebaseInfo.numer)/timebaseInfo.denom;
  return [NSDictionary dictionaryWithObjectsAndKeys:
           [NSNumber numberWithUnsignedLongLong:result], @"result",
            success ? @"SUCCESS" : @"FAILURE",           @"outcome",
        nil];
  
  
}

@end
