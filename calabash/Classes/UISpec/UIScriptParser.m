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
#import "UIScriptASTPredicate.h"


@interface UIScriptParser()
    - (NSString*) parseClassName:(NSString*) token;
    - (UIScriptAST*) parseIndexPropertyOrPredicate:(NSString*) token;
    - (void) parseLiteralValue:(NSString*) literalToken addToWithAST:(UIScriptASTWith*) ast;
    - (UIScriptASTDirection*) parseDirectionIfPresent:(NSString*) token;
    - (NSString *)findNextToken:(NSUInteger *)index;
@end

@implementation UIScriptParser
@synthesize script=_script;

+(UIScriptParser*)scriptParserWithObject:(id)obj
{
    if ([obj isKindOfClass:[NSString class]])
    {
        return [[[UIScriptParser alloc] initWithUIScript:(NSString*) obj] autorelease];
    }
    else if ([obj isKindOfClass:[NSArray class]])
    {
        return [[[UIScriptParser alloc] initWithQuery:(NSArray*) obj] autorelease];
    }
    return nil;
}

- (id) initWithUIScript:(NSString*) script {
    self = [super init];
    if (self) {
        self.script = script;
        _res = [[NSMutableArray alloc] initWithCapacity:8];
    }
    return self;
}

- (id) initWithQuery:(NSArray*) aq {
    self = [super init];
    if (self) {
        self.arrayQuery = aq;
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
static NSCharacterSet* curlyBrackets = nil;

- (void) parse {
    
    if (colon==nil) {colon=[[NSCharacterSet characterSetWithCharactersInString:@":"] retain];}
    if (ping==nil) {ping=[[NSCharacterSet characterSetWithCharactersInString:@"'"] retain];}
    if (curlyBrackets==nil) {curlyBrackets=[[NSCharacterSet characterSetWithCharactersInString:@"{}"] retain];}
    
    if (self.script)
    {
        [self parseString];
    }
    else
    {
        [self parseArray];
    }
    
}

-(void)parseArray
{
    for (NSObject *obj in self.arrayQuery)
    {
        //each object can be one of
        //String/Symbol/keyword
        //Example direction: descendant, child, parent
        //Example classname: UITableView
        if ([obj isKindOfClass:[NSString class]])
        {
            NSString* token = (NSString*)obj;
            UIScriptASTDirection* direction = nil;
            direction = [self parseDirectionIfPresent:token];
            if (direction)
            {
                [_res addObject:direction];
            } else {// default is descendant
                //should be a classname
                UIScriptASTClassName *cn = [[[UIScriptASTClassName alloc] initWithClassName:token] autorelease];
                [_res addObject:cn];
            }
            
        }
        else if ([obj isKindOfClass:[NSDictionary class]])
        {//NSDictionary
            //Example direction: {:text "Karl, :length 42}
            NSDictionary *dic = (NSDictionary*)obj;
            for (NSString *key in [dic keyEnumerator])
            {
                id val = [dic valueForKey:key];
                UIScriptASTWith *w = [[[UIScriptASTWith alloc] initWithSelectorName:key] autorelease];
                
                if ([val isKindOfClass:[NSString class]])
                {
                    w.valueType = UIScriptLiteralTypeString;
                    w.objectValue = val;
                }
                else if ([val isKindOfClass:[NSNumber class]])
                {
                    w.valueType = UIScriptLiteralTypeInteger;
                    w.integerValue = [val integerValue];
                }
                else if ([val isKindOfClass:[NSArray class]])
                {
                    NSNumber *i1 = [val objectAtIndex:0];
                    NSNumber *i2 = [val objectAtIndex:1];
                    
                    w.valueType = UIScriptLiteralTypeIndexPath;
                    w.objectValue = [NSIndexPath indexPathForRow: [i1 integerValue]
                                                       inSection:[i2 integerValue]];

                } else
                {
                    NSLog(@"Unknown value type %@",val);
                }
                [_res addObject:w];
                
            }
            
        }
        else if ([obj isKindOfClass:[NSArray class]])
        {
            NSArray *arr = (NSArray*)obj;
            if ([arr count] == 2)
            {//type selector value
//                id selObj = [arr objectAtIndex:0];
//                id val = [arr objectAtIndex:1];
                NSLog(@"TODO...%@",arr);
            }
            if ([arr count] == 3)
            {//relation/NSPredicate
                NSString *selStr = [arr objectAtIndex:0];
                NSString *rel = [arr objectAtIndex:1];
                id val = [arr objectAtIndex:2];
                SEL sel = NSSelectorFromString(selStr);
                NSPredicate *pred = nil;
                if ([val isKindOfClass:[NSString class]])
                {
                    pred = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"%@ %@ '%@'",selStr,rel,val]];
                }
                else
                {
                    pred = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"%@ %@ %@",selStr,rel,val]];
                }
                [_res addObject:[[[UIScriptASTPredicate alloc] initWithPredicate:pred selector:sel] autorelease]];

            }
            
        }
        
        

    }
}

-(void)parseString
{
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
        
        UIScriptAST* indexPropOrPred = [self parseIndexPropertyOrPredicate:token];
        while (indexPropOrPred != nil) {
            //token is an index or property
            
            [_res addObject:indexPropOrPred];
            
            if (index == N) {return;}
            token = [self findNextToken:&index];
            indexPropOrPred=[self parseIndexPropertyOrPredicate:token];
            
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
    static NSCharacterSet *whiteSpaceSquareOrPing = nil;
    
    if (whiteSpaceSquareOrPing==nil) {
        NSMutableCharacterSet *cs = [NSMutableCharacterSet whitespaceCharacterSet];
        [cs formUnionWithCharacterSet:ping];
        [cs formUnionWithCharacterSet:curlyBrackets];
        whiteSpaceSquareOrPing = [cs retain];
    }
    
    NSUInteger i = *index;
    NSUInteger N = [_script length];
    if (i==N) {
        return nil;
    }
    NSRange range=[_script rangeOfCharacterFromSet:whiteSpaceSquareOrPing options:NSLiteralSearch range:NSMakeRange(i, N-i)];
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
        } else {
            while (endPing.location > 0 && 
                   [[_script substringWithRange:NSMakeRange(endPing.location-1,1)] isEqualToString:@"\\"]) {
                endPing = [_script rangeOfCharacterFromSet:ping options:NSLiteralSearch range:NSMakeRange(endPing.location+1, N-endPing.location-1)];                
                if (endPing.location == NSNotFound) {
                    return nil;
                }                 
            } 
            
        }
        NSString *res = [_script substringWithRange:NSMakeRange(i, endPing.location-i+1)];
        *index = endPing.location+1;
        if (*index < N) {
            i=*index;
            NSRange range=[_script rangeOfCharacterFromSet:notWhite options:NSLiteralSearch range:NSMakeRange(i, N-i)];
            *index = range.location;
        }
        return [res stringByReplacingOccurrencesOfString:@"\\'" withString:@"'"];
    } else if ([firstChar isEqualToString:@"}"]) {
        NSLog(@"Illegal unbalanced [] found %@",_script);
        return nil;
    } else if ([firstChar isEqualToString:@"{"]) {
        NSRange endBrack = [_script rangeOfString:@"}" options:NSLiteralSearch range:NSMakeRange(range.location+1, N-range.location-1)];
        if (endBrack.location==NSNotFound) {
            return nil;
        }
        NSString *res = [_script substringWithRange:NSMakeRange(i, endBrack.location-i+1)];
        *index = endBrack.location+1;
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

- (UIScriptAST*) parseIndexPropertyOrPredicate:(NSString*) token {
    NSRange r = [token rangeOfString:@"{"];
    if (r.location == 0) {
        NSString *str = [token substringWithRange:NSMakeRange(1, token.length - 2)];
        NSCharacterSet* white = [NSCharacterSet whitespaceCharacterSet];
        NSRange range = [str rangeOfCharacterFromSet:white];
        NSString *selString = [str substringWithRange:NSMakeRange(0, range.location)];
        SEL sel = NSSelectorFromString(selString);

        NSPredicate *pred = [NSPredicate predicateWithFormat:str];        
        return [[[UIScriptASTPredicate alloc] initWithPredicate:pred selector:sel] autorelease];
        
    }

    NSArray* colonSep=[token componentsSeparatedByCharactersInSet:colon];
    if ([colonSep count] < 2) {
        
        
        NSLog(@"Warning: token %@ has no : separator", token);
        return nil;
    }
    
    //handle general case...
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
    NSString* propValTok = [[colonSep subarrayWithRange:NSMakeRange(1, [colonSep count]-1)] componentsJoinedByString:@":"];
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
        else
        {
            NSRange rng = [literalToken rangeOfString:@","];
            if (rng.location != NSNotFound)
            {
                NSString *str1 = [literalToken substringWithRange:NSMakeRange(0, rng.location)];
                NSString *str2 = [literalToken substringFromIndex:rng.location+1];
                ast.valueType = UIScriptLiteralTypeIndexPath;
                ast.objectValue = [NSIndexPath indexPathForRow:[str1 integerValue] inSection:[str2 integerValue]];
                return;
                
                
            }
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
