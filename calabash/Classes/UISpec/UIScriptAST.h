//
//  UIScriptAST.h
//  Created by Karl Krukow on 12/08/11.
//  Copyright 2011 LessPainful. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
  UIScriptASTDirectionTypeDescendant, UIScriptASTDirectionTypeParent, UIScriptASTDirectionTypeChild, UIScriptASTDirectionTypeSibling,
      UIScriptASTDirectionTypeAcc, UIScriptASTDirectionTypeAccParent
} UIScriptASTDirectionType;

typedef enum {
  UIScriptASTVisibilityTypeVisible, UIScriptASTVisibilityTypeAll
} UIScriptASTVisibilityType;

@interface UIScriptAST : NSObject

- (NSMutableArray *) evalWith:(NSArray *) views direction:(UIScriptASTDirectionType) dir visibility:(UIScriptASTVisibilityType) visibility;

@end
