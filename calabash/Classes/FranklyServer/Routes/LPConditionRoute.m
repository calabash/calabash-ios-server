//
//  LPConditionRoute.m
//  calabash
//
//  Created by Karl Krukow on 29/01/12.
//  Copyright (c) 2012 LessPainful. All rights reserved.
//

#import "LPConditionRoute.h"
#import "LPOperation.h"

#define kLPConditionRouteNoNetworkIndicator @"NO_NETWORK_INDICATOR"
#define kLPConditionRouteNoneAnimating @"NONE_ANIMATING"


@implementation LPConditionRoute
@synthesize timer = _timer;
@synthesize maxCount;
@synthesize curCount;
@synthesize stablePeriod;
@synthesize stablePeriodCount;


// Should only return YES after the LPHTTPConnection has read all available data.
- (BOOL) isDone {
  return !self.timer && [super isDone];
}


- (void) beginOperation {
  self.done = NO;
  NSString *condition = [self.data objectForKey:@"condition"];
  if (!condition) {
    NSLog(@"condition not specified");
    [self failWithMessageFormat:@"condition parameter missing" message:nil];
    return;
  }
  self.curCount = 0;


  NSNumber *timeoutInSecs = [self.data objectForKey:@"timeout"];
  if (!timeoutInSecs) {
    timeoutInSecs = [self defaultTimeoutForCondition: condition];
  }
  NSUInteger timeoutInSecsUI = [timeoutInSecs unsignedIntegerValue];

  NSNumber *freq = [self.data objectForKey:@"frequency"];
  if (!freq) {
    freq = [NSNumber numberWithDouble:0.2];
  }

  double freq_d = [freq doubleValue];
  if (freq_d <= 0.1) {
    freq_d = 0.1;
  }

  self.maxCount = ceil(timeoutInSecsUI / freq_d);

  NSNumber *stable = [self.data objectForKey:@"duration"];
  if (!stable) {
    stable = [NSNumber numberWithDouble:0.5];
  }
  double stablePeriod_d = [stable doubleValue];

  self.stablePeriod = ceil(stablePeriod_d / freq_d);
  self.stablePeriodCount = 0;

  self.timer = [NSTimer scheduledTimerWithTimeInterval:freq_d
                                                target:self
                                              selector:@selector(checkConditionWithTimer:)
                                              userInfo:nil repeats:YES];
  [self checkConditionWithTimer:self.timer];
}


- (void) checkConditionWithTimer:(NSTimer *) aTimer {
  if (!self.timer) {return;}
  NSString *condition = [self.data objectForKey:@"condition"];

  if (self.curCount == self.maxCount) {
    [self failWithMessageFormat:@"Timed out waiting for condition %@" message:condition];
  }

  self.curCount += 1;
  if ([condition isEqualToString:kLPConditionRouteNoneAnimating]) {

    id query = [self.data objectForKey:@"query"];
    if (query) {
      NSArray *result = [LPOperation performQuery:query];
      for (id v in result) {
        if ([v isKindOfClass:[UIView class]]) {
          UIView *view = (UIView *) v;
          if ([[view.layer animationKeys] count] > 0) {
            self.stablePeriodCount = 0;
            return;
          }
        }
      }
      self.stablePeriodCount += 1;
      if (self.stablePeriodCount == self.stablePeriod) {
        [self succeedWithResult:[NSArray array]];
        return;
      }
    } else {
      [self failWithMessageFormat:@"No query specified." message:nil];
      return;
    }

    return;
  } else if ([condition isEqualToString:kLPConditionRouteNoNetworkIndicator]) {
    if ([[UIApplication sharedApplication] isNetworkActivityIndicatorVisible]) {
      self.stablePeriodCount = 0;
      return;
    }
    self.stablePeriodCount += 1;
    if (self.stablePeriodCount == self.stablePeriod) {
      [self succeedWithResult:[NSArray array]];
    }
    return;
  }
  [self failWithMessageFormat:@"Unknown condition %@" message:condition];
}


- (void) failWithMessageFormat:(NSString *) messageFmt message:(NSString *) message {
  [self.timer invalidate];
  self.timer = nil;
  [super failWithMessageFormat:messageFmt message:message];
}


- (void) succeedWithResult:(NSArray *) result {
  [self.timer invalidate];
  self.timer = nil;
  [super succeedWithResult:result];
}

-(NSNumber*)defaultTimeoutForCondition:(NSString*)condition {
  if ([kLPConditionRouteNoneAnimating isEqualToString:condition]) {
    return [NSNumber numberWithUnsignedInteger:6];
  }
  else if ([kLPConditionRouteNoNetworkIndicator isEqualToString:condition]) {
    return [NSNumber numberWithUnsignedInteger:30];
  }
  return [NSNumber numberWithUnsignedInteger:30];
}


- (void) dealloc {
  [self.timer invalidate];  
  self.timer = nil;
  [super dealloc];
}

@end

