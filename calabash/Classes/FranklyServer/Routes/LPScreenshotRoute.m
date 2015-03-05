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

@interface LPScreenshotRoute ()

- (NSData *) takeScreenshot;

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

  CGSize imageSize = [[UIScreen mainScreen] bounds].size;
  UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0);

  CGContextRef context = UIGraphicsGetCurrentContext();

  // Iterate over every window from back to front
  for (UIWindow *window in [LPTouchUtils applicationWindows]) {
    if (![window respondsToSelector:@selector(screen)] || [window screen] == [UIScreen mainScreen]) {
        if (![window respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)]) {
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
        } else {
          // Use latest API to capture custom views like openGL
          [window drawViewHierarchyInRect:window.bounds afterScreenUpdates:YES];
        }
    }
  }

  // Retrieve the screenshot image
  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();

  UIGraphicsEndImageContext();

  return UIImagePNGRepresentation(image);
}

@end
