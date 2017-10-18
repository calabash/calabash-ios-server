//
//  LPTouchUtils.h
//  Created by Karl Krukow on 14/08/11.
//  Copyright 2011 LessPainful. All rights reserved.
//

#import <UIKit/UIKit.h>

#define LPiPHONE4INCHOFFSET 44

@interface LPTouchUtils : NSObject

+ (CGPoint) translateToScreenCoords:(CGPoint) point sampleFactor:(CGFloat)sampleFactor;
+ (CGPoint) translateToScreenCoords:(CGPoint) point;

+ (CGFloat) xOffsetFor4inchLetterBox:(UIInterfaceOrientation) orientation;
+ (CGFloat) yOffsetFor4inchLetterBox:(UIInterfaceOrientation) orientation;
+ (CGFloat) xOffsetForIPhone10LetterBox:(UIInterfaceOrientation) orientation;
+ (CGFloat) yOffsetForIPhone10LetterBox:(UIInterfaceOrientation) orientation;
+ (CGRect) rectByApplyingLetterBoxAndSampleFactorToRect:(CGRect) rect;
+ (CGPoint) centerOfView:(UIView *) view;
+ (CGPoint) centerOfView:(UIView *) view shouldTranslate:(BOOL) shouldTranslate;
+ (CGRect)translateRect:(CGRect)rect inView:(UIView*) view;
+ (CGPoint) centerOfFrame:(CGRect) frame;
+ (CGPoint) centerOfView:(id) view withSuperView:(UIView *) superView inWindow:(id) window;
+ (BOOL) canFindView:(UIView *) viewToFind
     asSubViewInView:(UIView *) viewToSearch;
+ (CGPoint) centerOfFrame:(CGRect) frame
          shouldTranslate:(BOOL) shouldTranslate;
+ (NSArray *) applicationWindows;
+ (UIWindow *) windowForView:(UIView *) view;
+ (UIWindow *) appDelegateWindow;
+ (BOOL) isViewVisible:(UIView *) view;
+ (NSArray *) accessibilityChildrenFor:(id) view;
+ (void) flashView:(id) viewOrDom forDuration:(NSUInteger) duration;

@end
