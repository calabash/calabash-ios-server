//
//  LPConditionRoute.m
//  calabash
//
//  Created by Karl Krukow on 29/01/12.
//  Copyright (c) 2012 LessPainful. All rights reserved.
//

#import "LPConditionRoute.h"
#import "LPOperation.h"


@implementation LPConditionRoute
@synthesize timer = _timer;
@synthesize maxCount;
@synthesize curCount;


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
  NSNumber *count = [self.data objectForKey:@"count"];
  if (!count) {
    count = [NSNumber numberWithInt:1];
  }
  if ([count integerValue] <= 0) {
    [self failWithMessageFormat:@"Count should be positive..." message:nil];
    return;
  }
  self.maxCount = [count integerValue];
  self.curCount = 0;
  NSNumber *freq = [self.data objectForKey:@"frequency"];
  if (!freq) {
    freq = [NSNumber numberWithDouble:0.2];
  }


  self.timer = [NSTimer scheduledTimerWithTimeInterval:[freq doubleValue] target:self selector:@selector(checkConditionWithTimer:) userInfo:nil repeats:YES];
  [self checkConditionWithTimer:self.timer];
}


- (void) checkConditionWithTimer:(NSTimer *) aTimer {
  self.curCount += 1;
  NSString *condition = [self.data objectForKey:@"condition"];
  if ([condition isEqualToString:@"NONE_ANIMATING"]) {

    id query = [self.data objectForKey:@"query"];
    if (query) {
      NSArray *result = [LPOperation performQuery:query];
      for (id v in result) {
        if ([v isKindOfClass:[UIView class]]) {
          UIView *view = (UIView *) v;
          if ([[view.layer animationKeys] count] > 0) {
            [self failWithMessageFormat:@"Found animating view: %@" message:v];
            return;
          }
        }
      }
      if (self.curCount == self.maxCount) {
        [self succeedWithResult:[NSArray array]];
      }
    } else {
      [self failWithMessageFormat:@"No query specified." message:nil];
      return;
    }

    return;
  } else if ([condition isEqualToString:@"NO_NETWORK_INDICATOR"]) {
    if ([[UIApplication sharedApplication] isNetworkActivityIndicatorVisible]) {
      [self failWithMessageFormat:@"Network activity indicator visible" message:nil];
      return;
    }
    if (self.curCount == self.maxCount) {
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


- (void) dealloc {
  self.timer = nil;
  [super dealloc];
}

@end

