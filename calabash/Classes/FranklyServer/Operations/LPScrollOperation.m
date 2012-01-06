//
//  ScrollOperation.m
//  iLessPainfulServer
//
//  Created by Karl Krukow on 05/09/11.
//  Copyright (c) 2011 Trifork. All rights reserved.
//

#import "LPScrollOperation.h"

@implementation LPScrollOperation
- (NSString *) description {
	return [NSString stringWithFormat:@"Scroll: %@",_arguments];
}

- (id) performWithTarget:(UIView*)_view error:(NSError **)error {
    if ([_view isKindOfClass:[UIScrollView class]]) {
        UIScrollView* sv = (UIScrollView*) _view;
        NSString *dir = [_arguments objectAtIndex:0];
        CGSize size = sv.frame.size;
        CGPoint offset = sv.contentOffset;
        
        if ([@"up" isEqualToString:dir]) {
            [sv setContentOffset:CGPointMake(offset.x, offset.y - size.height/2.0) animated:YES];
        } else if ([@"down" isEqualToString:dir]) {
            [sv setContentOffset:CGPointMake(offset.x, offset.y + size.height/2.0) animated:YES];            
        } else if ([@"left" isEqualToString:dir]) {
            [sv setContentOffset:CGPointMake(offset.x - size.width/2.0, offset.y) animated:YES];
        } else if ([@"right" isEqualToString:dir]) {
            [sv setContentOffset:CGPointMake(offset.x+ size.width/2.0, offset.y) animated:YES];            
        }
        
        return _view;
        
    }
	return nil;
}

@end
