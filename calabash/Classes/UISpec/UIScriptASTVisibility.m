//
//  UIScriptASTVisibility.h
//  Created by Karl Krukow on 12/02/13.
//  Copyright 2013 LessPainful. All rights reserved.
//

#import "UIScriptASTVisibility.h"

@implementation UIScriptASTVisibility
@synthesize visibilityType = _visibilityType;


- (id) initWithVisibility:(UIScriptASTVisibilityType) visibility {
  self = [super init];
  if (self) {
    self.visibilityType = visibility;
  }
  return self;
}


- (NSString *) description {
  switch (self.visibilityType) {
    case UIScriptASTVisibilityTypeVisible:return @"visible";
    case UIScriptASTVisibilityTypeAll:return @"all";
    default:return @"<UNKNOWN_VISIBILITY>";
  }
}


@end
