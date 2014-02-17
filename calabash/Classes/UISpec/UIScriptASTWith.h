//
//  UIScriptASTWith.h
//  Created by Karl Krukow on 12/08/11.
//  Copyright 2011 LessPainful. All rights reserved.
//

#import "UIScriptAST.h"

typedef enum {
  UIScriptLiteralTypeUnknown, UIScriptLiteralTypeIndexPath, UIScriptLiteralTypeString, UIScriptLiteralTypeInteger, UIScriptLiteralTypeBool
} UIScriptLiteralType;

@interface UIScriptASTWith : UIScriptAST {
  NSString *_selectorName;
  SEL _selector;
  NSObject *_objectValue;
  BOOL _boolValue;
  NSInteger _integerValue;
  UIScriptLiteralType _valueType;
}

@property(nonatomic, retain) NSArray *selectorSpec;
@property(nonatomic, retain) NSString *selectorName;
@property(nonatomic, assign) SEL selector;
@property(nonatomic, assign) NSInteger timeout;
@property(nonatomic, retain) NSObject *objectValue;
@property(nonatomic, assign) BOOL boolValue;
@property(nonatomic, assign) BOOL boolValue2;
@property(nonatomic, assign) NSInteger integerValue;
@property(nonatomic, assign) NSInteger integerValue2;
@property(nonatomic, assign) UIScriptLiteralType valueType;
@property(nonatomic, assign) UIScriptLiteralType valueType2;

- (id) initWithSelectorName:(NSString *) selectorName;
- (id) initWithSelectorSpec:(NSArray *) selectorSpec;

@end
