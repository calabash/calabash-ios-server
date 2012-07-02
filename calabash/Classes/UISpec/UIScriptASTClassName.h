//
//  UIScriptASTClassName.h
//  Created by Karl Krukow on 12/08/11.
//  Copyright 2011 LessPainful. All rights reserved.
//

#import "UIScriptAST.h"

@interface UIScriptASTClassName : UIScriptAST {
    NSString *__unsafe_unretained _className;
    Class _class;
}

@property (unsafe_unretained, nonatomic, readonly) NSString *className;
- (id) initWithClassName:(NSString*) className;

@end
