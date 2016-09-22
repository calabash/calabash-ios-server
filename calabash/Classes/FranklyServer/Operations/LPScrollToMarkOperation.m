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
#import "LPInvoker.h"
#import "LPInvocationResult.h"

@interface LPScrollToMarkOperation ()

- (BOOL) view:(UIView *) aView hasTextMatchingMark:(NSString *) aMark;

@end

@implementation LPScrollToMarkOperation

- (BOOL) view:(UIView *) aView hasTextMatchingMark:(NSString *) aMark {
  if (![aView respondsToSelector:@selector(text)]) { return NO; }

  LPInvocationResult *result = [LPInvoker invokeOnMainThreadZeroArgumentSelector:@selector(text)
                                                                      withTarget:aView];
  if (result.isError || result.isNSNull) { return NO; }
  
  if (![[result.value class] isSubclassOfClass:[NSString class]]) { return NO; }

  return [aMark isEqualToString:result.value];
}

- (BOOL) view:(UIView *) aView hasMark:(NSString *) aMark {

  if ([aView.accessibilityIdentifier isEqualToString:aMark]) { return YES; }
  
  if ([aView.accessibilityLabel isEqualToString:aMark]) { return YES; }

  if ([self view:aView hasTextMatchingMark:aMark]) { return YES; }

  if ([aView isKindOfClass:[UIButton class]]) {
    UIButton *button = (UIButton *) aView;
    if ([[button currentTitle] isEqualToString:aMark]) { return YES; }
  }
  
  return NO;
}

- (BOOL) view:(UIView *)aView hasSubviewWithMark:(NSString *)aMark {
  BOOL result = NO;

  if ([self view:aView hasMark:aMark]) {
    result = YES;
  } else if ([aView.subviews count] == 0) {
    result = NO;
  } else {
    for (UIView *subView in [aView subviews]) {
      result = [self view:subView hasSubviewWithMark:aMark];
      if (result) { break; }
    }
  }
  return result;
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
