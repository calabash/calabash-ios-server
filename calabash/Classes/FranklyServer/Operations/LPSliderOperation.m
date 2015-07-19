#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPSliderOperation.h"
#import "LPJSONUtils.h"

@implementation LPSliderOperation

/*
 args << options[:notify_targets] || true
 args << options[:animate] || true
 */

//    required ===========> |     optional
//  _arguments => [value_str,  notify targets, animate]
- (id) performWithTarget:(id) target error:(NSError * __autoreleasing *) error {
  if ([target isKindOfClass:[UISlider class]] == NO) {
    NSLog(@"Warning view: %@ should be a UISlier", target);
    return nil;
  }

  UISlider *slider = (UISlider *) target;

  NSArray *arguments = self.arguments;

  NSString *valueStr = arguments[0];
  if (valueStr == nil || [valueStr length] == 0) {
    NSLog(@"Warning: value str: '%@' should be non-nil and non-empty",
            valueStr);
    return nil;
  }

  CGFloat targetValue = [valueStr floatValue];

  NSUInteger argcount = [arguments count];

  BOOL notifyTargets = YES;
  if (argcount > 1) {
    notifyTargets = [arguments[1] boolValue];
  }

  BOOL animate = YES;
  if (argcount > 2) {
    animate = [arguments[2] boolValue];
  }

  if (targetValue > [slider maximumValue]) {
    NSLog(@"Warning: target value '%.2f' is greater than slider max value '%.2f' - will slide to max value",
            targetValue, [slider maximumValue]);
  }

  if (targetValue < [slider minimumValue]) {
    NSLog(@"Warning: target value '%.2f' is less than slider min value '%.2f' - will slide to min value",
            targetValue, [slider minimumValue]);
  }

  if (notifyTargets) {
    UIControlEvents events = [slider allControlEvents];
    [slider setValue:targetValue animated:animate];
    [slider sendActionsForControlEvents:events];
  }

  return [LPJSONUtils jsonifyObject:target];
}
@end
