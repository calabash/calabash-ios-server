//  Created by Karl Krukow on 15/04/14.
//  Copyright (c) 2014 Xamarin. All rights reserved.


#import "LPUIATapRoute.h"
#import "LPUIAChannel.h"
#import "LPTouchUtils.h"
#import "LPOperation.h"
#import "LPHTTPConnection.h"

#define kLPUIATapRouteModalWaitIterationCount 5

@implementation LPUIATapRoute
@synthesize timer = _timer;
@synthesize maxCount;
@synthesize curCount;



- (void) dealloc {
  [self.timer invalidate];
  self.timer = nil;
  [super dealloc];
}


- (BOOL) supportsMethod:(NSString *) method atPath:(NSString *) path {
  return [method isEqualToString:@"POST"];
}

// Should only return YES after the LPHTTPConnection has read all available data.
- (BOOL) isDone {
  return !self.timer && [super isDone];
}


- (void) beginOperation {
  self.done = NO;
  self.curCount = 0;
  
  NSNumber *timeoutInSecs = [self.data objectForKey:@"timeout"];
  if (!timeoutInSecs) {
    timeoutInSecs = [NSNumber numberWithUnsignedInteger:30];
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

  self.timer = [NSTimer scheduledTimerWithTimeInterval:freq_d
                                                target:self
                                              selector:@selector(checkConditionWithTimer:)
                                              userInfo:nil repeats:YES];
  [self checkConditionWithTimer:self.timer];
}


- (void) checkConditionWithTimer:(NSTimer *) aTimer {
  if (self.timer == nil) {return;}
  if (self.curCount == self.maxCount) {
    [self failWithMessageFormat:@"Timed out waiting for view to not animate." message:nil];
  }
  self.curCount += 1;

  id query = [self.data objectForKey:@"query"];
  if (query) {
    NSArray *result = [LPOperation performQuery:query];
    if ([result count] > 0) {
      id v = [result objectAtIndex:0];//autopick first?
      if ([v isKindOfClass:[UIView class]]) {
        UIView *view = (UIView *) v;
        UIView *viewWindow = [LPTouchUtils windowForView:view];
        if (viewWindow == [LPTouchUtils appDelegateWindow]) {
          if ([self isViewOrSuperViewAnimating: view]) {
            return; //wait
          }
        }
        else {
          if (self.curCount < kLPUIATapRouteModalWaitIterationCount) {
            return; //wait
          }
        }
      }
      [self.timer invalidate];
      self.timer = nil;
      [self performTapOnView: v];
      
    }
  } else {
     [self failWithMessageFormat:@"No query specified." message:nil];
  }
  
}

-(BOOL)isViewOrSuperViewAnimating:(UIView*)view {
  UIView *current = view;
  while (current) {
    if ([[current.layer animationKeys] count] > 0) {
      return YES;
    }
    current = [current superview];
  }
  return NO;
}

-(void)performTapOnView:(id)v {
  NSDictionary *offset = [self.data valueForKey:@"offset"];
  NSNumber *x = [offset valueForKey:@"x"];
  NSNumber *y = [offset valueForKey:@"y"];
  
  CGPoint offsetPoint = CGPointMake([x floatValue], [y floatValue]);
  
  CGPoint center;
  if ([v isKindOfClass:[UIView class]]) {
    center = [LPTouchUtils centerOfView:v];
  } else {
    CGPointMakeWithDictionaryRepresentation((CFDictionaryRef) [v valueForKey:@"center"], &center);
  }
  
  center = CGPointMake(center.x + offsetPoint.x, center.y + offsetPoint.y);
  NSString *command = [self tapCommandForPoint:center];
  [LPUIAChannel runAutomationCommand:command then:^(NSDictionary *result) {
    if (!result) {
      [self failWithMessageFormat:@"Timed out running command %@"
                          message:command];
    } else {
      [self succeedWithResult:[NSArray arrayWithObject:[[result copy]
                                                        autorelease]]];
    }
  }];
  
}


-(NSString*)tapCommandForPoint:(CGPoint)point {
  return [NSString stringWithFormat:@"uia.tapOffset('{:x %f, :y %f}')", point.x, point.y];
  
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


@end
