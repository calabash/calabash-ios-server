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
#import "LPConstants.h"
#import "LPCocoaLumberjack.h"
#import "LPDevice.h"

@implementation LPWebQuery

+ (BOOL) point:(CGPoint) center isVisibleInWebview:(UIView<LPWebViewProtocol> *) webView {
  BOOL pointInsideCenter = [webView pointInside:center withEvent:nil];
  BOOL centerNotZeroPoint = !CGPointEqualToPoint(CGPointZero, center);
  return centerNotZeroPoint && pointInsideCenter;
}

+ (NSArray *) arrayByEvaluatingQuery:(NSString *) query
                       frameSelector:(NSString *) frameSelector
                                type:(LPWebQueryType) type
                             webView:(UIView<LPWebViewProtocol> *) webView
                    includeInvisible:(BOOL) includeInvisible {
  frameSelector = frameSelector ?: @"";
  NSString *jsString = nil;
  switch (type) {
    case LPWebQueryTypeCSS:
      jsString = [NSString stringWithFormat:LP_QUERY_JS,query,@"css", @"", frameSelector];
      break;

    case LPWebQueryTypeXPATH:
      jsString = [NSString stringWithFormat:LP_QUERY_JS,query,@"xpath",@"", frameSelector];
      break;
    default:
      return nil;
  }

  NSMutableArray *result = [NSMutableArray array];

  NSString *output = [webView calabashStringByEvaluatingJavaScript:jsString];

  NSArray *queryResult = [LPJSONUtils deserializeArray:output];

  UIWindow *window = [LPTouchUtils windowForView:webView];
  UIWindow *frontWindow = [[UIApplication sharedApplication] keyWindow];
  CGPoint webViewPageOffset = [LPWebQuery pointByAdjustingOffsetForScrollPositionOfWebView:webView];

  for (NSDictionary *d in queryResult) {
    NSMutableDictionary *dres = [NSMutableDictionary dictionaryWithDictionary:d];

    // Inexplicably, rect.x and rect.y are the _center_.
    CGFloat center_x = [[dres valueForKeyPath:@"rect.x"] floatValue];
    CGFloat center_y = [[dres valueForKeyPath:@"rect.y"] floatValue];

    CGPoint center = CGPointMake(webViewPageOffset.x + center_x,
                                 webViewPageOffset.y + center_y);
    CGPoint windowCenter = [window convertPoint:center fromView:webView];
    CGPoint keyCenter = [frontWindow convertPoint:windowCenter
                                       fromWindow:window];
    CGPoint finalCenter;

    finalCenter = [LPWebQuery centerByApplyingTransformationsToPoint:keyCenter];

    if (includeInvisible || [LPWebQuery point:center
                           isVisibleInWebview:webView]) {
      NSDictionary *centerDict;
      centerDict = (__bridge_transfer NSDictionary *)CGPointCreateDictionaryRepresentation(finalCenter);
      [dres setValue:centerDict forKey:@"center"];
      [dres setValue:webView forKey:@"webView"];

      [dres setValue:[NSNumber numberWithFloat:finalCenter.x] forKeyPath:@"rect.center_x"];
      [dres setValue:[NSNumber numberWithFloat:finalCenter.y] forKeyPath:@"rect.center_y"];
      [dres setValue:[dres valueForKeyPath:@"rect.left"] forKeyPath:@"rect.x"];
      [dres setValue:[dres valueForKeyPath:@"rect.top"] forKeyPath:@"rect.y"];

      /*
       When doing iframe queries, we need to store all of the information needed to
       recreate the iframe query in case subsequent tokens from the original
       query string need to traverse further into the iframe.

       E.g., UIWebView css:'iframe' css:'#myElement'
       */
      if ([dres[NODE_NAME_KEY] isEqualToString:IFRAME_KEY]) {
        dres[IFRAME_INFO_KEY] = @{
                                  QUERY_KEY : query,
                                  QUERY_TYPE_KEY : @(type)
                                  };
      }

      [result addObject:dres];
    }
  }
  return result;
}

+ (NSDictionary *) dictionaryOfViewsInWebView:(UIView<LPWebViewProtocol> *) webView {
  NSString *jsString = [NSString stringWithFormat:LP_QUERY_JS,@"",@"dump", @"", @""];

  NSString *output = [webView calabashStringByEvaluatingJavaScript:jsString];
  NSDictionary *dumpResult = [LPJSONUtils deserializeDictionary:output];
  NSMutableDictionary *finalResult = [NSMutableDictionary dictionaryWithDictionary:dumpResult];
  if (!(finalResult[@"type"])) {
    finalResult[@"type"] = @"dom";
  }
  return [LPWebQuery dictionaryByAugmentingDOMElement:dumpResult
                                              webView:webView
                               accumulateInDictionary:finalResult];
}


+ (NSDictionary *)dictionaryByAugmentingDOMElement:(NSDictionary *)domElement
                                           webView:(UIView <LPWebViewProtocol> *)webView
                            accumulateInDictionary:(NSMutableDictionary *) accumulator {

  CGPoint webViewPageOffset = [LPWebQuery pointByAdjustingOffsetForScrollPositionOfWebView:webView];

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

    CGRect translatedRect = [LPWebQuery translateRect:domChildBounds
                                               inView:webView.scrollView];

    CGFloat center_x = translatedRect.origin.x + translatedRect.size.width/2.0f;
    CGFloat center_y = translatedRect.origin.y + translatedRect.size.height/2.0f;

    CGPoint contentOffset = [webView.scrollView contentOffset];
    CGPoint boundsCenterInScrollView;
    boundsCenterInScrollView = CGPointMake(contentOffset.x + domChildBounds.origin.x +
                                           domChildBounds.size.width/2.0f,
                                           contentOffset.y + domChildBounds.origin.y +
                                           domChildBounds.size.height/2.0f);

    NSMutableDictionary *rectDict = [@{@"center_x": @(center_x),
                                       @"center_y": @(center_y),
                                       @"x"       : @(translatedRect.origin.x),
                                       @"y"       : @(translatedRect.origin.y),
                                       @"width"   : @(translatedRect.size.width),
                                       @"height"  : @(translatedRect.size.height)
                                       } mutableCopy];

    NSMutableDictionary *augmentedChild = [NSMutableDictionary dictionaryWithDictionary:domChild];
    augmentedChild[@"rect"] = rectDict;
    augmentedChild[@"hit-point"] = @{@"x": @(center_x), @"y": @(center_y)};
    if (!(augmentedChild[@"type"])) {
      augmentedChild[@"type"] = @"dom";
    }

    if (!CGPointEqualToPoint(CGPointZero, boundsCenterInScrollView) &&
        [webView.scrollView pointInside:boundsCenterInScrollView withEvent:nil]) {
      [augmentedChild setValue:@(1) forKeyPath:@"visible"];

      UIWindow *windowForView = [LPTouchUtils windowForView:webView];
      CGPoint windowBounds = [windowForView convertPoint:boundsCenterInScrollView
                                                fromView:webView.scrollView];
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

    [LPWebQuery dictionaryByAugmentingDOMElement:domChild
                                         webView:webView
                          accumulateInDictionary:augmentedChild];
    [children addObject:augmentedChild];
  }
  accumulator[@"children"] = children;
  return accumulator;
}

+ (CGPoint) pointByAdjustingOffsetForScrollPositionOfWebView:(UIView<LPWebViewProtocol> *) webView {
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

+ (CGRect) translateRect:(CGRect)sourceRect inView:(UIView *) view {
  UIWindow *window = [LPTouchUtils windowForView:view];
  CGRect bounds = [window convertRect:view.bounds fromView:view];
  CGRect rect = CGRectMake(bounds.origin.x + sourceRect.origin.x,
          bounds.origin.y + sourceRect.origin.y,
          sourceRect.size.width,
          sourceRect.size.height);

  UIWindow *frontWindow = [[UIApplication sharedApplication] keyWindow];
  rect = [window convertRect:rect toCoordinateSpace:frontWindow];
  return [LPTouchUtils rectByApplyingLetterBoxAndSampleFactorToRect:rect];
}

+ (CGPoint) centerByApplyingLetterBoxAndSampleFactorToPoint:(CGPoint) point {
  LPLogDebug(@"Applying letter box and sample factors to point: %@",
          NSStringFromCGPoint(point));

  CGFloat x, y;

  LPDevice *device = [LPDevice sharedDevice];

  if ([device isIPad]) {
    LPLogDebug(@"Device is an iPad or iPad Pro; returning the original point");
    return point;
  }

  LPLogDebug(@"Device is an iPhone");
  UIInterfaceOrientation orientation;
  orientation = [[UIApplication sharedApplication] statusBarOrientation];

  if ([device isIPhoneXLetterBox] &&
          UIInterfaceOrientationIsLandscape(orientation)) {
    // iPhone 10 Letter Box in portrait just requires an offset on the y
    // iPhone 10 Letter Box in landscape requires an x and y offset _and_ a scale
    LPLogError(@"Detected that app is being displayed in letter box on iPhone 10");
    LPLogError(@"Cannot translate point without access to the containing rect");
    LPLogError(@"Returning the original point: %@", NSStringFromCGPoint(point));
    return point;
  }

  CGFloat xOffset = 0.0;
  CGFloat yOffset = 0.0;

  if ([device isIPhoneXLetterBox]) {
    LPLogDebug(@"Device is an iPhone 10 in letter box");
    xOffset = [LPTouchUtils xOffsetForIPhone10LetterBox:orientation];
    yOffset = [LPTouchUtils yOffsetForIPhone10LetterBox:orientation];
  } else if ([device isLetterBox]) {
    LPLogDebug(@"Device is an iPhone 4 inch in letter box");
    xOffset = [LPTouchUtils xOffsetFor4inchLetterBox:orientation];
    yOffset = [LPTouchUtils yOffsetFor4inchLetterBox:orientation];
  } else {
    LPLogDebug(@"Device is an iPhone");
  }

  CGFloat sampleFactor = [device sampleFactor];

  x = (point.x + xOffset) * sampleFactor;
  y = (point.y + yOffset) * sampleFactor;

  CGPoint translated = CGPointMake(x, y);
  LPLogDebug(@"  original: %@", NSStringFromCGPoint(point));
  LPLogDebug(@"translated: %@", NSStringFromCGPoint(translated));

  return translated;
}

+ (CGSize) sizeForIPadPro:(LPDevice *)device
              orientation:(UIInterfaceOrientation)orientation {
  CGSize size;

  if ([device isIPadPro9point7inch]) {
    size = CGSizeMake(768, 1024);
  } else if ([device isIPadPro10point5inch]) {
    size = CGSizeMake(834, 1112);
  } else if ([device isIPadPro12point9inch]) {
    size = CGSizeMake(1024, 1361);
  } else {
    LPLogError(@"Device has an unknown iPad Pro form factor: %@", device);

    // Will only be correct _if_ the app is being displayed natively.
    // Will not be correct if app is scaled, sampled, or zoomed.
    // Will not be correct if (web) app is being displayed in a 768x1024 rect.
    // The take-away message is that we need to keep track of new iPad Pro
    // form factors.
    NSDictionary *dimensions = [device screenDimensions];
    size = CGSizeMake([dimensions[@"bounds_portrait_width"] integerValue],
            [dimensions[@"bounds_portrait_height"] integerValue]);
    LPLogError(@"Returning %@ as size", NSStringFromCGSize(size));
    return size;
  }

  LPLogDebug(@"Native portrait resolution: %@", NSStringFromCGSize(size));

  if (UIInterfaceOrientationIsLandscape(orientation)) {
    size = CGSizeMake(size.height, size.width);
    LPLogDebug(@"Interface orientation is landscape; rotating to %@",
            NSStringFromCGSize(size));
  }
  return size;
}

+ (CGPoint) centerByApplyingIPadProScaleToPoint:(CGPoint) point {
  LPLogDebug(@"Apply iPad Pro scaling to point: %@", NSStringFromCGPoint(point));

  LPDevice *device = [LPDevice sharedDevice];
  if ([device isIPhone]) {
    LPLogDebug(@"Device is has an iPhone form factor; returning the original point");
    return point;
  }

  if (![device isIPadPro]) {
    LPLogDebug(@"Device is not an iPad Pro form factor; returning the original point");
    return point;
  }

  UIInterfaceOrientation orientation;
  orientation = [[UIApplication sharedApplication] statusBarOrientation];

  CGSize nativeResolution = [LPWebQuery sizeForIPadPro:device
                                           orientation:orientation];

  CGSize frameSize = [[UIScreen mainScreen] bounds].size;
  if (UIInterfaceOrientationIsLandscape(orientation)) {
    frameSize = CGSizeMake(frameSize.height, frameSize.width);
  }

  LPLogDebug(@"Main screen bounds has size %@",
          NSStringFromCGSize(frameSize));

  CGFloat xScale = nativeResolution.width / frameSize.width;
  CGFloat yScale = nativeResolution.height / frameSize.height;

  LPLogDebug(@"Will scale x by %@", @(xScale));
  LPLogDebug(@"Will scale y by %@", @(yScale));

  CGPoint translated = CGPointMake(xScale * point.x,
                                   yScale * point.y);

  LPLogDebug(@"Translated point to %@", NSStringFromCGPoint(translated));
  return translated;
}

+ (CGPoint)centerByApplyingTransformationsToPoint:(CGPoint)point {
  CGPoint transformed;
  transformed = [LPWebQuery centerByApplyingLetterBoxAndSampleFactorToPoint:point];
  return [LPWebQuery centerByApplyingIPadProScaleToPoint:transformed];
}

@end
