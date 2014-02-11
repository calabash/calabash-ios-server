//
//  UIScriptParser.h
//  Created by Karl Krukow on 11/08/11.
//  Copyright 2011 LessPainful. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UIScriptParser : NSObject {
  NSMutableArray *_res;
  NSString *_script;
}

@property(nonatomic, retain) NSString *script;
@property(nonatomic, retain) NSArray *arrayQuery;

+ (UIScriptParser *) scriptParserWithObject:(id) obj;
+ (UIView *) findViewByClass:(NSString *) className fromView:(UIView *) parent;
- (id) initWithUIScript:(NSString *) script;
- (id) initWithQuery:(NSArray *) aq;
- (void) parse;
- (NSArray *) parsedTokens;
- (NSArray *) evalWith:(NSArray *) views;

@end
