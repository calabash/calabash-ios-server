//
//  UIScriptASTPredicate.h
//  LPSimpleExample
//
//  Created by Karl Krukow on 01/02/12.
//  Copyright (c) 2012 LessPainful. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UIScriptAST.h"

@interface UIScriptASTPredicate : UIScriptAST {
    NSPredicate *__unsafe_unretained _predicate;
    SEL _selector;
}
@property (unsafe_unretained, nonatomic) NSPredicate *predicate;
@property (nonatomic, assign) SEL selector;

-(id) initWithPredicate:(NSPredicate *)pred selector:(SEL) sel;

@end
