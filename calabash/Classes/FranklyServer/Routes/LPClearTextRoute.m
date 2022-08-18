#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPClearTextRoute.h"
#import "UIScriptParser.h"
#import "LPTouchUtils.h"
#import "LPCocoaLumberjack.h"
#import "LPJSONUtils.h"
#import "LPMachClock.h"

// TODO We might need to implement something to handle target/action pairs.
// [textField addTarget:self
//               action:@selector(myTextChangedMethod:)
//     forControlEvents:UIControlEventEditingChanged];

@implementation LPClearTextRoute

- (BOOL) supportsMethod:(NSString *) method atPath:(NSString *) path {
  return [method isEqualToString:@"GET"];
}

- (NSDictionary *)failureResponseWithReason:(NSString *)reason {
  return @{
           @"outcome" : @"FAILURE",
           @"reason" : reason,
           @"details" : @""
           };
}

- (NSDictionary *)successResponseWithResult:(id)result {
  return @{
           @"outcome" : @"SUCCESS",
           @"results" : @[result]
           };
}

- (id)firstResponder {
  NSString *query = @"* isFirstResponder:1 index:0";
  UIScriptParser *parser = [[UIScriptParser alloc] initWithUIScript:query];
  [parser parse];
  NSArray *allWindows = [LPTouchUtils applicationWindows];
  NSArray *results = [parser evalWith:allWindows];
  if (!results || results.count == 0) {
    return nil;
  } else {
    return results[0];
  }
}

- (NSDictionary *)JSONResponseForMethod:(NSString *) method
                                    URI:(NSString *) path
                                   data:(NSDictionary *) data {
  NSString *reason = @"";
  id target = [self firstResponder];
  if (!target) {
    reason = [NSString stringWithFormat:@"Cannot clear text because no view is first responder"];
    LPLogError(@"%@", reason);
    return [self failureResponseWithReason:reason];
  }

  if (![target respondsToSelector:@selector(isFirstResponder)]) {
    reason = [NSString stringWithFormat:@"Target %@ does not respond to 'isFirstResponder'",
              target];
    return [self failureResponseWithReason:reason];
  }

  id delegate = nil;
  if ([target respondsToSelector:@selector(delegate)]) {
    delegate = [target performSelector:@selector(delegate)];
  }

  BOOL shouldClearText = YES;
  NSString *existingText = @"";
  if ([target respondsToSelector:@selector(text)]) {
    id currentText = [target performSelector:@selector(text)];
    if (currentText) {
      existingText = (NSString *)currentText;
    }
  }

  NSRange textRange = NSRangeFromString(existingText);
  if ([target respondsToSelector:@selector(setText:)]) {
    shouldClearText = [self shouldClearTextInRange:textRange
                                          delegate:delegate
                                            target:target];
    if (shouldClearText) {
      [target performSelector:@selector(setText:) withObject:@""];
    }
  } else {
    // Check if it's UIKeyInput protocol
    LPLogDebug(@"Target class %@ does not respond to setText; checking UIKeyInput",
               target);
    if ([target conformsToProtocol:@protocol(UIKeyInput)]) {
      LPLogDebug(@"Attempting to clearText with deleteBackward");
      NSTimeInterval startTime = [[LPMachClock sharedClock] absoluteTime];
      NSTimeInterval endTime = startTime + 20.0; // Timeout after 20s
      while ([target hasText] && [[LPMachClock sharedClock] absoluteTime] < endTime) {
        [target deleteBackward];
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, false);
      }
      if ([target hasText]) {
        reason = [NSString stringWithFormat:@"Timed out clearing text from UIKeyInput"];
        LPLogError(@"%@", reason);
        return [self failureResponseWithReason:reason];
      }
    } else {
      reason = [NSString stringWithFormat:@"Target %@ does not respond to setText nor deleteBackward",
                target];
      return [self failureResponseWithReason:reason];
    }
  }

  [self postTextChangedNotificationAndCallDelegateMethodsOnTarget:target
                                                         delegate:delegate];

  return [self successResponseWithResult:[LPJSONUtils jsonifyObject:target]];
}

- (BOOL)shouldClearTextInRange:(NSRange)range
                      delegate:(id)delegate
                        target:(id)target {
  if (!delegate) { return YES; }

  if ([target isKindOfClass:[UITextField class]]) {
    SEL selector = @selector(textField:shouldChangeCharactersInRange:replacementString:);
    if ([delegate respondsToSelector:selector]) {
      return [delegate textField:target
   shouldChangeCharactersInRange:range
               replacementString:@""];
    }
    if ([delegate respondsToSelector:@selector(textFieldShouldClear:)]) {
      return [delegate textFieldShouldClear:target];
    }
  } else if ([target isKindOfClass:[UITextView class]] && [delegate respondsToSelector: @selector(textView:shouldChangeTextInRange:replacementText:)]) {
    return [delegate textView:target
      shouldChangeTextInRange:range
              replacementText:@""];
  } else if ([target isKindOfClass:[UISearchBar class]] && [delegate respondsToSelector: @selector(searchBar:shouldChangeTextInRange:replacementText:)]) {
    return [delegate searchBar:target
       shouldChangeTextInRange:range
               replacementText:@""];
  }

  return YES;
}

- (void)postTextChangedNotificationAndCallDelegateMethodsOnTarget:(id)target
                                                         delegate:(id)delegate {
  if ([target isKindOfClass:[UITextField class]]) {
    [[NSNotificationCenter defaultCenter]
     postNotificationName:UITextFieldTextDidChangeNotification
     object:target];
  } else if ([target isKindOfClass:[UITextView class]]) {
    if (delegate) {
      if ([delegate respondsToSelector:@selector(textViewDidChangeSelection:)]) {
        [delegate textViewDidChangeSelection:target];
      }

      if ([delegate respondsToSelector:@selector(textViewDidChange:)]) {
        [delegate textViewDidChange:target];
      }
    }
    [[NSNotificationCenter defaultCenter]
     postNotificationName:UITextViewTextDidChangeNotification
     object:target];
  } else if ([target isKindOfClass:[UISearchBar class]]) {
    if (delegate && [delegate respondsToSelector:@selector(searchBar:textDidChange:)]) {
      [delegate searchBar:target textDidChange:@""];
    }
  }
}

@end
