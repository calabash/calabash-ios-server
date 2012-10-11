//
//  LPTouchUtils.m
//  Created by Karl Krukow on 14/08/11.
//  Copyright 2011 LessPainful. All rights reserved.
//

#import "LPTouchUtils.h"

@implementation LPTouchUtils

+(CGPoint) translateToScreenCoords:(CGPoint) point {
    UIScreen*  s = [UIScreen mainScreen];
    
    UIScreenMode* sm =[s currentMode];
    CGRect b = [s bounds];
    CGSize size = sm.size;
    UIDeviceOrientation o = [[UIDevice currentDevice] orientation];    
    //try and detect "compatabilitity mode"
    CGRect small_vert = CGRectMake(0, 0, 320, 480);
    CGRect small_hori = CGRectMake(0, 0, 480, 320);
    CGSize large_size_vert = CGSizeMake(768.0, 1024);
    CGSize large_size_hori = CGSizeMake(1024, 768.0);
    if ((CGRectEqualToRect(small_vert, b) || CGRectEqualToRect(small_hori, b))  && (CGSizeEqualToSize(large_size_hori, size) || CGSizeEqualToSize(large_size_vert, size))) {
       
        CGSize orientation_size =  UIDeviceOrientationIsPortrait(o) || UIDeviceOrientationFaceUp == o || UIDeviceOrientationUnknown == o ? large_size_vert : large_size_hori;
        float x_offset = orientation_size.width/2.0f - b.size.width/2.0f;
        float y_offset = orientation_size.height/2.0f - b.size.height/2.0f;
        return CGPointMake(x_offset+point.x, y_offset+point.y);
    } else {
        return point;
    }
}
+(UIWindow*)windowForView:(UIView*)view
{
    id v = view;
    while (v && ![v isKindOfClass:[UIWindow class]])
    {
        v = [v superview];
    }
    return v;
}

+(BOOL)canFindView:(UIView *)viewToFind asSubViewInView:(UIView *)viewToSearch
{
    if (viewToFind == viewToSearch) { return YES; }
    if (viewToFind == nil || viewToSearch == nil) {return  NO; }
        
    for (UIView *subView  in [viewToSearch subviews])
    {
        if ([self canFindView:viewToFind asSubViewInView:subView])
        {
            return YES;
        }
    }
    return NO;
    
}

+(BOOL)isViewVisible:(UIView *)view
{
    if (![view isKindOfClass:[UIView class]] || [view isHidden]) {return NO;}
    CGPoint center = [self centerOfView:view shouldTranslate:NO];
    UIWindow *windowForView = [self windowForView:view];
    if (!windowForView) {return YES;/* what can I do?*/}
    NSLog(@"view %@ cent: %@",    [view accessibilityLabel], NSStringFromCGPoint(center));
    UIView *hitView = [windowForView hitTest:center withEvent:nil];
    NSLog(@"hit test -> %@",hitView);
    NSLog(@"window rect: %@",    NSStringFromCGRect([windowForView bounds]));
    if ([self canFindView: view asSubViewInView:hitView])
    {
        return YES;
    } 
    UIView *hitSuperView = hitView;
    
    while (hitSuperView && hitSuperView != view)
    {
        hitSuperView = [hitSuperView superview];
    }
    if (hitSuperView == view)
    {
        return YES;
    }
    
    if (![view isKindOfClass:[UIControl class]])
    {
        //there may be a case with a non-control (e.g., label)
        //on top of a control visually but not logically
        UIWindow *viewWin = [self windowForView:view];
        UIWindow *hitWin = [self windowForView:hitView];
        if (viewWin == hitWin)//common window
        {
            CGRect ctrlRect = [viewWin convertRect:hitView.frame fromView:hitView.superview];            
            return CGRectContainsPoint(ctrlRect, center);
            //
            
        }
    }
    return NO;
}

+(CGPoint)centerOfFrame:(CGRect)frame shouldTranslate:(BOOL)shouldTranslate
{
    CGPoint translated =  shouldTranslate ? [self translateToScreenCoords:frame.origin] : frame.origin;
    
    
    return CGPointMake(translated.x + 0.5 * frame.size.width,
                       translated.y + 0.5 * frame.size.height);
}


+(CGPoint)centerOfFrame:(CGRect)frame
{
    return [self centerOfFrame:frame shouldTranslate:YES];
}

+(CGPoint)centerOfView:(UIView *)view shouldTranslate:(BOOL)shouldTranslate
{
    CGRect frameInWindow;
    if ([view isKindOfClass:[UIWindow class]])
    {
        frameInWindow = view.frame;
    }
    else
    {
        
        UIWindow *window = nil;
        /*
        UIApplication *app = [UIApplication sharedApplication];
        if ([app.delegate respondsToSelector:@selector(window)])
        {
            window = [app.delegate window];
        }
        else 
        {
            for (UIWindow *w in [app windows])
            {
                if (CGAffineTransformIsIdentity(w.transform))
                {
                    window = w;
                    break;
                }
            }
        }
        */
        window = [self windowForView:view];
        
        if (window)
        {
            frameInWindow = [window convertRect:view.frame fromView:view.superview];            
        }
        else
        {
            frameInWindow = view.frame;//give up?
        }

        //frameInWindow = [view.window convertRect:view.frame fromView:view.superview];
    }    
    return [self centerOfFrame:frameInWindow shouldTranslate:shouldTranslate];
}
+(CGPoint) centerOfView:(UIView *) view 
{
    return [self centerOfView:view shouldTranslate:YES];
}
+(CGPoint) centerOfView:(id)view 
          withSuperView:(UIView *)superView
               inWindow:(id)window
{
        
        CGRect frameInWindow = [window convertRect:[view frame] fromView:superView];
    return [self centerOfFrame:frameInWindow shouldTranslate:YES];
}
@end
