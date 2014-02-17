//
//  ScrollOperation.m
//  Created by Karl Krukow on 05/09/11.
//  Copyright 2011 LessPainful. All rights reserved.
//

#import "LPScrollOperation.h"

@implementation LPScrollOperation
- (NSString *) description {
  return [NSString stringWithFormat:@"Scroll: %@", _arguments];
}


- (id) performWithTarget:(UIView *) _view error:(NSError **) error {
  NSString *dir = [_arguments objectAtIndex:0];

  if ([_view isKindOfClass:[UIScrollView class]]) {
    UIScrollView *sv = (UIScrollView *) _view;
    CGSize size = sv.frame.size;
    CGPoint offset = sv.contentOffset;
    CGFloat fraction = 2.0;
    if ([sv isPagingEnabled]) {
      fraction = 1.0;
    }

    if ([@"up" isEqualToString:dir]) {
      [sv                                setContentOffset:CGPointMake(offset.x,
              offset.y - size.height / fraction) animated:YES];
    } else if ([@"down" isEqualToString:dir]) {
      [sv                                setContentOffset:CGPointMake(offset.x,
              offset.y + size.height / fraction) animated:YES];
    } else if ([@"left" isEqualToString:dir]) {
      [sv       setContentOffset:CGPointMake(offset.x - size.width / fraction,
              offset.y) animated:YES];
    } else if ([@"right" isEqualToString:dir]) {
      [sv       setContentOffset:CGPointMake(offset.x + size.width / fraction,
              offset.y) animated:YES];
    }

    return _view;
  } else if ([_view isKindOfClass:[UIWebView class]]) {
    UIWebView *wv = (UIWebView *) _view;
    NSString *scrollJS = @"window.scrollBy(%@,%@);";
    if ([@"up" isEqualToString:dir]) {
      scrollJS = [NSString stringWithFormat:scrollJS, @"0", @"-100"];
    } else if ([@"down" isEqualToString:dir]) {
      scrollJS = [NSString stringWithFormat:scrollJS, @"0", @"100"];
    } else if ([@"left" isEqualToString:dir]) {
      scrollJS = [NSString stringWithFormat:scrollJS, @"-100", @"0"];
    } else if ([@"right" isEqualToString:dir]) {
      scrollJS = [NSString stringWithFormat:scrollJS, @"100", @"0"];
    }
    NSString *res = [wv stringByEvaluatingJavaScriptFromString:scrollJS];
    NSLog(@"RES:%@", res);
    return _view;
  }
  return nil;
}

@end
