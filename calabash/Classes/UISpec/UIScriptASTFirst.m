//
//  UIScriptASTFirst.m
//  Created by Karl Krukow on 16/08/11.
//  Copyright (c) 2011 LessPainful. All rights reserved.
//

#import "UIScriptASTFirst.h"

@implementation UIScriptASTFirst
- (NSString *) description {
  return @"first";
}


- (NSMutableArray *) evalWith:(NSArray *) views direction:(UIScriptASTDirectionType) dir visibility:(UIScriptASTVisibilityType) visibility {

  if ([views count] > 0) {
    return [NSMutableArray arrayWithObject:[views objectAtIndex:0]];
  }
  return [NSMutableArray array];
}

@end
