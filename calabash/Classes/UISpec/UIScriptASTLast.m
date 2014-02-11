//
//  UIScriptASTLast.m
//  Created by Karl Krukow on 16/08/11.
//  Copyright (c) 2011 LessPainful. All rights reserved.
//

#import "UIScriptASTLast.h"

@implementation UIScriptASTLast
- (NSString *) description {
  return @"last";
}


- (NSMutableArray *) evalWith:(NSArray *) views direction:(UIScriptASTDirectionType) dir visibility:(UIScriptASTVisibilityType) visibility {

  if ([views count] > 0) {
    return [NSMutableArray arrayWithObject:[views objectAtIndex:[views count] - 1]];
  }
  return [NSMutableArray array];
}

@end
