#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPDatePickerOperation.h"

@implementation LPDatePickerOperation

/*
 args << options[:is_timer] || false
 args << options[:notify_targets] || true
 args << options[:animate] || true
 */


//                        required =========> |     optional
// _arguments ==> [target date str, format str, notify targets, animated]
- (id) performWithTarget:(UIView *) view error:(NSError *__autoreleasing*) error {
  if ([view isKindOfClass:[UIDatePicker class]] == NO) {
    NSLog(@"Warning view: %@ should be a date picker", view);
    return nil;
  }

  NSArray *arguments = self.arguments;

  UIDatePicker *picker = (UIDatePicker *) view;

  NSString *dateStr = arguments[0];
  if (dateStr == nil || [dateStr length] == 0) {
    NSLog(@"Warning: date str: '%@' should be non-nil and non-empty", dateStr);
    return nil;
  }

  NSUInteger argcount = [arguments count];

  NSString *dateFormat = nil;
  if (argcount > 1) {
    dateFormat = arguments[1];
  } else {
    NSLog(@"Warning: date format is required as the second argument");
    return nil;
  }


  BOOL notifyTargets = YES;
  if (argcount > 2) {
    notifyTargets = [arguments[2] boolValue];
  }

  BOOL animate = YES;
  if (argcount > 3) {
    animate = [arguments[3] boolValue];
  }

  NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
  [formatter setDateFormat:dateFormat];
  NSDate *date = [formatter dateFromString:dateStr];
  if (date == nil) {
    NSLog(@"Warning: could not create date from '%@' and format '%@'", dateStr,
            dateFormat);
    return nil;
  }

  NSDate *minDate = picker.minimumDate;
  if (minDate != nil && [date compare:minDate] == NSOrderedAscending) {
    NSLog(@"Warning: could not set the date to '%@' because is earlier than the minimum date '%@'",
            date,
            [minDate descriptionWithLocale:[NSLocale autoupdatingCurrentLocale]]);
    return nil;
  }

  NSDate *maxDate = picker.maximumDate;
  if (maxDate != nil && [date compare:maxDate] == NSOrderedDescending) {
    NSLog(@"Warning: could not set the date to '%@' because is later than the maximum date '%@'",
            date,
            [maxDate descriptionWithLocale:[NSLocale autoupdatingCurrentLocale]]);
    return nil;
  }

  if (notifyTargets) {
    if ([[NSThread currentThread] isMainThread]) {
      [picker setDate:date animated:animate];
      UIControlEvents events = [picker allControlEvents];
      [picker sendActionsForControlEvents:events];
    } else {
      dispatch_sync(dispatch_get_main_queue(), ^{
        [picker setDate:date animated:animate];
        UIControlEvents events = [picker allControlEvents];
        [picker sendActionsForControlEvents:events];
      });
    }
  }

  return view;
}

@end
