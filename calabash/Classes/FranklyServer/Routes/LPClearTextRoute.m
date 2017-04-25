#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPClearTextRoute.h"
#import "UIScriptParser.h"
#import "LPTouchUtils.h"
#import "LPCocoaLumberjack.h"
#import "LPJSONUtils.h"

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
    reason = [NSString stringWithFormat:@"Target %@ does not respond to 'isFirstResponder'", target];
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
    shouldClearText = [self shouldClearTextInRange:textRange WithDelegate:delegate withTarget:target];
    if (shouldClearText) {
      [target performSelector:@selector(setText:) withObject:@""];
    }
  } else {
    // Check if it's UIKeyInput protocol
    LPLogDebug(@"Target class %@ does not respond to setText checking UIKeyInput", target);
    if ([target conformsToProtocol:@protocol(UIKeyInput)]) {
      LPLogDebug(@"Attempting to clearText with deleteBackward");
      while ([target hasText]) {
        [target deleteBackward];
      }
    } else {
      reason = [NSString stringWithFormat:@"Target %@ does not respond to setText nor deleteBackward", target];
      return [self failureResponseWithReason:reason];
    }
  }

  [self fireTextChangeMethodsWithDelegate:delegate withTarget:target];

  return [self successResponseWithResult:[LPJSONUtils jsonifyObject:target]];
}

- (BOOL)shouldClearTextInRange:(NSRange)range WithDelegate:(id)delegate withTarget:(id)target {
  if (!delegate) { return YES; }

  if ([target isKindOfClass:[UITextField class]]) {
    if ([delegate respondsToSelector:@selector(textField:shouldChangeCharactersInRange:replacementString:)]) {
      return [delegate textField:target shouldChangeCharactersInRange:range replacementString:@""];
    }
    if ([delegate respondsToSelector:@selector(textFieldShouldClear:)]) {
      return [delegate textFieldShouldClear:target];
    }
  } else if ([target isKindOfClass:[UITextView class]]) {
    return [delegate textView:target shouldChangeTextInRange:range replacementText:@""];
  } else if ([target isKindOfClass:[UISearchBar class]]) {
    return [delegate searchBar:target shouldChangeTextInRange:range replacementText:@""];
  }

  return YES;
}

- (void)fireTextChangeMethodsWithDelegate:(id)delegate withTarget:(id)target {
  if ([target isKindOfClass:[UITextField class]]) {
    [[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidChangeNotification object:target];
  } else if ([target isKindOfClass:[UITextView class]]) {
    if (delegate) {
      if ([delegate respondsToSelector:@selector(textViewDidChangeSelection:)]) {
        [delegate textViewDidChangeSelection:target];
      }

      if ([delegate respondsToSelector:@selector(textViewDidChange:)]) {
        [delegate textViewDidChange:target];
      }
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:UITextViewTextDidChangeNotification object:target];
  } else if ([target isKindOfClass:[UISearchBar class]]) {
    if (delegate && [delegate respondsToSelector:@selector(searchBar:textDidChange:)]) {
      [delegate searchBar:target textDidChange:@""];
    }
  }
}

@end
