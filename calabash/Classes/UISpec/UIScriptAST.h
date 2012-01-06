//
//  UIScriptAST.h
//  iLessPainfulServer
//
//  Created by Karl Krukow on 12/08/11.
//  Copyright 2011 Trifork. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef enum {
    UIScriptASTDirectionTypeDescendant,
    UIScriptASTDirectionTypeParent,
    UIScriptASTDirectionTypeChild
} UIScriptASTDirectionType;

@interface UIScriptAST : NSObject

- (NSMutableArray*) evalWith:(NSArray*) views direction:(UIScriptASTDirectionType) dir;

@end
