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

    if ([@"up" isEqualToString:dir]) {
      CGFloat scrollAmount = MIN((size.height)/fraction, offset.y + sv.contentInset.top);
      point = CGPointMake(offset.x, offset.y - scrollAmount);
    } else if ([@"down" isEqualToString:dir]) {
      CGFloat scrollAmount = MIN(size.height/fraction, sv.contentSize.height + sv.contentInset.bottom - offset.y - size.height);
      point = CGPointMake(offset.x, offset.y + scrollAmount);
    } else if ([@"left" isEqualToString:dir]) {
      CGFloat scrollAmount = MIN(size.width/fraction, offset.x + sv.contentInset.left);
      point = CGPointMake(offset.x - scrollAmount, offset.y);
    } else {
      CGFloat scrollAmount = MIN(size.width/fraction, sv.contentSize.width + sv.contentInset.right - offset.x - size.width);
      point = CGPointMake(offset.x + scrollAmount, offset.y);
    }

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

@end
