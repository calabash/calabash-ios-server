//
//  UIScriptASTWith.h
//  Created by Karl Krukow on 12/08/11.
//  Copyright 2011 LessPainful. All rights reserved.
//

#import "UIScriptAST.h"
typedef enum {
    UIScriptLiteralTypeUnknown,
    UIScriptLiteralTypeString,
    UIScriptLiteralTypeInteger,
    UIScriptLiteralTypeBool
} UIScriptLiteralType;

@interface UIScriptASTWith : UIScriptAST {
    NSString *_selectorName;
    SEL _selector;
    NSObject* _objectValue;
    BOOL _boolValue;
    NSInteger _integerValue;
    
    UIScriptLiteralType _valueType;
    
}
@property (nonatomic, assign) NSString *selectorName;
@property (nonatomic,assign) SEL selector;
@property (nonatomic, assign) NSInteger timeout;
@property (nonatomic,retain) NSObject *objectValue;
@property (nonatomic,assign) BOOL boolValue;
@property (nonatomic,assign) NSInteger integerValue;
@property (nonatomic,assign) UIScriptLiteralType valueType;
 

- (id)initWithSelectorName:(NSString *)selectorName;
@end
