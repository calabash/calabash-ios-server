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


- (NSDictionary *) JSONResponseForMethod:(NSString *) method
                                     URI:(NSString *) path
                                    data:(NSDictionary *) data {
  
  mach_timebase_info_data_t timebaseInfo;
  mach_timebase_info(&timebaseInfo);
  
  uint64_t machTimeBefore = mach_absolute_time();

  __block uint64_t machTimeAfter;
  
  dispatch_sync(dispatch_get_main_queue(), ^{
    machTimeAfter = mach_absolute_time();
  });
  

  // Convert the mach time to milliseconds
  uint64_t durationMachTime = machTimeAfter -  machTimeBefore;
  uint64_t result = (durationMachTime/1000000 * timebaseInfo.numer) / timebaseInfo.denom;
  return [NSDictionary dictionaryWithObjectsAndKeys:
           [NSNumber numberWithUnsignedLongLong:result], @"result",
           @"SUCCESS", @"outcome",
        nil];
  
  
}

@end
