//
//  UIScriptASTIndex.m
//  Created by Karl Krukow on 12/08/11.
//  Copyright 2011 LessPainful. All rights reserved.
//

#import "UIScriptASTIndex.h"

@implementation UIScriptASTIndex
@synthesize index = _index;


- (id) initWithIndex:(NSUInteger) index {
  self = [super init];
  if (self) {
    self.index = index;
  }

  return self;
}


- (NSMutableArray *) evalWith:(NSArray *) views direction:(UIScriptASTDirectionType) dir visibility:(UIScriptASTVisibilityType) visibility {

  if (_index >= [views count]) {return nil;}
  return [NSMutableArray arrayWithObject:[views objectAtIndex:self.index]];
}


- (NSString *) description {
  return [NSString stringWithFormat:@"index:%@", @(self.index)];
}

@end
