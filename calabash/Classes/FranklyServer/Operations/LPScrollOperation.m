//
//  ScrollOperation.m
//  Created by Karl Krukow on 05/09/11.
//  Copyright 2011 LessPainful. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPScrollOperation.h"
#import "UIWebView+LPWebView.h"
#import "LPWebViewUtils.h"
#import "LPWebViewProtocol.h"
#import "LPCocoaLumberjack.h"
#import "LPJSONUtils.h"
#import "LPInvoker.h"
#import "LPInvocationResult.h"

@implementation LPScrollOperation

- (id) performWithTarget:(id) target error:(NSError *__autoreleasing*) error {

  NSString *dir = [self.arguments objectAtIndex:0];

  NSArray *allowedDirections = @[@"up", @"down", @"left", @"right"];
  NSUInteger index = [allowedDirections indexOfObject:dir];
  if (index == NSNotFound) {
    LPLogError(@"Expected direction '%@' to be: up, down, left, or right", dir);
    LPLogError(@"Returning nil");
    if (error != NULL) {
      *error = [NSError errorWithDomain:@"Calabash"
                                   code:1
                               userInfo:nil];
    }
    return nil;
  }

  if ([target isKindOfClass:[UIScrollView class]]) {
    UIScrollView *sv = (UIScrollView *) target;
    CGSize size = sv.bounds.size;
    CGPoint offset = sv.contentOffset;
    CGFloat fraction = 2.0;
    if ([sv isPagingEnabled]) {
      fraction = 1.0;
    }

    CGPoint point;
    CGFloat contentInset;

    if ([@"up" isEqualToString:dir]) {
      contentInset = [self insetForScrollView:sv direction:@"up"];
      CGFloat scrollAmount = MIN((size.height)/fraction, offset.y + contentInset);
      point = CGPointMake(offset.x, offset.y - scrollAmount);
    } else if ([@"down" isEqualToString:dir]) {
      contentInset = [self insetForScrollView:sv direction:@"down"];
      CGFloat scrollAmount = MIN(size.height/fraction,
                                 contentInset - offset.y - size.height);
      point = CGPointMake(offset.x, offset.y + scrollAmount);
    } else if ([@"left" isEqualToString:dir]) {
      contentInset = [self insetForScrollView:sv direction:@"left"];
      CGFloat scrollAmount = MIN(size.width/fraction, offset.x + contentInset);
      point = CGPointMake(offset.x - scrollAmount, offset.y);
    } else {
      contentInset = [self insetForScrollView:sv direction:@"right"];
      CGFloat scrollAmount = MIN(size.width/fraction,
                                 contentInset - offset.x - size.width);
      point = CGPointMake(offset.x + scrollAmount, offset.y);
    }

    LPLogDebug(@"Scrolling to offset: %@", NSStringFromCGPoint(point));

    [sv setContentOffset:point animated:YES];
    return [LPJSONUtils jsonifyObject:target];
  } else if ([LPWebViewUtils isWebView:target]) {
    NSString *scrollJS = @"window.scrollBy(%@,%@);";
    if ([@"up" isEqualToString:dir]) {
      scrollJS = [NSString stringWithFormat:scrollJS, @"0", @"-100"];
    } else if ([@"down" isEqualToString:dir]) {
      scrollJS = [NSString stringWithFormat:scrollJS, @"0", @"100"];
    } else if ([@"left" isEqualToString:dir]) {
      scrollJS = [NSString stringWithFormat:scrollJS, @"-100", @"0"];
    } else {
      scrollJS = [NSString stringWithFormat:scrollJS, @"100", @"0"];
    }

    [target calabashStringByEvaluatingJavaScript:scrollJS];

    return [LPJSONUtils jsonifyObject:target];
  }
  return nil;
}

- (CGFloat)insetForScrollView:(UIScrollView *)view
                    direction:(NSString *)direction {

  CGFloat contentInset;
  SEL selector = NSSelectorFromString(@"adjustedContentInset");
  if ([@"up" isEqualToString:direction]) {
    if ([view respondsToSelector:selector]) {
      contentInset = [self adjustedContentInset:view edge:@"Top"];
    } else {
      contentInset = view.contentInset.top;
    }
  } else if ([@"down" isEqualToString:direction]) {
    if ([view respondsToSelector:selector]) {
      contentInset = [self adjustedContentInset:view edge:@"Bottom"];
    } else {
      contentInset = view.contentInset.bottom;
    }
    contentInset = contentInset + view.contentSize.height;
  } else if ([@"left" isEqualToString:direction]) {
    if ([view respondsToSelector:selector]) {
      contentInset = [self adjustedContentInset:view edge:@"Left"];
    } else {
      contentInset = view.contentInset.left;
    }
  } else {
    if ([view respondsToSelector:selector]) {
      contentInset = [self adjustedContentInset:view edge:@"Right"];
    } else {
      contentInset = view.contentInset.right;
    }
    contentInset = contentInset + view.contentSize.width;
  }

  return contentInset;
}

- (CGFloat)adjustedContentInset:(UIScrollView *)view
                           edge:(NSString *)edge {
  SEL selector = NSSelectorFromString(@"adjustedContentInset");
  LPInvocationResult *result;
  result = [LPInvoker invokeOnMainThreadZeroArgumentSelector:selector
                                                  withTarget:view];

  if ([result isError]) {
    LPLogError(@"Error finding adjusted content inset: %@", [result description]);
    LPLogError(@"returning 0.0");
    return 0.0;
  } else if ([result isNSNull]) {
    LPLogError(@"NSNull returned for adjusted content inset");
    LPLogError(@"returning 0.0");
    return 0.0;
  } else {
    NSDictionary *dict = (NSDictionary *)[result value];
    return (CGFloat)[dict[edge] floatValue];
  }
}

@end
