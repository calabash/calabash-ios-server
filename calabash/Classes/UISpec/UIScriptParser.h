//
//  UIScriptParser.h
//  Created by Karl Krukow on 11/08/11.
//  Copyright 2011 LessPainful. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIScriptParser : NSObject

@property(nonatomic, strong) NSMutableArray *res;
@property(nonatomic, copy) NSString *script;
@property(nonatomic, copy) NSArray *arrayQuery;

+ (UIScriptParser *) scriptParserWithObject:(id) obj;
+ (UIView *) findViewByClass:(NSString *) className fromView:(UIView *) parent;
- (id) initWithUIScript:(NSString *) script;
- (id) initWithQuery:(NSArray *) aq;
- (void) parse;
- (NSArray *) parsedTokens;
- (NSArray *) evalWith:(NSArray *) views;

@end
