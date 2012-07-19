//
//  UIScriptParser.h
//  Created by Karl Krukow on 11/08/11.
//  Copyright 2011 LessPainful. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UIScriptParser : NSObject {

}

@property (copy, nonatomic) NSString* script;
@property (nonatomic, strong) NSMutableArray *res;

- (id) initWithUIScript:(NSString*) script;

- (void) parse;
- (NSArray*) parsedTokens;

- (NSArray*) evalWith:(NSArray*) views;

@end
