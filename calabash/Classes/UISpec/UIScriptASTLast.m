//
//  UIScriptASTLast.m
//  MobileBank
//
//  Created by Karl Krukow on 16/08/11.
//  Copyright (c) 2011 Trifork. All rights reserved.
//

#import "UIScriptASTLast.h"

@implementation UIScriptASTLast
- (NSString*) description {
    return @"last";
}

- (NSMutableArray*) evalWith:(NSArray*) views direction:(UIScriptASTDirectionType) dir {
    if ([views count] > 0) {
        return [NSMutableArray arrayWithObject:[views objectAtIndex:[views count]-1]];
    }
    return [NSMutableArray array];

}

@end
