//
//  LPTouchUtils.m
//  Created by Karl Krukow on 14/08/11.
//  Copyright 2011 LessPainful. All rights reserved.
//
#import <sys/utsname.h>

#define LPiPHONE4INCHOFFSET 44

#import "LPTouchUtils.h"


@implementation LPTouchUtils

+ (BOOL) is4InchDevice {
  UIDevice *device = [UIDevice currentDevice];
  struct utsname systemInfo;
  uname(&systemInfo);

  NSString *system = [NSString stringWithCString:systemInfo.machine
                                        encoding:NSUTF8StringEncoding];
  NSDictionary *env = [[NSProcessInfo processInfo] environment];

  BOOL iphone5Like = NO;
  if ([@"iPhone Simulator" isEqualToString:[device model]]) {

    NSPredicate *inch5PhonePred = [NSPredicate predicateWithFormat:@"IPHONE_SIMULATOR_VERSIONS LIKE '*iPhone*Retina*4-inch*'"];
    iphone5Like = [inch5PhonePred evaluateWithObject:env];
  } else if ([[device model] hasPrefix:@"iPhone"]) {
    iphone5Like = [system hasPrefix:@"iPhone5"] || [system hasPrefix:@"iPhone6"];
  } else if ([[device model] hasPrefix:@"iPod"]) {
    iphone5Like = [system hasPrefix:@"iPod5"];
  }

  return iphone5Like;
}


+ (CGPoint) translateToScreenCoords:(CGPoint) point {
  UIScreen *s = [UIScreen mainScreen];

  UIScreenMode *sm = [s currentMode];
  CGRect b = [s bounds];
  CGSize size = sm.size;
  UIDeviceOrientation o = [[UIDevice currentDevice] orientation];

  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
    if ([UIScreen mainScreen].scale == 2.0f) {
      CGSize result = [[UIScreen mainScreen] bounds].size;
      CGFloat scale = [UIScreen mainScreen].scale;
      result = CGSizeMake(result.width * scale, result.height * scale);

      if (result.height == 960 && [LPTouchUtils is4InchDevice]) {//detect Letterbox
        return CGPointMake(point.x, point.y + LPiPHONE4INCHOFFSET);
      }

      if (result.height == 1136) {
        //NSLog(@"iPhone 5 Resolution");
        //iPhone 5 full
        return point;
      }
    }
  }


  CGRect small_vert = CGRectMake(0, 0, 320, 480);
  CGRect small_hori = CGRectMake(0, 0, 480, 320);
  CGSize large_size_vert = CGSizeMake(768, 1024);
  CGSize large_size_hori = CGSizeMake(1024, 768);
  CGSize retina_ipad_vert = CGSizeMake(1536, 2048);
  CGSize retina_ipad_hori = CGSizeMake(2048, 1536);


  if ((CGRectEqualToRect(small_vert, b) || CGRectEqualToRect(small_hori,
          b)) && (CGSizeEqualToSize(large_size_hori, size) || CGSizeEqualToSize(
          large_size_vert, size) || CGSizeEqualToSize(retina_ipad_hori,
          size) || CGSizeEqualToSize(retina_ipad_vert, size))) {

    CGSize orientation_size = UIDeviceOrientationIsPortrait(o) || UIDeviceOrientationFaceUp == o || UIDeviceOrientationUnknown == o ? large_size_vert : large_size_hori;
    float x_offset = orientation_size.width / 2.0f - b.size.width / 2.0f;
    float y_offset = orientation_size.height / 2.0f - b.size.height / 2.0f;
    return CGPointMake(x_offset + point.x, y_offset + point.y);
  } else {
    return point;
  }
}


+ (NSArray *) applicationWindows {
  // iOS flatdacted apparently doesn't list the "real" window containing alerts in the windows list, but stores it
  // instead in the -keyWindow property. To fix that, check if the array of windows contains the key window, and
  // explicitly add it if needed.
  //
  NSMutableArray *allWindows = [[[[UIApplication sharedApplication] windows]
          mutableCopy] autorelease];
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


+ (NSInteger) indexOfView:(UIView *) viewToFind asSubViewInView:(UIView *) viewToSearch {
  //Assume viewToFind != viewToSearch
  if (viewToFind == nil || viewToSearch == nil) {return -1;}
  NSArray *subViews = [viewToSearch subviews];
  for (NSInteger i = 0; i < [subViews count]; i++) {
    UIView *subView = [subViews objectAtIndex:i];
    if ([self canFindView:viewToFind asSubViewInView:subView]) {
      return i;
    }
  }
  return -1;
}


+ (BOOL) canFindView:(UIView *) viewToFind asSubViewInView:(UIView *) viewToSearch {
  if (viewToFind == viewToSearch) {return YES;}
  if (viewToFind == nil || viewToSearch == nil) {return NO;}
  NSInteger index = [self indexOfView:viewToFind asSubViewInView:viewToSearch];
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


+ (UIView *) findCommonAncestorForView:(UIView *) viewToCheck andView:(UIView *) otherView firstIndex:(NSInteger *) firstIndexPtr secondIndex:(NSInteger *) secondIndexPtr {
  UIView *parent = [otherView superview];
  NSInteger parentIndex = [[parent subviews] indexOfObject:otherView];
  NSInteger viewToCheckIndex = [self indexOfView:viewToCheck
                                 asSubViewInView:parent];
  while (parent && (viewToCheckIndex == -1)) {
    UIView *nextParent = [parent superview];
    parentIndex = [[nextParent subviews] indexOfObject:parent];
    parent = nextParent;
    viewToCheckIndex = [self indexOfView:viewToCheck asSubViewInView:parent];
  }
  if (viewToCheckIndex && parent) {
    *firstIndexPtr = viewToCheckIndex;
    *secondIndexPtr = parentIndex;
    return parent;
  }
  return nil;
}


+ (BOOL) isView:(UIView *) viewToCheck zIndexAboveView:(UIView *) otherView {
  NSInteger firstIndex = -1;
  NSInteger secondIndex = -1;

  UIView *commonAncestor = [self findCommonAncestorForView:viewToCheck
                                                   andView:otherView
                                                firstIndex:&firstIndex
                                               secondIndex:&secondIndex];
  if (!commonAncestor || firstIndex == -1 || secondIndex == -1) {return NO;}
  return firstIndex > secondIndex;
}


+ (BOOL) isViewVisible:(UIView *) view {
  if (![view isKindOfClass:[UIView class]] || [self isViewOrParentsHidden:view]) {return NO;}
  UIWindow *windowForView = [self windowForView:view];
  if (!windowForView) {return YES;/* what can I do?*/}

  CGPoint center = [self centerOfView:view inWindow:windowForView];

  UIView *hitView = [windowForView hitTest:center withEvent:nil];
  if ([self canFindView:view asSubViewInView:hitView]) {
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
    UIWindow *viewWin = [self windowForView:view];
    UIWindow *hitWin = [self windowForView:hitView];
    if (viewWin == hitWin)//common window
    {

      CGRect hitViewBounds = [viewWin convertRect:hitView.bounds
                                         fromView:hitView];
      CGRect viewBounds = [viewWin convertRect:view.bounds fromView:view];

      if (CGRectContainsRect(hitViewBounds, viewBounds) && [self isView:hitView
                                                        zIndexAboveView:view]) {
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


+ (CGPoint) centerOfFrame:(CGRect) frame shouldTranslate:(BOOL) shouldTranslate {
  CGPoint translated = shouldTranslate ? [self translateToScreenCoords:frame.origin] : frame.origin;
  return CGPointMake(translated.x + 0.5 * frame.size.width,
          translated.y + 0.5 * frame.size.height);
}


+ (CGPoint) centerOfFrame:(CGRect) frame {
  return [self centerOfFrame:frame shouldTranslate:YES];
}


+ (CGPoint) centerOfView:(UIView *) view shouldTranslate:(BOOL) shouldTranslate {

  UIWindow *delegateWindow = [LPTouchUtils appDelegateWindow];
  UIWindow *viewWindow = [self windowForView:view];
  CGRect bounds = [viewWindow convertRect:view.bounds fromView:view];
  bounds = [delegateWindow convertRect:bounds fromWindow:viewWindow];
  return [self centerOfFrame:bounds shouldTranslate:shouldTranslate];
}


+ (CGPoint) centerOfView:(UIView *) view inWindow:(UIWindow *) windowForView {
  CGRect bounds = [windowForView convertRect:view.bounds fromView:view];
  return [self centerOfFrame:bounds shouldTranslate:NO];
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
      delegateWindow = [allWindows objectAtIndex:0];
    }
  } else {
    delegateWindow = appDelegate.window;
  }
  return delegateWindow;
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
//

+ (void) flashView:(id) viewOrDom forDuration:(NSUInteger) duration {
  if ([viewOrDom isKindOfClass:[UIView class]]) {
    UIView *view = (UIView *) viewOrDom;

    UIColor *originalBackgroundColor = [view.backgroundColor retain];
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
    [originalBackgroundColor release];
  } else {
    //TODO implement flash in JavaScript
  }
}

@end
