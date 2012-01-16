//
//  TextOperation.m
//  FoodFinder
//
//  Created by Karl Krukow on 11/09/11.
//  Copyright (c) 2011 LessPainful. All rights reserved.
//

#import "LPSetTextOperation.h"

@implementation LPSetTextOperation
- (NSString *) description {
	return [NSString stringWithFormat:@"Text: %@",_arguments];
}

- (id) performWithTarget:(UIView*)_view error:(NSError **)error {
    if ([_view respondsToSelector:@selector(setText:)]) {
        NSString *txt = [_arguments objectAtIndex:0];        
        [_view performSelector:@selector(setText:) withObject:txt];
        return _view;
    }
	return nil;
}

@end
