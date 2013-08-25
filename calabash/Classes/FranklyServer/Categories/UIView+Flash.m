//
//  UIView+Flash.m
//  calabash
//
//  Created by Olivier Larivain on 3/6/13.
//  Copyright (c) 2013 LessPainful. All rights reserved.
//

#import "UIView+Flash.h"

@implementation UIView (Flash)
- (void) FEX_flash {
	UIColor *originalBackgroundColor = [self.backgroundColor retain];
    CGFloat orginalAlpha = self.alpha;
    for (NSUInteger i = 0; i < 5; i++) {
        self.backgroundColor = [UIColor yellowColor];
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, .05, false);
        
        self.alpha = 0;
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, .05, false);
        
        self.backgroundColor = [UIColor blueColor];
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, .05, false);
        
        self.alpha = 1;
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, .05, false);
    }
    self.alpha = orginalAlpha;
    self.backgroundColor = originalBackgroundColor;
    [originalBackgroundColor release];
}
@end
