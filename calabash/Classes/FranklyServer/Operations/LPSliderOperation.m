#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPSliderOperation.h"
#import "LPJSONUtils.h"

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
- (id) performWithTarget:(UIView *) _view error:(NSError * __autoreleasing *) error {
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
    UIControlEvents events = [slider allControlEvents];
    [slider sendActionsForControlEvents:events];
  }

  return [LPJSONUtils jsonifyObject:_view];

}
@end
