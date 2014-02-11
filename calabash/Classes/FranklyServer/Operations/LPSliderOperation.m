//
//  ScrollOperation.m
//  Calabash
//
//  Created by Karl Krukow on 18/08/11.
//  Copyright (c) 2011 LessPainful. All rights reserved.
//

#import "LPSliderOperation.h"


@implementation LPSliderOperation

- (NSString *) description {
  return [NSString stringWithFormat:@"Slider: %@", _arguments];
}

/*
 args << options[:notify_targets] || true
 args << options[:animate] || true
 */


//    required =========> |     optional
// _arguments ==> [value_st,  notify targets, animate]
- (id) performWithTarget:(UIView *) _view error:(NSError **) error {
  if ([_view isKindOfClass:[UISlider class]] == NO) {
    NSLog(@"Warning view: %@ should be a UISlier", _view);
    return nil;
  }

  UISlider *slider = (UISlider *) _view;

  NSString *valueStr = _arguments[0];
  if (valueStr == nil || [valueStr length] == 0) {
    NSLog(@"Warning: value str: '%@' should be non-nil and non-empty",
            valueStr);
    return nil;
  }

  CGFloat targetValue = [valueStr floatValue];

  NSUInteger argcount = [_arguments count];

  BOOL notifyTargets = YES;
  if (argcount > 1) {
    notifyTargets = [_arguments[1] boolValue];
  }

  BOOL animate = YES;
  if (argcount > 2) {
    animate = [_arguments[2] boolValue];
  }

  if (targetValue > [slider maximumValue]) {
    NSLog(@"Warning: target value '%.2f' is greater than slider max value '%.2f' - will slide to max value",
            targetValue, [slider maximumValue]);
  }

  if (targetValue < [slider minimumValue]) {
    NSLog(@"Warning: target value '%.2f' is less than slider min value '%.2f' - will slide to min value",
            targetValue, [slider minimumValue]);
  }

  [slider setValue:targetValue animated:animate];

  if (notifyTargets) {
    NSSet *targets = [slider allTargets];
    for (id target in targets) {
      NSArray *actions = [slider actionsForTarget:target
                                  forControlEvent:UIControlEventValueChanged];
      for (NSString *action in actions) {
        SEL sel = NSSelectorFromString(action);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [target performSelector:sel withObject:slider];
#pragma clang diagnostic pop
      }
    }
  }

  return _view;
}
@end
