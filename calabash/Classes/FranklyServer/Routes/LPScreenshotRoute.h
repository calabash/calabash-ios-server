//
//  ScreenshotRoute.h
//  Created by Karl Krukow on 13/08/11.
//  Copyright 2011 LessPainful. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LPRoute.h"

@interface LPScreenshotRoute : NSObject <LPRoute>

- (NSData *) takeScreenshot;

@end
