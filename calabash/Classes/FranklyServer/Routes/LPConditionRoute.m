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

#define kLPConditionRouteNoNetworkIndicator @"NO_NETWORK_INDICATOR"
#define kLPConditionRouteNoneAnimating @"NONE_ANIMATING"
#define kLPConditionRouteAnimationDurationLimit 0.01

@interface LPConditionRoute () <LPRepeatingTimerProtocol>

@property(nonatomic, strong) NSTimer *timer;
@property(nonatomic, assign) NSUInteger maxCount;
@property(nonatomic, assign) NSUInteger curCount;
@property(nonatomic, assign) NSUInteger stablePeriod;
@property(nonatomic, assign) NSUInteger stablePeriodCount;
@property(nonatomic, assign) NSTimeInterval timerRepeatInterval;

@end

@implementation LPConditionRoute

@synthesize timer = _timer;

#pragma mark - Memory Management

- (void) dealloc {
  [self stopAndReleaseRepeatingTimers];
}

- (void) startAndRetainRepeatingTimers {
  [self stopAndReleaseRepeatingTimers];
  _timer = [NSTimer scheduledTimerWithTimeInterval:self.timerRepeatInterval
                                            target:self
                                          selector:@selector(checkConditionWithTimer:)
                                          userInfo:nil
                                           repeats:YES];
}

- (void) stopAndReleaseRepeatingTimers {
  if (_timer != nil) {
    [_timer invalidate];
    _timer = nil;
  }
}

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

  self.timerRepeatInterval = (NSTimeInterval)freq_d;

  [self startAndRetainRepeatingTimers];
}


- (void) checkConditionWithTimer:(NSTimer *) aTimer {
  if (!self.timer) {return;}
  NSString *condition = [self.data objectForKey:@"condition"];

  if (self.curCount == self.maxCount) {
    [self failWithMessageFormat:@"Timed out waiting for condition %@" message:condition];
    return;
  }

  self.curCount += 1;
  if ([condition isEqualToString:kLPConditionRouteNoneAnimating]) {

    id query = [self.data objectForKey:@"query"];
    if (query) {
      NSArray *result = [LPOperation performQuery:query];
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
  if (!self.timer) { //to prevent accidental double writing of http chunks
    return;
  }
  [self stopAndReleaseRepeatingTimers];
  [super failWithMessageFormat:messageFmt message:message];
}


- (void) succeedWithResult:(NSArray *) result {
  if (!self.timer) { //to prevent accidental double writing of http chunks
    return;
  }
  [self stopAndReleaseRepeatingTimers];
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

@end
