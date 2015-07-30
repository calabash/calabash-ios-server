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

  NSDictionary *response = nil;

  if(!keyboardView.textInputMode.primaryLanguage){
    response =
    @{
      @"outcome" : @"FAILURE",
      @"details" : @"The keyboard must be visible.",
      @"reason" : @"Could not find the keyboard view."
      };
  } else {
    response =
    @{
      @"outcome" : @"SUCCESS",
      @"results" : @{@"input_mode" : keyboardView.textInputMode.primaryLanguage},
      };
  }

  return response;
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
