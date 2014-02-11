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
  NSPredicate *_predicate;
  SEL _selector;
}
@property(nonatomic, retain) NSPredicate *predicate;
@property(nonatomic, assign) SEL selector;

- (id) initWithPredicate:(NSPredicate *) pred selector:(SEL) sel;

@end
