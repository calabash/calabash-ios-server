//
//  UIScriptParser.h
//  Created by Karl Krukow on 11/08/11.
//  Copyright 2011 Xamarin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UIScriptParser : NSObject {
    NSMutableArray *_res;
    NSString *_script;
}

@property (nonatomic, retain) NSString* script;
@property (nonatomic, retain) NSArray* arrayQuery;

+(UIScriptParser*)scriptParserWithObject:(id)obj;
- (id) initWithUIScript:(NSString*) script;

- (void) parse;
- (NSArray*) parsedTokens;

- (NSArray*) evalWith:(NSArray*) views;

@end
