//
//  ScreenshotRoute2.h
//  Created by Karl Krukow on 13/08/11.
//  Copyright 2011 LessPainful. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LPRoute.h"

// todo why does LPScreenshotRoute2 exist?
@interface LPScreenshotRoute2 : NSObject <LPRoute>

- (NSData *) takeScreenshot;

@end
