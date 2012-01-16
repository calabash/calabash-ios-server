//
//  UIScriptParser.m
//  Created by Karl Krukow on 11/08/11.
//  Copyright 2011 LessPainful. All rights reserved.
//

#import "UIScriptParser.h"
#import "UIScriptASTClassName.h"
#import "UIScriptASTIndex.h"
#import "UIScriptASTWith.h"
#import "UIScriptASTALL.h"
#import "UIScriptASTFirst.h"
#import "UIScriptASTLast.h"
#import "UIScriptASTDirection.h"


@interface UIScriptParser() 
    - (NSString*) parseClassName:(NSString*) token;
    - (UIScriptAST*) parseIndexOrProperty:(NSString*) token;
    - (void) parseLiteralValue:(NSString*) literalToken addToWithAST:(UIScriptASTWith*) ast;
    - (UIScriptASTDirection*) parseDirectionIfPresent:(NSString*) token;
    - (NSString *)findNextToken:(NSUInteger *)index;
@end

@implementation UIScriptParser
@synthesize script=_script;

- (id) initWithUIScript:(NSString*) script {
    self = [super init];
    if (self) {
        self.script = script;
        _res = [[NSMutableArray alloc] initWithCapacity:8];
    }
    return self;
}

- (void) dealloc {
    [_res release];_res=nil;
    [super dealloc];
}

#pragma mark Parsing
static NSCharacterSet* colon = nil;
static NSCharacterSet* ping = nil;

- (void) parse {
    
    if (colon==nil) {colon=[[NSCharacterSet characterSetWithCharactersInString:@":"] retain];}
    if (ping==nil) {ping=[[NSCharacterSet characterSetWithCharactersInString:@"'"] retain];}
    
    NSUInteger index=0;
    NSUInteger N=[_script length];
    NSString* token = [self findNextToken:&index];
    while (token) {
        //token should be a direction or classname
        UIScriptASTDirection* direction = [self parseDirectionIfPresent:token];
        if (direction!=nil) {
            [_res addObject:direction];    
            if (index == N) {return;}
            token = [self findNextToken:&index];
        } else {// default is descendant
            
        }
        
        if ([token isEqualToString:@"all"]) {
            UIScriptASTALL* all = [UIScriptASTALL new];
            [_res addObject:all];
            [all release];
            return;//ignore everything past all
        } else if ([token isEqualToString:@"last"]) {
            UIScriptAST* last = [UIScriptASTLast new];
            [_res addObject:last];
            [last release];
            return;//ignore everything past last
        } else if ([token isEqualToString:@"first"]) {
            UIScriptAST* first = [UIScriptASTFirst new];
            [_res addObject:first];
            [first release];
            return;//ignore everything past first
        }
        
        
        //token should be a classname, e.g., view:'UITableView' or tableView
        NSString* clzName = [self parseClassName:token];
        UIScriptASTClassName* c = [[UIScriptASTClassName alloc] initWithClassName:clzName];
        [_res addObject:c];
        [c release];
        
        if (index == N) {return;}
        token = [self findNextToken:&index];
        if (token==nil) { break; }
        
        UIScriptAST* indexOrProp = [self parseIndexOrProperty:token];
        while (indexOrProp != nil) {
            //token is an index or property

            [_res addObject:indexOrProp];
             
            if (index == N) {return;}
            token = [self findNextToken:&index];
            indexOrProp=[self parseIndexOrProperty:token];
            
            
        }//else lookahead reveals another classname so continue        
    }
}

- (NSString *)findNextToken:(NSUInteger *)index {
    static NSCharacterSet *notWhite = nil;
    
    if (notWhite==nil) {
        NSMutableCharacterSet *cs = [NSMutableCharacterSet whitespaceCharacterSet];
        [cs invert];
        notWhite = [cs retain];
    }
    static NSCharacterSet *whiteSpaceOrPing = nil;
    
    if (whiteSpaceOrPing==nil) {
        NSMutableCharacterSet *cs = [NSMutableCharacterSet whitespaceCharacterSet];
        [cs formUnionWithCharacterSet:ping];
        whiteSpaceOrPing = [cs retain];
    }
    
    NSUInteger i = *index;
    NSUInteger N = [_script length];
    if (i==N) {
        return nil;
    }
    NSRange range=[_script rangeOfCharacterFromSet:whiteSpaceOrPing options:NSLiteralSearch range:NSMakeRange(i, N-i)];
    if (range.location==NSNotFound) {
        //last token
        *index=N;
        return [_script substringFromIndex:i];
    }
    NSString *firstChar = [_script substringWithRange:range];
    if ([firstChar isEqualToString:@"'"]) {
        NSRange endPing = [_script rangeOfCharacterFromSet:ping options:NSLiteralSearch range:NSMakeRange(range.location+1, N-range.location-1)];
        if (endPing.location==NSNotFound) {
            return nil;
        }
        NSString *res = [_script substringWithRange:NSMakeRange(i, endPing.location-i+1)];
        *index = endPing.location+1;
        if (*index < N) {
            i=*index;
            NSRange range=[_script rangeOfCharacterFromSet:notWhite options:NSLiteralSearch range:NSMakeRange(i, N-i)];
            *index = range.location;
        }
        return res;
    } else {//whitespace
        *index = range.location+range.length;
        NSRange txtRange = NSMakeRange(i,range.location-i);
        return [_script substringWithRange:txtRange];
    }
}

- (NSArray*) parsedTokens {return [[_res mutableCopy] autorelease];}

- (UIScriptASTDirection*) parseDirectionIfPresent:(NSString*) token {
    if ([token isEqualToString:@"parent"]) {
        UIScriptASTDirection* d = [[UIScriptASTDirection alloc] initWithDirection:UIScriptASTDirectionTypeParent];
        return [d autorelease];
    }
    if ([token isEqualToString:@"find"] || [token isEqualToString:@"descendant"]) {
        UIScriptASTDirection* d = [[UIScriptASTDirection alloc] initWithDirection:UIScriptASTDirectionTypeDescendant];
        return [d autorelease];
    }
    if ([token isEqualToString:@"child"]) {
        UIScriptASTDirection* d = [[UIScriptASTDirection alloc] initWithDirection:UIScriptASTDirectionTypeChild];
        return [d autorelease];
    }
    return nil;
}

- (NSString*) parseClassName:(NSString*) token {
    NSArray* colonSep=[token componentsSeparatedByCharactersInSet:colon];
    if ([colonSep count] > 1) {//view:'xx'
        NSString *viewTok = [colonSep objectAtIndex:0];
        if (![viewTok isEqualToString:@"view"]) {return nil;}
        //'xx'
        NSString *clzTok = [colonSep objectAtIndex:1];
        NSArray* nameArr = [clzTok componentsSeparatedByCharactersInSet:ping];
        if ([nameArr count]!=3) {return nil;}
        return [nameArr objectAtIndex:1];
    } else {
        NSString* smallCaseName = [colonSep objectAtIndex:0];
        //tableView
        NSString* upCaseFirst = [[smallCaseName substringToIndex:1] uppercaseString];
        return [NSString stringWithFormat:@"UI%@%@",upCaseFirst,[smallCaseName substringFromIndex:1]];
    }
}

- (UIScriptAST*) parseIndexOrProperty:(NSString*) token {
    NSArray* colonSep=[token componentsSeparatedByCharactersInSet:colon];
    if ([colonSep count] != 2) {
        return nil;
    }
    //propOrIndex:value
    NSString *propNameOrIndex = [colonSep objectAtIndex:0];
    if ([@"view" isEqualToString:propNameOrIndex]) {
        return nil;//property can't be view
    }
    if ([propNameOrIndex isEqualToString:@"index"]) {
        NSString* value = [colonSep objectAtIndex:1];
        NSNumberFormatter* nf = [[NSNumberFormatter alloc] init];
        NSNumber* numVal = [nf numberFromString:value];
        [nf release];
        NSUInteger val = [numVal unsignedIntegerValue];
        return [[[UIScriptASTIndex alloc] initWithIndex:val] autorelease];
    }
    //general property
    NSString *propName = [colonSep objectAtIndex:0];
    NSString* propValTok = [colonSep objectAtIndex:1];
    UIScriptASTWith* withProp = [[UIScriptASTWith alloc] initWithSelectorName:propName];
    
    [self parseLiteralValue:propValTok addToWithAST:withProp];
    
    return [withProp autorelease];
}

- (void) parseLiteralValue:(NSString*) literalToken addToWithAST:(UIScriptASTWith*) ast {
    if ([@"NO" isEqualToString:literalToken]) {
        ast.valueType = UIScriptLiteralTypeBool;
        [ast setBoolValue:NO];
        return;
    }
    if ([@"YES" isEqualToString:literalToken]) {
        ast.valueType = UIScriptLiteralTypeBool;
        [ast setBoolValue:YES];
        return;
    }     
    if ([literalToken length] >= 2) {
        NSString* startChar = [literalToken substringToIndex:1];    
        NSString* endChar = [literalToken substringFromIndex:[literalToken length]-1];
        if ([startChar isEqualToString:@"'"]) {
            if (![endChar isEqualToString:@"'"]) {
                //log err
                ast.valueType = UIScriptLiteralTypeUnknown;
                return;
            }
            //literalToken = 'VAL'
            ast.valueType = UIScriptLiteralTypeString;
            ast.objectValue = [literalToken substringWithRange:NSMakeRange(1, [literalToken length]-2)];
            return;
        }
    }
    NSNumberFormatter* nf = [[NSNumberFormatter alloc] init];
    NSNumber* numVal = [nf numberFromString:literalToken];
    [nf release];
    ast.valueType = UIScriptLiteralTypeInteger;
    ast.integerValue = [numVal integerValue];
    //does not handle float/double
}

- (NSArray*) evalWith:(NSArray*) views {
    if ([_res count] == 0) {return nil;}
    NSUInteger index = 0;
    UIScriptASTDirectionType dir = UIScriptASTDirectionTypeDescendant;
     
    //index and first match first = [res objectAtIndex:index];
    //dir is direction or default direction
    NSArray* res = views;
    NSUInteger N = [_res count];
    while (index<N) {
        UIScriptAST* cur = [_res objectAtIndex:index++];
        if ([cur isKindOfClass:[UIScriptASTDirection class]]) {
            dir = [(UIScriptASTDirection*)cur directionType];
        } else {
            res = [cur evalWith:res direction:dir];
        }
    }
    return res;
}

@end
