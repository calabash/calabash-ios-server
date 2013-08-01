//
//  UIScriptASTALL.m
//  Created by Karl Krukow on 12/08/11.
//  Copyright 2011 Xamarin. All rights reserved.
//

#import "UIScriptASTALL.h"

@implementation UIScriptASTALL

- (NSString*) description {
    return @"all";
}
- (NSMutableArray*) evalWith:(NSArray*) views direction:(UIScriptASTDirectionType) dir {
    return [[views mutableCopy]autorelease];
}

@end
