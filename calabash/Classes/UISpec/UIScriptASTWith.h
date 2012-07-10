//
//  UIScriptASTWith.h
//  Created by Karl Krukow on 12/08/11.
//  Copyright 2011 LessPainful. All rights reserved.
//

#import "UIScriptAST.h"
typedef enum {
    UIScriptLiteralTypeUnknown,
    UIScriptLiteralTypeIndexPath,
    UIScriptLiteralTypeString,
    UIScriptLiteralTypeInteger,
    UIScriptLiteralTypeBool
} UIScriptLiteralType;


@interface UIScriptASTWith : UIScriptAST {

      
}
@property (nonatomic, copy) NSString *selectorName;
@property (nonatomic, assign) NSInteger timeout;
@property (strong, nonatomic) NSObject *objectValue;
@property (nonatomic,assign) BOOL boolValue;
@property (nonatomic,assign) NSInteger integerValue;
@property (nonatomic,assign) NSInteger integerValue2;
@property (nonatomic,assign) UIScriptLiteralType valueType;
@property (nonatomic,assign) UIScriptLiteralType valueType2;
 

- (id)initWithSelectorName:(NSString *)selectorName;
@end
