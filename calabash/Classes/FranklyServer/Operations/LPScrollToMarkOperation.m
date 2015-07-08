//
//  LPScrollToMarkOperation.m
//  calabash
//
//  Created by Julien Curro on 18/02/14.
//  Copyright (c) 2014 Xamarin. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPScrollToMarkOperation.h"

@implementation LPScrollToMarkOperation

- (BOOL) view:(UIView *) aView hasMark:(NSString *) aMark {
  // iOS 5+
  NSString *identifier = nil;
  if ([aView respondsToSelector:@selector(accessibilityIdentifier)]) {
    identifier = aView.accessibilityIdentifier;
  }
  
  if (identifier != nil && [identifier isEqualToString:aMark]) {
    return YES;
  }
  
  if ([aView.accessibilityLabel isEqualToString:aMark]) {
    return YES;
  }
  
  if ([aView isKindOfClass:[UILabel class]]) {
    UILabel *label = (UILabel *) aView;
    if ([label.text isEqualToString:aMark]) { return YES; }
  }
  
  if ([aView isKindOfClass:[UITextView class]]) {
    UITextView *textView = (UITextView *) aView;
    if ([textView.text isEqualToString:aMark]) { return YES; }
  }
  
  return NO;
}

- (BOOL) cell:(UIView *) aCell contentViewHasSubviewMarked:(NSString *) aMark {
  if ([aCell respondsToSelector: @selector(contentView)]){
    UIView *contentView = [aCell valueForKey:@"contentView"];
    for (UIView *subview in [contentView subviews]) {
      if ([self view:subview hasMark:aMark]) { return YES; }
    }
  }
  return NO;
}

@end
