//
//  LPConditionRoute.m
//  calabash
//
//  Created by Karl Krukow on 29/01/12.
//  Copyright (c) 2012 LessPainful. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPConditionRoute.h"
#import "LPOperation.h"
#import "LPRepeatingTimerProtocol.h"
#import "LPCocoaLumberjack.h"

#define kLPConditionRouteNoNetworkIndicator @"NO_NETWORK_INDICATOR"
#define kLPConditionRouteNoneAnimating @"NONE_ANIMATING"
#define kLPConditionRouteAnimationDurationLimit 0.01

@interface LPConditionRoute () <LPRepeatingTimerProtocol>

@property(atomic, assign) NSUInteger maxCount;
@property(atomic, assign) NSUInteger curCount;
@property(atomic, assign) NSUInteger stablePeriod;
@property(atomic, assign) NSUInteger stablePeriodCount;
@property(atomic, assign) NSTimeInterval timerRepeatInterval;
@property(atomic, strong) dispatch_source_t repeatingTimer;
@property(atomic, copy, readonly) NSString *condition;
@property(atomic, strong, readonly) id query;

- (NSArray *) performQueryOnMainThread;
- (BOOL) checkNetworkIndicatorOnMainThread;

@end

@implementation LPConditionRoute

#pragma mark - Memory Management

@synthesize repeatingTimer = _repeatingTimer;
@synthesize condition = _condition;
@synthesize query = _query;


- (void) dealloc {
  [self stopAndReleaseRepeatingTimers];
}

- (void) startAndRetainRepeatingTimers {
  [self stopAndReleaseRepeatingTimers];

  NSTimeInterval interval = self.timerRepeatInterval;

  dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  _repeatingTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);

  dispatch_time_t startTime = dispatch_time(DISPATCH_TIME_NOW, 0);
  uint64_t intervalNano = (uint64_t)(interval * NSEC_PER_SEC);

  dispatch_source_set_timer(_repeatingTimer, startTime, intervalNano, 0);

  dispatch_source_set_event_handler(_repeatingTimer, ^{
    [self checkConditionWithTimer:nil];
  });

  dispatch_resume(_repeatingTimer);
}

- (void) stopAndReleaseRepeatingTimers {
  if (_repeatingTimer) {
    dispatch_source_cancel(_repeatingTimer);
    _repeatingTimer = nil;
  }
}

- (NSString *) condition {
  if (_condition) { return _condition; }
  _condition = [self.data objectForKey:@"condition"];
  return _condition;
}

- (id) query {
  if (_query) { return _query; }
  _query = [self.data objectForKey:@"query"];
  return _query;
}

#pragma mark - Condition Handling

- (BOOL) isDone {
  return !_repeatingTimer && [super isDone];
}

- (void) beginOperation {
  self.done = NO;
  NSString *condition = self.condition;
  if (!condition) {
    LPLogError(@"Condition not specified");
    [self failWithMessageFormat:@"Condition parameter missing" message:nil];
    return;
  }

  if (!([condition isEqualToString:kLPConditionRouteNoNetworkIndicator] ||
        [condition isEqualToString:kLPConditionRouteNoneAnimating])) {
    LPLogError(@"Expected condition: '%@' or '%@'",
               kLPConditionRouteNoneAnimating, kLPConditionRouteNoNetworkIndicator);
    LPLogError(@"Found condition: '%@'", condition);
    [self failWithMessageFormat:@"Unknown condition '%@'" message:condition];
    return;
  }

  if ([condition isEqualToString:kLPConditionRouteNoneAnimating]) {
    id query = self.query;
    if (!query || [query isEqualToString:@""]) {
      LPLogError(@"Condition received '%@' without a query argument",
                 kLPConditionRouteNoneAnimating);
      [self failWithMessageFormat:@"No query specified." message:nil];
      return;
    }
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

  self.timerRepeatInterval = (NSTimeInterval)freq_d;

  [self startAndRetainRepeatingTimers];
}

- (NSArray *) performQueryOnMainThread {
  id query = self.query;
  if ([[NSThread currentThread] isMainThread]) {
    return [LPOperation performQuery:query];
  } else {
    __block NSArray *result = @[];
    dispatch_sync(dispatch_get_main_queue(), ^{
      result = [LPOperation performQuery:query];
    });
    return result;
  }
}

- (BOOL) checkNetworkIndicatorOnMainThread {
  if ([[NSThread currentThread] isMainThread]) {
    return [[UIApplication sharedApplication] isNetworkActivityIndicatorVisible];
  } else {
    __block BOOL result = NO;
    dispatch_sync(dispatch_get_main_queue(), ^{
      result = [[UIApplication sharedApplication] isNetworkActivityIndicatorVisible];
    });
    return result;
  }
}

#pragma mark - Timer Selector

- (void) checkConditionWithTimer:(NSTimer *) aTimer {
  if (!_repeatingTimer) {
    LPLogWarn(@"Check condition received a nil timer - returning");
    return;
  }

  NSString *condition = [self.data objectForKey:@"condition"];

  if (self.curCount == self.maxCount) {
    [self failWithMessageFormat:@"Timed out waiting for condition %@" message:condition];
    return;
  }

  self.curCount += 1;
  if ([condition isEqualToString:kLPConditionRouteNoneAnimating]) {
    NSArray *result = [self performQueryOnMainThread];
    for (id v in result) {
      if ([v isKindOfClass:[UIView class]]) {
        UIView *view = (UIView *) v;
        NSArray *animationKeys = [[view.layer animationKeys] copy];
        for (NSString *key in animationKeys) {
          CAAnimation *animation = [view.layer animationForKey:key];
          // Only consider animations with a duration greater than the defined
          // limit. This is intended to work around the parallax animation
          // attached to iOS 8 UIAlertViews and UIActionSheets
          if (animation.duration > kLPConditionRouteAnimationDurationLimit) {
            self.stablePeriodCount = 0;
            return;
          }
        }
      }
    }

    self.stablePeriodCount += 1;
    if (self.stablePeriodCount == self.stablePeriod) {
      [self succeedWithResult:[NSArray array]];
      return;
    }
  } else if ([condition isEqualToString:kLPConditionRouteNoNetworkIndicator]) {
    if ([self checkNetworkIndicatorOnMainThread]) {
      self.stablePeriodCount = 0;
      return;
    }
    self.stablePeriodCount += 1;
    if (self.stablePeriodCount == self.stablePeriod) {
      [self succeedWithResult:[NSArray array]];
    }
    return;
  }
}

- (void) failWithMessageFormat:(NSString *) messageFmt message:(NSString *) message {
  [self stopAndReleaseRepeatingTimers];
  [super failWithMessageFormat:messageFmt message:message];
}

- (void) succeedWithResult:(NSArray *) result {
  [self stopAndReleaseRepeatingTimers];
  [super succeedWithResult:result];
}

- (NSNumber *) defaultTimeoutForCondition:(NSString *)condition {
  if ([kLPConditionRouteNoneAnimating isEqualToString:condition]) {
    return [NSNumber numberWithUnsignedInteger:6];
  } else if ([kLPConditionRouteNoNetworkIndicator isEqualToString:condition]) {
    return [NSNumber numberWithUnsignedInteger:30];
  }
  return [NSNumber numberWithUnsignedInteger:30];
}

@end
