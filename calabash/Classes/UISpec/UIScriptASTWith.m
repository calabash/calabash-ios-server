//
//  UIScriptASTWith.m
//  Created by Karl Krukow on 12/08/11.
//  Copyright 2011 LessPainful. All rights reserved.
//

#import "UIScriptASTWith.h"
#import "LPJSONUtils.h"
#import "LPTouchUtils.h"

@implementation UIScriptASTWith
@synthesize selectorName=_selectorName;
@synthesize selector=_selector;
@synthesize objectValue=_objectValue;
@synthesize objectValue2;
@synthesize boolValue=_boolValue;
@synthesize boolValue2;
@synthesize integerValue=_integerValue;
@synthesize integerValue2;
@synthesize timeout;

@synthesize valueType=_valueType;
@synthesize valueType2;

- (id)initWithSelectorName:(NSString *)selectorName {
        self = [super init];
        if (self) {
            self.valueType=UIScriptLiteralTypeUnknown;
            self.valueType2=UIScriptLiteralTypeUnknown;
            self.selectorName = selectorName;
            self.selector = NSSelectorFromString(selectorName);
            self.timeout = 3;
        }
        return self;
}
- (NSString*) description {
    NSString* fm = [NSString stringWithFormat:@"with %@:",NSStringFromSelector(self.selector)];
    switch (self.valueType) {
        case UIScriptLiteralTypeIndexPath:
        {
            NSIndexPath *ip = (id)[self objectValue];
            return [NSString stringWithFormat:@"%@%d,%d",fm,[ip row],[ip section]];            
        }

        case UIScriptLiteralTypeString:
            return [NSString stringWithFormat:@"%@'%@'",fm,self.objectValue];
        case UIScriptLiteralTypeInteger:
            return [NSString stringWithFormat:@"%@%d",fm,self.integerValue];
        case UIScriptLiteralTypeBool:
            return [NSString stringWithFormat:@"%@%@",fm,self.boolValue?@"YES":@"NO"];
        default:
            return @"UIScriptLiteralTypeUnknown";
    }
}
-(BOOL) resultsForWebView:(UIWebView *)webView query:(NSString *)jsString result:(NSMutableArray *)res
{
    NSLog(@"%@",jsString);
    
    NSString *output = [webView stringByEvaluatingJavaScriptFromString:jsString];
    NSLog(@"OUT: %@",output);
    NSArray *query = [LPJSONUtils performSelector:@selector(deserializeArray:) withObject:output]; 
    
    CGPoint webViewPoint = [webView convertPoint:webView.bounds.origin toView:[UIApplication sharedApplication].keyWindow.rootViewController.view];
    
    BOOL anyResults = NO;
    NSLog(@"%@", CGPointCreateDictionaryRepresentation(webViewPoint));
    for (NSDictionary *d in query) 
    {
        NSMutableDictionary *dres = [NSMutableDictionary dictionaryWithDictionary:d];
        CGFloat left = [[dres valueForKeyPath:@"rect.left"] floatValue];
        CGFloat top = [[dres valueForKeyPath:@"rect.top"] floatValue];
        CGFloat width =  [[dres valueForKeyPath:@"rect.width"] floatValue];
        CGFloat height =  [[dres valueForKeyPath:@"rect.height"] floatValue];
        
        
        CGPoint center = CGPointMake(left+width/2.0, top+height/2.0);            
        CGPoint screenCenter = CGPointMake(webViewPoint.x + center.x, webViewPoint.y + center.y);            
        if (!CGPointEqualToPoint(CGPointZero, center) && [webView pointInside:center withEvent:nil])
        {
            anyResults = YES;
            NSDictionary *centerDict = (NSDictionary*)CGPointCreateDictionaryRepresentation(screenCenter);
            [dres setValue:[centerDict autorelease] forKey:@"center"];
            [dres setValue:webView forKey:@"webView"];
            [res addObject:dres];                
        }
    }
    return anyResults;
}

-(void) handleWebView:(UIWebView *)webView result: (NSMutableArray *) res {
    if (self.valueType == UIScriptLiteralTypeString) {
        NSString *jsString = LP_QUERY_JS;
        if ([[self selectorName] isEqualToString:@"marked"]) 
        {
            jsString = [NSString stringWithFormat:jsString, 
                        [NSString stringWithFormat:@"//node()[contains(text(),\\\"%@\\\")]", self.objectValue], 
                        @"xpath"];                           
        }
        else if ([[self selectorName] isEqualToString:@"xpath"])
        {
            jsString = [NSString stringWithFormat:jsString, 
                        self.objectValue, 
                        @"xpath"];                        
        }
        else if ([[self selectorName] isEqualToString:@"css"])
        {
            jsString = [NSString stringWithFormat:jsString, 
                        self.objectValue, 
                        @"css"];                        
        }
        BOOL found = [self resultsForWebView: webView query:jsString result:res];
        if (!found)
        {
            jsString = [NSString stringWithFormat:LP_QUERY_JS,
                            [NSString stringWithFormat:@"//text()[contains(.,\\\"%@\\\")]", self.objectValue],
                            @"xpath"];
            
            [self resultsForWebView: webView query:jsString result:res];
        }                
        
    } else {
        NSLog(@"Attempting to look for non string in web view");
    }

}


- (NSMutableArray*) evalWith:(NSArray*) views direction:(UIScriptASTDirectionType) dir {
    NSMutableArray* res = [NSMutableArray arrayWithCapacity:8];

    for (UIView* v in views) {
        if ([v isKindOfClass:[NSDictionary class]])
        {
            NSDictionary *dict = (NSDictionary *)v;
            NSString *key = NSStringFromSelector(self.selector);
            if ([[dict valueForKey:key] isEqual:self.objectValue])
            {
                [res addObject:dict];
            }
            
        }
        else
        {
            if (![LPTouchUtils isViewVisible:v]) { continue; }
            if ([v isKindOfClass:[UIWebView class]]) {            
                [self handleWebView:(UIWebView *)v result:res];
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
            
            if ([v respondsToSelector:_selector]) {
                void* val = [v performSelector:_selector];
                switch (self.valueType) {
                    case UIScriptLiteralTypeInteger:
                        if ((NSInteger) val == self.integerValue) {
                            [res addObject:v];
                        }
                        break;
                    case UIScriptLiteralTypeString: {
                        if (val != nil && 
                            ([(NSString*)val isEqualToString:(NSString*)self.objectValue])) {
                            [res addObject:v];
                        } 
                        break;
                    }
                    case UIScriptLiteralTypeBool:
                        if (self.boolValue == (BOOL)val) {
                            [res addObject:v];
                        }
                        break;
                    default:
                        break;
                }
            }
            
        }
        
    }
    return res;
}


    
- (void) dealloc {
    self.selector=nil;
    [_objectValue release];_objectValue=nil;
    [super dealloc];
}
    

@end
