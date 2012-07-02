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
    NSString *__unsafe_unretained _selectorName;
    SEL _selector;
    NSObject* __unsafe_unretained _objectValue;
    BOOL _boolValue;
    NSInteger _integerValue;
    
    UIScriptLiteralType _valueType;
    
}
@property (nonatomic, unsafe_unretained) NSString *selectorName;
@property (nonatomic,assign) SEL selector;
@property (nonatomic, assign) NSInteger timeout;
@property (unsafe_unretained, nonatomic) NSObject *objectValue;
@property (unsafe_unretained, nonatomic) NSObject *objectValue2;
@property (nonatomic,assign) BOOL boolValue;
@property (nonatomic,assign) BOOL boolValue2;
@property (nonatomic,assign) NSInteger integerValue;
@property (nonatomic,assign) NSInteger integerValue2;
@property (nonatomic,assign) UIScriptLiteralType valueType;
@property (nonatomic,assign) UIScriptLiteralType valueType2;
 

- (id)initWithSelectorName:(NSString *)selectorName;
@end
