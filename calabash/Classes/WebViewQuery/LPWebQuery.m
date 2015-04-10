#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

//
//  LPWebQuery.m
//  CalabashJS
//
//  Created by Karl Krukow on 27/06/12.
//  Copyright (c) 2012 Xamarin. All rights reserved.
//

#import "LPWebQuery.h"
#import "LPJSONUtils.h"
#import "LPTouchUtils.h"

@interface LPWebQuery ()


+ (NSDictionary *) dictionaryByAugmentingDOMElement:(NSDictionary *) domElement
                                            webView:(UIView<LPWebViewProtocol> *) webView
                              accumlateInDictionary:(NSMutableDictionary *) accumulator;

+ (CGPoint) pointByAdjustingOffsetForScrollPostionOfWebView:(UIView<LPWebViewProtocol> *) webView;

+ (BOOL) point:(CGPoint) center isVisibleInWebview:(UIView<LPWebViewProtocol> *) webView;

@end

@implementation LPWebQuery

+ (BOOL) point:(CGPoint) center isVisibleInWebview:(UIView<LPWebViewProtocol> *) webView {
  BOOL pointInsideCenter = [webView pointInside:center withEvent:nil];
  BOOL centerNotZeroPoint = !CGPointEqualToPoint(CGPointZero, center);
  return centerNotZeroPoint && pointInsideCenter;
}

+ (NSArray *) arrayByEvaluatingQuery:(NSString *) query
                                type:(LPWebQueryType) type
                             webView:(UIView<LPWebViewProtocol> *) webView
                    includeInvisible:(BOOL) includeInvisible {
  NSString *jsString = nil;
  switch (type) {
    case LPWebQueryTypeCSS:
      jsString = [NSString stringWithFormat:LP_QUERY_JS,query,@"css", @""];
      break;

    case LPWebQueryTypeXPATH:
      jsString = [NSString stringWithFormat:LP_QUERY_JS,query,@"xpath",@""];
      break;
    case LPWebQueryTypeFreeText:
      jsString = [NSString stringWithFormat:LP_QUERY_JS,
                  [NSString stringWithFormat:@"//node()[contains(text(),\\\"%@\\\")]", query],
                  @"xpath",@""];
      break;
    default:
      return nil;
  }

  NSMutableArray *result = [NSMutableArray array];

  NSString *output = [webView calabashStringByEvaluatingJavaScript:jsString];

  NSArray *queryResult = [LPJSONUtils deserializeArray:output];

  UIWindow *window = [LPTouchUtils windowForView:webView];
  UIWindow *frontWindow = [[UIApplication sharedApplication] keyWindow];
  CGPoint webViewPageOffset = [self pointByAdjustingOffsetForScrollPostionOfWebView:webView];

  for (NSDictionary *d in queryResult) {
    NSMutableDictionary *dres = [NSMutableDictionary dictionaryWithDictionary:d];
    CGFloat center_x = [[dres valueForKeyPath:@"rect.x"] floatValue];
    CGFloat center_y = [[dres valueForKeyPath:@"rect.y"] floatValue];

    CGPoint center = CGPointMake(webViewPageOffset.x + center_x, webViewPageOffset.y + center_y);
    CGPoint windowCenter = [window convertPoint:center fromView:webView];
    CGPoint keyCenter = [frontWindow convertPoint:windowCenter fromWindow:window];
    CGPoint finalCenter = [LPTouchUtils translateToScreenCoords:keyCenter];

    if (includeInvisible || [self point:center isVisibleInWebview:webView]) {
      NSDictionary *centerDict = (__bridge_transfer NSDictionary *)CGPointCreateDictionaryRepresentation(finalCenter);
      [dres setValue:centerDict forKey:@"center"];
      [dres setValue:webView forKey:@"webView"];

      [dres setValue:[NSNumber numberWithFloat:finalCenter.x] forKeyPath:@"rect.center_x"];
      [dres setValue:[NSNumber numberWithFloat:finalCenter.y] forKeyPath:@"rect.center_y"];
      [dres setValue:[NSNumber numberWithFloat:finalCenter.x] forKeyPath:@"rect.x"];
      [dres setValue:[NSNumber numberWithFloat:finalCenter.y] forKeyPath:@"rect.y"];

      [result addObject:dres];
    }
  }
  return result;
}

+ (NSDictionary *) dictionaryOfViewsInWebView:(UIView<LPWebViewProtocol> *) webView {
  NSString *jsString = [NSString stringWithFormat:LP_QUERY_JS,@"",@"dump", @""];

  NSString *output = [webView calabashStringByEvaluatingJavaScript:jsString];
  NSDictionary *dumpResult = [LPJSONUtils deserializeDictionary:output];
  NSMutableDictionary *finalResult = [NSMutableDictionary dictionaryWithDictionary:dumpResult];
  if (!(finalResult[@"type"])) {
    finalResult[@"type"] = @"dom";
  }
  return [self dictionaryByAugmentingDOMElement:dumpResult
                                        webView:webView
                          accumlateInDictionary:finalResult];
}


+ (NSDictionary *) dictionaryByAugmentingDOMElement:(NSDictionary *) domElement
                                            webView:(UIView<LPWebViewProtocol> *) webView
                              accumlateInDictionary:(NSMutableDictionary *) accumulator {

  CGPoint webViewPageOffset = [self pointByAdjustingOffsetForScrollPostionOfWebView:webView];

  NSMutableArray *children = [NSMutableArray arrayWithCapacity:8];

  for (NSDictionary *domChild in domElement[@"children"]) {
    NSDictionary *rectAsDict = domChild[@"rect"];
    if ([rectAsDict isKindOfClass:[NSNull class]]) {
      continue;
    }

    CGRect domChildRect = CGRectMake([rectAsDict[@"left"] floatValue],
                                     [rectAsDict[@"top"] floatValue],
                                     [rectAsDict[@"width"] floatValue],
                                     [rectAsDict[@"height"] floatValue]);

    CGRect domChildBounds = CGRectMake(domChildRect.origin.x + webViewPageOffset.x,
                                       domChildRect.origin.y + webViewPageOffset.y,
                                       domChildRect.size.width,
                                       domChildRect.size.height);

    CGRect translatedRect = [LPTouchUtils translateRect:domChildBounds inView:webView.scrollView];

    CGFloat center_x = translatedRect.origin.x + translatedRect.size.width/2.0f;
    CGFloat center_y = translatedRect.origin.y + translatedRect.size.height/2.0f;

    CGPoint contentOffset = [webView.scrollView contentOffset];
    CGPoint boundsCenterInScrollView = CGPointMake(contentOffset.x + domChildBounds.origin.x + domChildBounds.size.width/2.0f,
                                                   contentOffset.y + domChildBounds.origin.y + domChildBounds.size.height/2.0f);

    NSMutableDictionary *rectDict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                     @(center_x), @"center_x",
                                     @(center_y), @"center_y",
                                     @(translatedRect.origin.x), @"x",
                                     @(translatedRect.origin.y), @"y",
                                     @(translatedRect.size.width), @"width",
                                     @(translatedRect.size.height), @"height",
                                     nil];

    NSMutableDictionary *augmentedChild = [NSMutableDictionary dictionaryWithDictionary:domChild];
    augmentedChild[@"rect"] = rectDict;
    augmentedChild[@"hit-point"] = @{@"x": @(center_x), @"y": @(center_y)};
    if (!(augmentedChild[@"type"])) {
      augmentedChild[@"type"] = @"dom";
    }

    if (!CGPointEqualToPoint(CGPointZero, boundsCenterInScrollView) && [webView.scrollView pointInside:boundsCenterInScrollView withEvent:nil]) {
      [augmentedChild setValue:@(1) forKeyPath:@"visible"];

      UIWindow *windowForView = [LPTouchUtils windowForView:webView];
      CGPoint windowBounds = [windowForView convertPoint:boundsCenterInScrollView fromView:webView.scrollView];
      UIView *hitView = [windowForView hitTest:windowBounds withEvent:nil];
      if (![LPTouchUtils canFindView:webView asSubViewInView:hitView]) {
        UIView *hitSuperView = hitView;

        while (hitSuperView && hitSuperView != webView) {
          hitSuperView = [hitSuperView superview];
        }
        if (hitSuperView != webView) {
          [augmentedChild setValue:@(0) forKeyPath:@"visible"];
        }
      }
    } else {
      [augmentedChild setValue:@(0) forKeyPath:@"visible"];
    }

    [self dictionaryByAugmentingDOMElement:domChild
                                   webView:webView
                     accumlateInDictionary:augmentedChild];
    [children addObject:augmentedChild];
  }
  accumulator[@"children"] = children;
  return accumulator;
}

+ (CGPoint) pointByAdjustingOffsetForScrollPostionOfWebView:(UIView<LPWebViewProtocol> *) webView {
  CGPoint webViewPageOffset = CGPointMake(0, 0);
  if ([webView respondsToSelector:@selector(scrollView)]) {
    id scrollView = [webView performSelector:@selector(scrollView) withObject:nil];
    if ([scrollView respondsToSelector:@selector(contentOffset)]) {
      CGPoint scrollViewOffset = [scrollView contentOffset];
      NSString *pageOffsetStr = [webView calabashStringByEvaluatingJavaScript:@"window.pageYOffset"];
      webViewPageOffset = CGPointMake(0, [pageOffsetStr floatValue] - scrollViewOffset.y);
    }
  }
  return webViewPageOffset;
}

@end
