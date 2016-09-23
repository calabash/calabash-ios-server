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
#import "LPScrollToRowWithMarkOperation.h"
#import "LPCollectionViewScrollToItemWithMarkOperation.h"
#import "LPTouchUtils.h"
#import "LPCocoaLumberjack.h"

@interface LPScrollToMarkOperation ()

- (BOOL) view:(UIView *) aView hasTextMatchingMark:(NSString *) aMark;
- (NSDictionary *)operationDictionary;

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

- (UIView *)view:(UIView *) aView subviewWithMark:(NSString *) aMark {
  UIView *result = nil;

  if (!aView) {
    return nil;
  } else {
    if ([self view:aView hasMark:aMark]) {
      result = aView;
    }
    for (UIView* subView in [aView subviews]) {
      result = [self view:subView subviewWithMark:aMark];
      if (result) { break; }
    }
  }

  return result;
}

- (NSDictionary *)operationDictionary {
  return @{
           @"method_name" : NSStringFromSelector(self.selector),
           @"arguments" : self.arguments
           };
}

//                 required, optional
// _arguments ==>   [mark,  animated]
- (id) performWithTarget:(id) target error:(NSError *__autoreleasing*) error {

  if (!target) {
    LPLogWarn(@"Cannot perform operation on nil target");
    return nil;
  }

  Class targetClass = [target class];
  if (![targetClass isSubclassOfClass:[UIScrollView class]]) {
    LPLogWarn(@"View %@ should be a UIScrollView or subclass but found '%@'",
    target, NSStringFromClass(targetClass));
    return nil;
  }

  NSString *mark = [self.arguments objectAtIndex:0];
  if (!mark || [mark length] == 0) {
    LPLogWarn(@"Mark: '%@' should be non-nil and non-empty", mark);
    return nil;
  }

  Class UITableViewWrapperClass = NSClassFromString(@"UITableViewWrapperView");

  if ([targetClass isSubclassOfClass:UITableViewWrapperClass]) {
    LPLogDebug(@"View is UITableViewWrapperView - skipping");
    return nil;
  }

  if ([targetClass isSubclassOfClass:[UITableView class]]) {
    LPLogDebug(@"Target is a UITableView: %@", target);

    NSMutableDictionary *dictionary = [[self operationDictionary] mutableCopy];
    NSMutableArray *arguments = [dictionary[@"arguments"] mutableCopy];
    
    // Table view operation requires scroll position
    // mark and animate are the arguments passed to this method.
    // Table view operation expects scroll position at index 1 and animate at
    // index 2.
    [arguments insertObject:@"middle" atIndex:1];
    dictionary[@"arguments"] = [NSArray arrayWithArray:arguments];

    LPScrollToRowWithMarkOperation *operation;
    operation = [[LPScrollToRowWithMarkOperation alloc]
                 initWithOperation:[NSDictionary dictionaryWithDictionary:dictionary]];
    return [operation performWithTarget:target error:error];
  }

  if ([targetClass isSubclassOfClass:[UICollectionView class]]) {
    LPLogDebug(@"Target is a UICollectionView: %@", target);

    NSMutableDictionary *dictionary = [[self operationDictionary] mutableCopy];
    NSMutableArray *arguments = [dictionary[@"arguments"] mutableCopy];

    // Collection view operation requires scroll position
    // mark and animate are the arguments passed to this method.
    // Collection view operation expects scroll position at index 1 and animate
    // at index 2.
    [arguments insertObject:@"center_vertical" atIndex:1];
    dictionary[@"arguments"] = [NSArray arrayWithArray:arguments];

    LPCollectionViewScrollToItemWithMarkOperation *operation;
    operation = [[LPCollectionViewScrollToItemWithMarkOperation alloc]
                 initWithOperation:[NSDictionary dictionaryWithDictionary:dictionary]];
    return [operation performWithTarget:target error:error];
  }

  LPLogDebug(@"Target is not a UITableView or UICollectionView: %@",
             NSStringFromClass(targetClass));

  BOOL animate = YES;
  if ([self.arguments count] == 2) {
    animate = [self.arguments[1] boolValue];
  }

  UIScrollView *scrollView = (UIScrollView *)target;
  UIView *subview = [self view:scrollView subviewWithMark:mark];

  if (subview) {
    [scrollView scrollRectToVisible:[subview frame] animated:animate];
    return subview;
  } else {
    LPLogWarn(@"ScrollView doesn't contain a subview with mark '%@'", mark);
    return nil;
  }
}

@end
