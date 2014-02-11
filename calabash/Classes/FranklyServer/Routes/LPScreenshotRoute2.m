//
//  ScreenshotRoute2.m
//  Created by Karl Krukow on 13/08/11.
//  Copyright 2011 LessPainful. All rights reserved.
//

#import "LPScreenshotRoute2.h"
#import "LPHTTPDataResponse.h"


CGImageRef UIGetScreenImage(void);


// UIGetScreenImage violates t
@implementation LPScreenshotRoute2

- (BOOL) supportsMethod:(NSString *) method atPath:(NSString *) path {
  return [method isEqualToString:@"GET"];
}


- (NSObject <LPHTTPResponse> *) httpResponseForMethod:(NSString *) method URI:(NSString *) path {
  LPHTTPDataResponse *drsp = [[LPHTTPDataResponse alloc] initWithData:[self takeScreenshot]];
  return [drsp autorelease];
}


- (NSData *) takeScreenshot {

  CGImageRef screen = UIGetScreenImage();
  UIImage *image = [UIImage imageWithCGImage:screen];
  CGImageRelease(screen);
  return UIImagePNGRepresentation(image);
}


@end
