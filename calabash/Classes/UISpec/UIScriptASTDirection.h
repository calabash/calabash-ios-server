//
//  UIScriptASTDirectionParent.h
//  iLessPainfulServer
//
//  Created by Karl Krukow on 12/08/11.
//  Copyright 2011 Trifork. All rights reserved.
//

#import "UIScriptAST.h"

@interface UIScriptASTDirection : UIScriptAST {
    UIScriptASTDirectionType _directionType;
}

@property (nonatomic, assign) UIScriptASTDirectionType directionType;

- (id)initWithDirection:(UIScriptASTDirectionType) direction;


@end
