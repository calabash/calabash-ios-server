#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

//  LPTouchUtils.m
//  Created by Karl Krukow on 14/08/11.
//  Copyright 2011 LessPainful. All rights reserved.
//
#import <math.h>
#import "LPTouchUtils.h"
#import "LPDevice.h"
#import "LPCocoaLumberjack.h"

@implementation LPTouchUtils

+ (CGPoint) translateToScreenCoords:(CGPoint) point sampleFactor:(CGFloat)sampleFactor{
  UIScreen *s = [UIScreen mainScreen];

  UIScreenMode *sm = [s currentMode];
  CGRect b = [s bounds];
  CGSize size = sm.size;
  UIDeviceOrientation o = [[UIDevice currentDevice] orientation];

  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
    if ([[LPDevice sharedDevice] isLetterBox]) {
      return CGPointMake(point.x * sampleFactor,
                         (point.y + LPiPHONE4INCHOFFSET)*sampleFactor);
    }
    return CGPointMake(point.x*sampleFactor,point.y*sampleFactor);
  }


  CGRect small_vert = CGRectMake(0, 0, 320, 480);
  CGRect small_hori = CGRectMake(0, 0, 480, 320);
  CGSize large_size_vert = CGSizeMake(768, 1024);
  CGSize large_size_hori = CGSizeMake(1024, 768);
  CGSize retina_ipad_vert = CGSizeMake(1536, 2048);
  CGSize retina_ipad_hori = CGSizeMake(2048, 1536);


  if ((CGRectEqualToRect(small_vert, b) || CGRectEqualToRect(small_hori,b)) && (CGSizeEqualToSize(large_size_hori, size) || CGSizeEqualToSize(large_size_vert, size) || CGSizeEqualToSize(retina_ipad_hori,size) ||
      CGSizeEqualToSize(retina_ipad_vert, size))) {

    CGSize orientation_size = UIDeviceOrientationIsPortrait(o) || UIDeviceOrientationFaceUp == o || UIDeviceOrientationUnknown == o ? large_size_vert : large_size_hori;
    float x_offset = orientation_size.width / 2.0f - b.size.width / 2.0f;
    float y_offset = orientation_size.height / 2.0f - b.size.height / 2.0f;
    return CGPointMake(x_offset + point.x, y_offset + point.y);
  } else {
    return point;
  }
}

+ (CGPoint) translateToScreenCoords:(CGPoint) point{
  CGFloat sampleFactor = [[LPDevice sharedDevice] sampleFactor];
  return [self translateToScreenCoords:point sampleFactor:sampleFactor];
}

+ (CGFloat) xOffsetFor4inchLetterBox:(UIInterfaceOrientation) orientation {
  if (UIInterfaceOrientationIsPortrait(orientation)) {
    return 0.0;
  } else {
    return 44.0;
  }
}

+ (CGFloat) yOffsetFor4inchLetterBox:(UIInterfaceOrientation) orientation {
  if (UIInterfaceOrientationIsPortrait(orientation)) {
    return 44.0;
  } else {
    return 0.0;
  }
}

+ (CGFloat) xOffsetForIPhone10LetterBox:(UIInterfaceOrientation) orientation {
  if (UIInterfaceOrientationIsPortrait(orientation)) {
    return 0.0;
  } else {
    return 94.0;
  }
}

+ (CGFloat) yOffsetForIPhone10LetterBox:(UIInterfaceOrientation) orientation {
  if (UIInterfaceOrientationIsPortrait(orientation)) {
    return 72.0;
  } else {
    return 4.0;
  }
}

+ (CGRect) rectByApplyingLetterBoxAndSampleFactorToRect:(CGRect) rect {
  CGFloat x, y, width, height;

  UIInterfaceOrientation orientation;
  LPDevice *device = [LPDevice sharedDevice];

  if ([device isIPhone10LetterBox]) {
    orientation = [[UIApplication sharedApplication] statusBarOrientation];

    CGFloat xOffset = [LPTouchUtils xOffsetForIPhone10LetterBox:orientation];
    CGFloat yOffset = [LPTouchUtils yOffsetForIPhone10LetterBox:orientation];

    CGFloat xScale = 1.0;
    CGFloat yScale = 1.0;

    if (UIInterfaceOrientationIsLandscape(orientation)) {
      xScale = 624.0/667.0;
      yScale = 350.0/375.0;
    }

    x = (rect.origin.x * xScale) + xOffset;
    y = (rect.origin.y * yScale) + yOffset;
    width = rect.size.width * xScale;
    height = rect.size.height * yScale;
  } else {
    CGFloat sampleFactor = [device sampleFactor];
    x = rect.origin.x * sampleFactor;
    y = rect.origin.y * sampleFactor;
    width = rect.size.width * sampleFactor;
    height = rect.size.height * sampleFactor;

    if ([device isLetterBox]) {
      orientation = [[UIApplication sharedApplication] statusBarOrientation];
      x = x + ([LPTouchUtils xOffsetFor4inchLetterBox:orientation] * sampleFactor);
      y = y + ([LPTouchUtils yOffsetFor4inchLetterBox:orientation] * sampleFactor);
    }
  }

  return CGRectMake(x, y, width, height);
}

+ (CGPoint) centerByApplyingLetterBoxAndSampleFactorToRect:(CGRect) rect {
  CGRect translated;
  translated = [LPTouchUtils rectByApplyingLetterBoxAndSampleFactorToRect:rect];
  return CGPointMake(CGRectGetMidX(translated), CGRectGetMidY(translated));
}

+ (NSArray *) applicationWindows {
  // iOS flatdacted apparently doesn't list the "real" window containing alerts
  // in the windows list, but stores it instead in the -keyWindow property. To
  // fix that, check if the array of windows contains the key window, and
  // explicitly add it if needed.
  NSArray *appWindows = [[UIApplication sharedApplication] windows];
  NSMutableArray *allWindows = [NSMutableArray arrayWithArray:appWindows];
  UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
  if (keyWindow && ![allWindows containsObject:keyWindow]) {
    [allWindows addObject:keyWindow];
  }

  return allWindows;
}

+ (UIWindow *) windowForView:(UIView *) view {
  id v = view;
  while (v && ![v isKindOfClass:[UIWindow class]]) {
    v = [v superview];
  }
  return v;
}

+ (NSInteger) indexOfView:(UIView *) viewToFind
          asSubViewInView:(UIView *) viewToSearch {
  //Assume viewToFind != viewToSearch
  if (viewToFind == nil || viewToSearch == nil) {return -1;}
  NSArray *subViews = [viewToSearch subviews];
  for (NSUInteger i = 0; i < [subViews count]; i++) {
    UIView *subView = subViews[i];
    if ([LPTouchUtils canFindView:viewToFind asSubViewInView:subView]) {
      return i;
    }
  }
  return -1;
}

+ (BOOL) canFindView:(UIView *) viewToFind
     asSubViewInView:(UIView *) viewToSearch {
  if (viewToFind == viewToSearch) {return YES;}
  if (viewToFind == nil || viewToSearch == nil) {return NO;}
  NSInteger index = [LPTouchUtils indexOfView:viewToFind
                              asSubViewInView:viewToSearch];
  return index != -1;
}

+ (BOOL) isViewOrParentsHidden:(UIView *) view {
  if ([view alpha] <= 0.05) {
    return YES;
  }
  UIView *superView = view;
  while (superView) {
    if ([superView isHidden]) {
      return YES;
    }
    superView = [superView superview];
  }
  return NO;
}

+ (UIView *) findCommonAncestorForView:(UIView *) viewToCheck
                               andView:(UIView *) otherView
                            firstIndex:(NSInteger *) firstIndexPtr
                           secondIndex:(NSInteger *) secondIndexPtr {
  UIView *parent = [otherView superview];
  NSInteger parentIndex = [[parent subviews] indexOfObject:otherView];
  NSInteger viewToCheckIndex = [LPTouchUtils indexOfView:viewToCheck
                                         asSubViewInView:parent];
  while (parent && (viewToCheckIndex == -1)) {
    UIView *nextParent = [parent superview];
    parentIndex = [[nextParent subviews] indexOfObject:parent];
    parent = nextParent;
    viewToCheckIndex = [LPTouchUtils indexOfView:viewToCheck
                                 asSubViewInView:parent];
  }
  if (viewToCheckIndex && parent) {
    *firstIndexPtr = viewToCheckIndex;
    *secondIndexPtr = parentIndex;
    return parent;
  }
  return nil;
}

+ (BOOL) isViewTransparent:(UIView*) view {
  return !view.backgroundColor || view.backgroundColor == [UIColor clearColor];
}
+ (BOOL) isView:(UIView *) viewToCheck zIndexAboveView:(UIView *) otherView {
  NSInteger firstIndex = -1;
  NSInteger secondIndex = -1;

  UIView *commonAncestor = [LPTouchUtils findCommonAncestorForView:viewToCheck
                                                           andView:otherView
                                                        firstIndex:&firstIndex
                                                       secondIndex:&secondIndex];
  if (!commonAncestor || firstIndex == -1 || secondIndex == -1) {return NO;}
  return firstIndex > secondIndex;
}


+ (BOOL) isViewVisible:(UIView *) view {
  if (![view isKindOfClass:[UIView class]] ||
      [LPTouchUtils isViewOrParentsHidden:view]) {
    return NO;
  }

  UIWindow *windowForView = [LPTouchUtils windowForView:view];
  if (!windowForView) {return YES;/* what can I do?*/}

  CGRect viewRect = [view frame];
  if (!(isfinite(viewRect.origin.x) && isfinite(viewRect.origin.y))) {
    // we don't consider this visible although there is a theoretical infinite
    // view which would be (visible)
    return NO;
  }

  CGPoint center = [LPTouchUtils centerOfView:view inWindow:windowForView];

  UIView *hitView = [windowForView hitTest:center withEvent:nil];
  if ([LPTouchUtils canFindView:view asSubViewInView:hitView]) {
    return YES;
  }
  UIView *hitSuperView = hitView;

  while (hitSuperView && hitSuperView != view) {
    hitSuperView = [hitSuperView superview];
  }
  if (hitSuperView == view) {
    return YES;
  }

  if (![view isKindOfClass:[UIControl class]]) {
    //there may be a case with a non-control (e.g., label)
    //on top of a control visually but not logically
    UIWindow *viewWin = [LPTouchUtils windowForView:view];
    UIWindow *hitWin = [LPTouchUtils windowForView:hitView];
    if (viewWin == hitWin)//common window
    {

      CGRect hitViewBounds = [viewWin convertRect:hitView.bounds
                                         fromView:hitView];
      CGRect viewBounds = [viewWin convertRect:view.bounds fromView:view];

      if (CGRectContainsRect(hitViewBounds, viewBounds) &&
          [LPTouchUtils isView:hitView zIndexAboveView:view] &&
          ![LPTouchUtils isViewTransparent:hitView]) {
        //In this case the hitView (which we're not asking about)
        //is completely overlapping the view and "above" it in the container.
        return NO;
      }


      CGRect ctrlRect = [viewWin convertRect:hitView.frame
                                    fromView:hitView.superview];
      return CGRectContainsPoint(ctrlRect, center);
    }
  }
  return NO;
}


+ (CGPoint) centerOfFrame:(CGRect) rect shouldTranslate:(BOOL) shouldTranslate {
  CGFloat sampleFactor = [[LPDevice sharedDevice] sampleFactor];
  CGPoint translated;
  if (shouldTranslate) {
    translated = [self translateToScreenCoords:rect.origin
                                  sampleFactor:sampleFactor];
  } else {
   translated = rect.origin;
  }
  
  return CGPointMake(translated.x + 0.5 * rect.size.width * sampleFactor,
                     translated.y + 0.5 * rect.size.height * sampleFactor);
  
}


+ (CGPoint) centerOfFrame:(CGRect) frame {
  return [self centerOfFrame:frame shouldTranslate:YES];
}


+ (CGPoint) centerOfView:(UIView *) view shouldTranslate:(BOOL) shouldTranslate {
  UIWindow *window = [self windowForView:view];
  CGRect rect = [window convertRect:view.bounds fromView:view];

  UIWindow *frontWindow = [[UIApplication sharedApplication] keyWindow];

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
  if ([frontWindow respondsToSelector:@selector(convertPoint:toCoordinateSpace:)]) {
    CGFloat sampleFactor = [[LPDevice sharedDevice] sampleFactor];
    rect = [window convertRect:rect toCoordinateSpace:frontWindow];
    CGFloat x = (rect.origin.x + 0.5 * rect.size.width) * sampleFactor;
    CGFloat y = (rect.origin.y + 0.5 * rect.size.height) * sampleFactor;
    
    if ([[LPDevice sharedDevice] isLetterBox]) {
      UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
      if (UIInterfaceOrientationIsPortrait(orientation)) {
        y += LPiPHONE4INCHOFFSET*sampleFactor;
      }
      else {
        x += LPiPHONE4INCHOFFSET*sampleFactor;
      }
    }
    return CGPointMake(x,y);
  } else {
    rect = [frontWindow convertRect:rect fromWindow:window];
    return [self centerOfFrame:rect shouldTranslate:shouldTranslate];
  }
#else
  rect = [frontWindow convertRect:rect fromWindow:window];
  return [self centerOfFrame:rect shouldTranslate:shouldTranslate];
#endif
}


+ (CGPoint) centerOfView:(UIView *) view inWindow:(UIWindow *) windowForView {
  CGRect bounds = [windowForView convertRect:view.bounds fromView:view];
  return [self centerOfFrame:bounds shouldTranslate:NO];
}

+ (CGRect)translateRect:(CGRect)sourceRect inView:(UIView*) view {
  UIWindow *window = [self windowForView:view];
  CGRect bounds = [window convertRect:view.bounds fromView:view];
  CGRect rect = CGRectMake(bounds.origin.x + sourceRect.origin.x,
                          bounds.origin.y + sourceRect.origin.y,
                          sourceRect.size.width,
                          sourceRect.size.height);


  UIWindow *frontWindow = [[UIApplication sharedApplication] keyWindow];

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
  if ([frontWindow respondsToSelector:@selector(convertPoint:toCoordinateSpace:)]) {
    CGFloat sampleFactor = [[LPDevice sharedDevice] sampleFactor];
    rect = [window convertRect:rect toCoordinateSpace:frontWindow];
    CGFloat x = rect.origin.x;
    CGFloat y = rect.origin.y;
    if ([[LPDevice sharedDevice] isLetterBox]) {
      UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
      if (UIInterfaceOrientationIsPortrait(orientation)) {
        y += LPiPHONE4INCHOFFSET*sampleFactor;
      }
      else {
        x += LPiPHONE4INCHOFFSET*sampleFactor;
      }
    }
    return CGRectMake(x * sampleFactor, y * sampleFactor,
                      rect.size.width * sampleFactor, rect.size.height * sampleFactor);
  } else {
    rect = [frontWindow convertRect:rect fromWindow:window];
    CGFloat sampleFactor = [[LPDevice sharedDevice] sampleFactor];
    CGPoint translated = [self translateToScreenCoords:rect.origin sampleFactor:sampleFactor];
    return CGRectMake(translated.x, translated.y, rect.size.width * sampleFactor, rect.size.height * sampleFactor);
  }
#else
  rect = [frontWindow convertRect:rect fromWindow:window];
  CGFloat sampleFactor = [[LPDevice sharedDevice] sampleFactor];
  CGPoint translated = [self translateToScreenCoords:rect.origin sampleFactor:sampleFactor];
  return CGRectMake(translated.x, translated.y, rect.size.width * sampleFactor, rect.size.height * sampleFactor);
#endif
}

+ (UIWindow *) appDelegateWindow {
  UIWindow *delegateWindow = nil;
  NSString *iosVersion = [UIDevice currentDevice].systemVersion;
  id <UIApplicationDelegate> appDelegate = [UIApplication sharedApplication].delegate;

  if ([[iosVersion substringToIndex:1]
          isEqualToString:@"4"] || !([appDelegate respondsToSelector:@selector(window)])) {

    if ([appDelegate respondsToSelector:@selector(window)]) {
      delegateWindow = [appDelegate window];
    }

    if (!delegateWindow) {
      NSArray *allWindows = [LPTouchUtils applicationWindows];
      delegateWindow = allWindows[0];
    }
  } else {
    delegateWindow = appDelegate.window;
  }
  return delegateWindow;
}

+ (NSArray *) accessibilityChildrenFor:(id) view {
  NSMutableArray *arr = [[NSMutableArray alloc] initWithCapacity:32];
  if ([view respondsToSelector:@selector(subviews)]) {
    [arr addObjectsFromArray:[view subviews]];
  }
  if ([view respondsToSelector:@selector(accessibilityElementCount)] &&
      [view respondsToSelector:@selector(accessibilityElementAtIndex:)]) {
    NSInteger count = [view accessibilityElementCount];
    if (count == 0 || count == NSNotFound) {
      return [NSArray arrayWithArray:arr];
    }
    for (NSInteger i=0;i<count;i++) {
      id accEl = [view accessibilityElementAtIndex:i];
      [arr addObject:accEl];
    }
  }
  return [NSArray arrayWithArray:arr];
}


+ (CGPoint) centerOfView:(UIView *) view {
  return [self centerOfView:view shouldTranslate:YES];
}


+ (CGPoint) centerOfView:(id) view withSuperView:(UIView *) superView inWindow:(id) window {

  CGRect frameInWindow = [window convertRect:[view frame] fromView:superView];
  return [self centerOfFrame:frameInWindow shouldTranslate:YES];
}

//  Created by Olivier Larivain on 3/6/13.
//  Copyright (c) 2013 LessPainful. All rights reserved.
//  Contribution by kra: https://github.com/calabash/calabash-ios-server/pull/15/files
//  Modified 22.04.2013 by Karl Krukow, Xamarin (karl.krukow@xamarin.com)
//      refactor from category method
+ (void) flashView:(id) viewOrDom forDuration:(NSUInteger) duration {
  if ([viewOrDom isKindOfClass:[UIView class]]) {
    UIView *view = (UIView *) viewOrDom;

    UIColor *originalBackgroundColor = view.backgroundColor;
    CGFloat originalAlpha = view.alpha;
    for (NSUInteger i = 0; i < 5; i++) {
      view.backgroundColor = [UIColor yellowColor];
      CFRunLoopRunInMode(kCFRunLoopDefaultMode, .05, false);
      view.alpha = 0;
      CFRunLoopRunInMode(kCFRunLoopDefaultMode, .05, false);

      view.backgroundColor = [UIColor blueColor];
      CFRunLoopRunInMode(kCFRunLoopDefaultMode, .05, false);

      view.alpha = 1;
      CFRunLoopRunInMode(kCFRunLoopDefaultMode, .05, false);
    }
    view.alpha = originalAlpha;
    view.backgroundColor = originalBackgroundColor;
  } else {
    //TODO implement flash in JavaScript
  }
}

@end
