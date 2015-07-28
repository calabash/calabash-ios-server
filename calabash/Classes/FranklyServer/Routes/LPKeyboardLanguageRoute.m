#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPKeyboardLanguageRoute.h"
#import "LPHTTPDataResponse.h"
#import "LPJSONUtils.h"
#import "UIScriptParser.h"
#import "LPTouchUtils.h"

@implementation LPKeyboardLanguageRoute

- (BOOL)supportsMethod:(NSString *)method atPath:(NSString *)path {
  return [method isEqualToString:@"GET"];
}

- (BOOL)canHandlePostForPath:(NSArray *)path {
  return [@"keyboard-language" isEqualToString:[path lastObject]];
}

- (NSDictionary *) JSONResponseForMethod:(NSString *) method
                                     URI:(NSString *) path
                                    data:(NSDictionary *) data {
  UIWindow *keyboardWindow = [self findKeyboardWindow];
  UIView *keyboardView = [self findKeyboardViewWith:keyboardWindow];

  NSDictionary *results;
  NSString *outcome;
  
  if(!keyboardView){
    results = @{@"input_mode": [NSNull null]};
    outcome = @"failure";
  }
  else{
    results = @{@"input_mode": keyboardView.textInputMode.primaryLanguage};
    outcome = @"success";
  }

  return @{@"outcome": outcome, @"results": results};
}

- (void)handleCurrentInputModeDidChangeNotificationWith: (NSNotification*)notification{

  NSLog(@"Inside notification %@", notification);
  id obj = [notification object];
  NSLog(@"Inside notification %@", obj);
  if ([obj respondsToSelector:@selector(primaryLanguage)]) {
    id mode = [obj performSelector:@selector(primaryLanguage)];
    NSLog(@"MODE: %@", mode);
  }
}

- (UIWindow *) findKeyboardWindow{
  UIWindow *keyboardWindow = nil;
  
  for (UIWindow *window in [LPTouchUtils applicationWindows]) {
    if ([NSStringFromClass([window class]) isEqual:@"UITextEffectsWindow"]) {
      keyboardWindow = window;
      break;
    }
  }
  return keyboardWindow;
}

- (UIView *) findKeyboardViewWith: (UIWindow *)aWindow{
  
  return [UIScriptParser findViewByClass:@"UIKBKeyplaneView"
                                fromView:aWindow];
  
}









@end
