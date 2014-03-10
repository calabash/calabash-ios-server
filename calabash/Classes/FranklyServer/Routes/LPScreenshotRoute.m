//
//  ScreenshotRoute.m
//  Created by Karl Krukow on 13/08/11.
//  Copyright 2011 LessPainful. All rights reserved.
//

#import "LPScreenshotRoute.h"
#import "LPHTTPDataResponse.h"
#import "LPTouchUtils.h"


// UIGetScreenImage violates t
@implementation LPScreenshotRoute

- (BOOL) supportsMethod:(NSString *) method atPath:(NSString *) path {
  return [method isEqualToString:@"GET"];
}


- (NSObject <LPHTTPResponse> *) httpResponseForMethod:(NSString *) method URI:(NSString *) path {
  LPHTTPDataResponse *drsp = [[LPHTTPDataResponse alloc]
          initWithData:[self takeScreenshot]];
  return [drsp autorelease];
}


- (NSData *) takeScreenshot {
  // Create a graphics context with the target size
  // On iOS 4 and later, use UIGraphicsBeginImageContextWithOptions to take the scale into consideration
  // On iOS prior to 4, fall back to use UIGraphicsBeginImageContext

  // todo - this can be refactored becase we no longer support iOS 4
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunreachable-code"
  CGSize imageSize = [[UIScreen mainScreen] bounds].size;
  if (NULL != UIGraphicsBeginImageContextWithOptions) {
    UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0);
  } else {
    UIGraphicsBeginImageContext(imageSize);
  }
#pragma clang diagnostic pop

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


//    NSString* appID = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
//    static NSDateFormatter *fm = nil;
//    if (!fm) {
//        fm=[[NSDateFormatter alloc] init];
//        [fm setDateFormat:@"ddMM'-'HH':'mm':'SSSS"];
//    }
//    NSString* timestamp = [fm stringFromDate:[NSDate date]];
//    NSString* tempFile = [NSString stringWithFormat:@"%@screenshot_%@_%@.png",tempDir,appID,timestamp,nil];

  return UIImagePNGRepresentation(image);
}


@end
