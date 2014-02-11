//
//  UIScriptASTVisibility.h
//  Created by Karl Krukow on 12/02/13.
//  Copyright 2013 LessPainful. All rights reserved.
//

#import "UIScriptAST.h"

@interface UIScriptASTVisibility : UIScriptAST {
  UIScriptASTVisibilityType _visibilityType;
}

@property(nonatomic, assign) UIScriptASTVisibilityType visibilityType;

- (id) initWithVisibility:(UIScriptASTVisibilityType) visibility;


@end
