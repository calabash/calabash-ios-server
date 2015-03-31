//
//  ScrollOperation.m
//  Created by Karl Krukow on 05/09/11.
//  Copyright 2011 LessPainful. All rights reserved.
//

#import "LPScrollOperation.h"
#import "UIWebView+LPWebView.h"
#import "WKWebView+LPWebView.h"
#import "UIView+LPIsWebView.h"
#import "LPWebViewProtocol.h"

@implementation LPScrollOperation
- (NSString *) description {
  return [NSString stringWithFormat:@"Scroll: %@", _arguments];
}


- (id) performWithTarget:(UIView *) _view error:(NSError **) error {
  NSString *dir = [_arguments objectAtIndex:0];

  if ([_view isKindOfClass:[UIScrollView class]]) {
    UIScrollView *sv = (UIScrollView *) _view;
    CGSize size = sv.bounds.size;
    CGPoint offset = sv.contentOffset;
    CGFloat fraction = 2.0;
    if ([sv isPagingEnabled]) {
      fraction = 1.0;
    }
    
    if ([@"up" isEqualToString:dir]) {
      CGFloat scrollAmount = MIN((size.height)/fraction, offset.y + sv.contentInset.top);
      [sv setContentOffset:CGPointMake(offset.x, offset.y - scrollAmount) animated:YES];
    } else if ([@"down" isEqualToString:dir]) {
      CGFloat scrollAmount = MIN(size.height/fraction, sv.contentSize.height + sv.contentInset.bottom - offset.y - size.height);
      [sv setContentOffset:CGPointMake(offset.x, offset.y + scrollAmount) animated:YES];
    } else if ([@"left" isEqualToString:dir]) {
      CGFloat scrollAmount = MIN(size.width/fraction, offset.x + sv.contentInset.left);
      [sv setContentOffset:CGPointMake(offset.x - scrollAmount, offset.y) animated:YES];
    } else if ([@"right" isEqualToString:dir]) {
      CGFloat scrollAmount = MIN(size.width/fraction, sv.contentSize.width + sv.contentInset.right - offset.x - size.width);
      [sv setContentOffset:CGPointMake(offset.x + scrollAmount, offset.y) animated:YES];
    }
    
    return _view;
  } else if ([_view lpIsWebView]) {
    UIView<LPWebViewProtocol> *webView = (UIView<LPWebViewProtocol> *)_view;
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
    NSString *res = [webView calabashStringByEvaluatingJavaScript:scrollJS];
    NSLog(@"RES:%@", res);
    return _view;
  }
  return nil;
}

@end
