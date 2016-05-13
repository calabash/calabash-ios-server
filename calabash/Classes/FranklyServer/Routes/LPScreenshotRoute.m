#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

//
//  ScreenshotRoute.m
//  Created by Karl Krukow on 13/08/11.
//  Copyright 2011 LessPainful. All rights reserved.
//

#import "LPScreenshotRoute.h"
#import "LPHTTPDataResponse.h"
#import "LPTouchUtils.h"
#import "LPCocoaLumberjack.h"

@interface LPScreenshotRoute ()

- (NSData *) takeScreenshot;
- (NSData *) takeScreenshotUsingSnapshotAPI;
- (NSData *) takeScreenshotUsingRenderInContext;

@end

@implementation LPScreenshotRoute

- (BOOL) supportsMethod:(NSString *) method atPath:(NSString *) path {
  return [method isEqualToString:@"GET"];
}

- (NSObject <LPHTTPResponse> *) httpResponseForMethod:(NSString *) method URI:(NSString *) path {
  LPHTTPDataResponse *drsp = [[LPHTTPDataResponse alloc]
                              initWithData:[self takeScreenshot]];
  return drsp;
}

- (NSData *) takeScreenshot {
  NSData *imageData = [NSData data];

  @try {
    imageData = [self takeScreenshotUsingSnapshotAPI];
  } @catch (NSException *exception) {
    LPLogError(@"Caught an exception using the snapshot API");
    LPLogError(@"%@", exception);
    LPLogError(@"Will try taking a screenshot using render in context");
    imageData = [self takeScreenshotUsingRenderInContext];
  }

  return imageData;
}

// Take a screenshot using the the snapshot API.  This is preferred because it
// captures OpenGL and UIKit views.  Unfortunately, it can cause app crashes
// if called during an animation.
- (NSData *) takeScreenshotUsingSnapshotAPI {

  // Available on iOS >= 7
  SEL selector = @selector(drawViewHierarchyInRect:afterScreenUpdates:);
  UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
  BOOL drawViewHierarchy = [view respondsToSelector:selector];

  CGRect bounds = [[UIScreen mainScreen] bounds];
  CGSize imageSize = bounds.size;
  UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0);

  CGContextRef context = UIGraphicsGetCurrentContext();

  // Iterate over every window from back to front
  for (UIWindow *window in [LPTouchUtils applicationWindows]) {
    if (![window respondsToSelector:@selector(screen)] || [window screen] == [UIScreen mainScreen]) {
      // -renderInContext: renders in the coordinate space of the layer,
      // so we must first apply the layer's geometry to the graphics context
      CGContextSaveGState(context);
      // Center the context around the window's anchor point
      CGContextTranslateCTM(context, [window center].x, [window center].y);
      // Apply the window's transform about the anchor point
      CGContextConcatCTM(context, [window transform]);
      // Offset by the portion of the bounds left of and above the anchor point
      CGContextTranslateCTM(context,
                            -[window bounds].size.width * [[window layer] anchorPoint].x,
                            -[window bounds].size.height * [[window layer] anchorPoint].y);

      if (drawViewHierarchy) {
        [window drawViewHierarchyInRect:bounds afterScreenUpdates:YES];
      } else {
        // Render the layer hierarchy to the current context
        [[window layer] renderInContext:context];
      }

      // Restore the context
      CGContextRestoreGState(context);
    }
  }

  // Retrieve the screenshot image
  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();

  UIGraphicsEndImageContext();

  return UIImagePNGRepresentation(image);
}

// Takes a screenshot using renderInContext.  This method is not preferred
// because it does not capture OpenGL views.  Its advantage is that it does not
// throw exceptions.
- (NSData *) takeScreenshotUsingRenderInContext {

  CGSize imageSize = [[UIScreen mainScreen] bounds].size;
  UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0);

  CGContextRef context = UIGraphicsGetCurrentContext();

  // Iterate over every window from back to front
  for (UIWindow *window in [LPTouchUtils applicationWindows]) {
    if (![window respondsToSelector:@selector(screen)] || [window screen] == [UIScreen mainScreen]) {
      // -renderInContext: renders in the coordinate space of the layer,
      // so we must first apply the layer's geometry to the graphics context
      CGContextSaveGState(context);
      // Center the context around the window's anchor point
      CGContextTranslateCTM(context, [window center].x, [window center].y);
      // Apply the window's transform about the anchor point
      CGContextConcatCTM(context, [window transform]);
      // Offset by the portion of the bounds left of and above the anchor point
      CGContextTranslateCTM(context,
                            -[window bounds].size.width * [[window layer] anchorPoint].x,
                            -[window bounds].size.height * [[window layer] anchorPoint].y);

      // Render the layer hierarchy to the current context
      [[window layer] renderInContext:context];

      // Restore the context
      CGContextRestoreGState(context);
    }
  }

  // Retrieve the screenshot image
  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();

  UIGraphicsEndImageContext();

  return UIImagePNGRepresentation(image);
}

@end
