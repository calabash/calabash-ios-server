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
    //try and detect "compatabilitity mode"
    CGRect small_vert = CGRectMake(0, 0, 320, 480);
    CGRect small_hori = CGRectMake(0, 0, 480, 320);
    CGSize large_size_vert = CGSizeMake(768.0, 1024);
    CGSize large_size_hori = CGSizeMake(1024, 768.0);
    if ((CGRectEqualToRect(small_vert, b) || CGRectEqualToRect(small_hori, b))  && (CGSizeEqualToSize(large_size_hori, size) || CGSizeEqualToSize(large_size_vert, size))) {
        UIDeviceOrientation o = [[UIDevice currentDevice] orientation];
        CGSize orientation_size =  UIDeviceOrientationIsPortrait(o) || UIDeviceOrientationFaceUp == o || UIDeviceOrientationUnknown == o ? large_size_vert : large_size_hori;
        float x_offset = orientation_size.width/2.0f - b.size.width/2.0f;
        float y_offset = orientation_size.height/2.0f - b.size.height/2.0f;
        return CGPointMake(x_offset+point.x, y_offset+point.y);
    } else {
        return point;
    }
}

+(CGPoint) centerOfView:(UIView *) view {
    CGRect frameInWindow;
    if ([view isKindOfClass:[UIWindow class]])
    {
        frameInWindow = view.frame;
    }
    else
    {
        
        UIWindow *window = nil;
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
        
        
        frameInWindow = [window convertRect:view.frame fromView:view.superview];
        //frameInWindow = [view.window convertRect:view.frame fromView:view.superview];
    }
    CGPoint translated = [self translateToScreenCoords:frameInWindow.origin];
        

    return CGPointMake(translated.x + 0.5 * frameInWindow.size.width,
                       translated.y + 0.5 * frameInWindow.size.height);
}
@end
