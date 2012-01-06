//
//  UIScriptASTFirst.m
//  MobileBank
//
//  Created by Karl Krukow on 16/08/11.
//  Copyright (c) 2011 Trifork. All rights reserved.
//

#import "UIScriptASTFirst.h"

@implementation UIScriptASTFirst
- (NSString*) description {
    return @"first";
}

- (NSMutableArray*) evalWith:(NSArray*) views direction:(UIScriptASTDirectionType) dir {
    if ([views count] > 0) {
        return [NSMutableArray arrayWithObject:[views objectAtIndex:0]];
    }
    return [NSMutableArray array];
}

@end
