//
//  UIScriptASTWith.m
//  Created by Karl Krukow on 12/08/11.
//  Copyright 2011 LessPainful. All rights reserved.
//

#import "UIScriptASTWith.h"
#import "LPJSONUtils.h"
#import "LPTouchUtils.h"
#import "LPWebQuery.h"
#import "NSObject+LPAdditions.h"

@implementation UIScriptASTWith
@synthesize selectorName;
@synthesize objectValue;

@synthesize boolValue;

@synthesize integerValue;
@synthesize timeout;
@synthesize valueType;


- (id)initWithSelectorName:(NSString *) aSelectorName {
        self = [super init];
        if (self) {
            self.valueType=UIScriptLiteralTypeUnknown;
            self.selectorName = aSelectorName;
            self.timeout = 3;
        }
        return self;
}
- (NSString*) description {
    NSString* fm = [NSString stringWithFormat:@"with %@:", self.selectorName];
    switch (self.valueType) {
        case UIScriptLiteralTypeIndexPath:
        {
            NSLog(@"return value type is index path");
            NSIndexPath *ip = (id)[self objectValue];
            return [NSString stringWithFormat:@"%@%d,%d",fm,[ip row],[ip section]];            
        }

        case UIScriptLiteralTypeString: {
            NSLog(@"return value type is string");
            return [NSString stringWithFormat:@"%@'%@'",fm,self.objectValue];
        }
        case UIScriptLiteralTypeInteger: {
            NSLog(@"return value type is integer");
            return [NSString stringWithFormat:@"%@%d",fm,self.integerValue];
        }
        case UIScriptLiteralTypeBool: {
            NSLog(@"return value type is bool");
            return [NSString stringWithFormat:@"%@%@",fm,self.boolValue?@"YES":@"NO"];
        }
        default:
            return @"UIScriptLiteralTypeUnknown";
    }
}

-(NSArray *)handleWebView:(UIWebView *)webView {
    if (self.valueType == UIScriptLiteralTypeString) {
        LPWebQueryType type = LPWebQueryTypeCSS;
        if ([[self selectorName] isEqualToString:@"marked"]) 
        {
            type = LPWebQueryTypeFreeText;                           
        }
        else if ([[self selectorName] isEqualToString:@"xpath"])
        {
            type = LPWebQueryTypeXPATH;
        }
        else if ([[self selectorName] isEqualToString:@"css"])
        {
            type = LPWebQueryTypeCSS;
        }
        return [LPWebQuery evaluateQuery:(NSString*)self.objectValue ofType:type inWebView:webView];                
    } else {
        NSLog(@"Attempting to look for non string in web view");
        return [NSMutableArray array];
    }

}


- (NSMutableArray *)evalWith:(NSArray*) views direction:(UIScriptASTDirectionType) dir {
    NSMutableArray* res = [NSMutableArray arrayWithCapacity:8];

    for (UIView* v in views) {
        if ([v isKindOfClass:[NSDictionary class]])
        {
            NSDictionary *dict = (NSDictionary *)v;
            if ([[dict valueForKey:self.selectorName] isEqual:self.objectValue])
            {
                [res addObject:dict];
            }
            
        }
        else
        {
            if (![LPTouchUtils isViewVisible:v]) { continue; }
            if ([v isKindOfClass:[UIWebView class]]) 
            {            
                [res addObjectsFromArray: [self handleWebView:(UIWebView *)v]];
                continue;            
            }
            if ([self.selectorName isEqualToString:@"marked"]) 
            {
                NSString *val = nil;
                if ([v respondsToSelector:@selector(accessibilityIdentifier)])
                {
                    val = [v accessibilityIdentifier];                
                    if ([val isEqualToString:(NSString*)self.objectValue])
                    {
                        [res addObject:v];
                        continue;
                    }
                }            
                val = [v accessibilityLabel];
                if ([val isEqualToString:(NSString*)self.objectValue])
                {
                    [res addObject:v];
                }            
                continue;
            } 
            if ([v isKindOfClass:[UITableViewCell class]] && 
                [self.selectorName isEqualToString:@"indexPath"])
            {
                UITableViewCell *cell = (UITableViewCell*)v;
                NSIndexPath *indexPath = (NSIndexPath *) self.objectValue;
                id tableView = [cell superview];
                while(tableView && ![tableView isKindOfClass:[UITableView class]])
                {
                    tableView = [tableView superview];
                }
                if (tableView)
                {
                    UITableView *tv = (UITableView*)tableView;
                    if ([indexPath isEqual:[tv indexPathForCell:cell]])
                    {
                        [res addObject:cell];
                    }
                }
                continue;            
            }
            
            SEL sel = NSSelectorFromString(self.selectorName);
            if ([v respondsToSelector:sel]) 
            {
              
                if ([v selectorReturnsObjectOrVoid:sel]) {
                    //NSLog(@"selector named: %@ returns void or an object: %@", self.selectorName, self);
                    id val = [v performSelectorSafely:sel];
                    if (self.valueType == UIScriptLiteralTypeString) {
                        if ((val != nil) &&
                            ([(NSString*)val isEqualToString:(NSString*)self.objectValue])) {
                            [res addObject:v];
                        }
                    } else {
                        continue;
                    }
                } else {
                    //NSLog(@"selector named: %@ returns non object and non-void: %@", self.selectorName, self);
                    NSMethodSignature *msig = [[v class] instanceMethodSignatureForSelector:sel];
                    NSInvocation *inv = [NSInvocation invocationWithMethodSignature:msig];
                    [inv setSelector:sel];
                    [inv setTarget:v];
                    [inv invoke];
                                        
                    switch (self.valueType) {
                        case UIScriptLiteralTypeInteger: {
                            NSInteger intVal;
                            [inv getReturnValue:(void **)&intVal];
                            //NSLog(@"int val = %d and self.integer value = %d", intVal, self.integerValue);
                            if (intVal == self.integerValue) [res addObject:v];
                            break;
                        }
                        case UIScriptLiteralTypeBool: {
                            BOOL boolVal;
                            [inv getReturnValue:(void **)&boolVal];
                            //NSLog(@"bool val = %d and self.boolValue value = %d", boolVal, self.boolValue);
                            if (boolVal == self.boolValue) [res addObject:v];
                            break;
                        }
                        default:
                            break;
                    }
        
                }
              
            }
            
        }
    }

    return res;
}

@end
