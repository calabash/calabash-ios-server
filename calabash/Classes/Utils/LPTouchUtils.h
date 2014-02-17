//
//  LPTouchUtils.h
//  Created by Karl Krukow on 14/08/11.
//  Copyright 2011 LessPainful. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LPTouchUtils : NSObject

+ (CGPoint) translateToScreenCoords:(CGPoint) point;

+ (CGPoint) centerOfView:(UIView *) view;

+ (CGPoint) centerOfFrame:(CGRect) frame;

+ (CGPoint) centerOfFrame:(CGRect) frame shouldTranslate:(BOOL) shouldTranslate;

+ (CGPoint) centerOfView:(id) view withSuperView:(UIView *) superView inWindow:(id) window;

+ (BOOL) is4InchDevice;

+ (NSArray *) applicationWindows;

+ (UIWindow *) windowForView:(UIView *) view;

+ (UIWindow *) appDelegateWindow;

+ (BOOL) isViewVisible:(UIView *) view;

+ (void) flashView:(id) viewOrDom forDuration:(NSUInteger) duration;

@end
