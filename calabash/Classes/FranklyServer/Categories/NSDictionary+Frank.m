//
//  NSDictionary+Frank.m
//  Calabash
//
//  Created by Karl Krukow on 20/05/13.
//  Copyright (c) 2013 Xamarin. All rights reserved.
//


#import "LoadableCategory.h"
#import <PublicAutomation/UIAutomationBridge.h>

MAKE_CATEGORIES_LOADABLE(NSDictionary_Frank)

@implementation NSDictionary(Frank)

#pragma mark - Utils

- (CGPoint)FEX_centerPoint {
    CGPoint point;
    NSDictionary *center = [self objectForKey:@"center"];
    if (center)
    {
        CGPointMakeWithDictionaryRepresentation((CFDictionaryRef)center, &point);
    }
    else {
        CGPointMakeWithDictionaryRepresentation((CFDictionaryRef)self, &point);
    }
    
    return point;
    
}

#pragma mark - Touch

- (BOOL)FEX_touchPoint:(CGPoint)point {
    [UIAutomationBridge tapPoint:point];
    return YES;
}

- (BOOL)touch {
    return [self FEX_touchPoint:[self FEX_centerPoint]];
}

#pragma mark - Frank

- (void) FEX_flash{
	//TODO implement in JS
    NSLog(@"blinkblink");
}

- (BOOL) FEX_isVisible {
    return true;//TODO generalize: already filtered
}


@end