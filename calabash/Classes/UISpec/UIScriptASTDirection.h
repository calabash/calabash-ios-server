//
//  UIScriptASTDirectionParent.h
//  Created by Karl Krukow on 12/08/11.
//  Copyright 2011 LessPainful. All rights reserved.
//

#import "UIScriptAST.h"

@interface UIScriptASTDirection : UIScriptAST {
  UIScriptASTDirectionType _directionType;
}

@property(nonatomic, assign) UIScriptASTDirectionType directionType;

- (id) initWithDirection:(UIScriptASTDirectionType) direction;


@end
