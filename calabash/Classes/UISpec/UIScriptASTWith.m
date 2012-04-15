//
//  UIScriptASTWith.m
//  Created by Karl Krukow on 12/08/11.
//  Copyright 2011 LessPainful. All rights reserved.
//

#import "UIScriptASTWith.h"
#import "NDWebElement.h"
#import "LPNDElementWrapper.h"
#import "LPJSONUtils.h"

@implementation UIScriptASTWith
@synthesize selectorName=_selectorName;
@synthesize selector=_selector;
@synthesize objectValue=_objectValue;
@synthesize boolValue=_boolValue;
@synthesize integerValue=_integerValue;
@synthesize timeout;

@synthesize valueType=_valueType;

- (id)initWithSelectorName:(NSString *)selectorName {
        self = [super init];
        if (self) {
            self.selectorName = selectorName;
            self.selector = NSSelectorFromString(selectorName);
            self.timeout = 3;
        }
        return self;
}
- (NSString*) description {
    NSString* fm = [NSString stringWithFormat:@"with %@:",NSStringFromSelector(self.selector)];
    switch (self.valueType) {
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
        if ([v isHidden]) continue;
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
    return res;
}


    
- (void) dealloc {
    self.selector=nil;
    [_objectValue release];_objectValue=nil;
    [super dealloc];
}
    

@end
