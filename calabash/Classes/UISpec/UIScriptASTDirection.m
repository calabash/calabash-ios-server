//
//  UIScriptASTDirectionParent.m
//  Created by Karl Krukow on 12/08/11.
//  Copyright 2011 LessPainful. All rights reserved.
//

#import "UIScriptASTDirection.h"

@implementation UIScriptASTDirection
@synthesize directionType = _directionType;

- (id) initWithDirection:(UIScriptASTDirectionType) direction {
  self = [super init];
  if (self) {
    self.directionType = direction;
  }

  return self;
}


- (NSString *) description {
  switch (self.directionType) {
    case UIScriptASTDirectionTypeDescendant:return @"descendant";
    case UIScriptASTDirectionTypeParent:return @"parent";
    case UIScriptASTDirectionTypeChild:return @"child";
    case UIScriptASTDirectionTypeSibling:return @"sibling";
    default:return @"<UNKNOWNDIRECTION";
  }
}

@end
