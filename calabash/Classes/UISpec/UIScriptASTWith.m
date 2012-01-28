//
//  UIScriptASTWith.m
//  Created by Karl Krukow on 12/08/11.
//  Copyright 2011 LessPainful. All rights reserved.
//

#import "UIScriptASTWith.h"
#import "NDWebElement.h"
#import "LPNDElementWrapper.h"

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
            if ([self.selectorName isEqualToString:@"marked"]) {
                self.selector = @selector(accessibilityLabel);
            } else {
                self.selector = NSSelectorFromString(selectorName);
            }
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

-(void) handleWebView:(UIWebView *)webView result: (NSMutableArray *) res {
    if (self.valueType == UIScriptLiteralTypeString) {
        NSString * query = [NSString stringWithFormat:@"/html//*[contains(text(),'%@')]",self.objectValue];
        NSArray* arr = [NDWebElement findElementsBy:kByXpath value:query maxCount:kFindEverything webView:webView];
        for (NDWebElement* el in arr) {
            if  ([el isDisplayed]) {
                [res addObject:[[[LPNDElementWrapper alloc] initWithElement: el] autorelease]];
            }
        }
    } else {
        NSLog(@"Attempting to look for non string in web view");
    }
}


- (NSMutableArray*) evalWith:(NSArray*) views direction:(UIScriptASTDirectionType) dir {
    NSMutableArray* res = [NSMutableArray arrayWithCapacity:8];
    //special cases  
//    NSDate *start = [NSDate date];
//	while ([start timeIntervalSinceNow] > (0 - self.timeout)) {
//		for (UIView *view in views) {
//			if (![view respondsToSelector:selector]) {
//						continue;
//            }
//            void* val = [v performSelector:_selector];
//            switch (self.valueType) {
//                case UIScriptLiteralTypeInteger:
//                    if ((NSInteger) val == self.integerValue) {
//                        [res addObject:v];
//                    }
//                    break;
//                case UIScriptLiteralTypeString:
//                    if ([(NSString*) self.objectValue isEqualToString:(NSString*)val]) {
//                        [res addObject:v];
//                    }
//                    break;
//                case UIScriptLiteralTypeBool:
//                    if (self.boolValue == (BOOL)val) {
//                        [res addObject:v];
//                    }
//                    break;
//                default:
//                    break;
//            }
//			
//					NSString *returnType = [NSString stringWithFormat:@"%s", [[view methodSignatureForSelector:selector] methodReturnType]];
//					//NSLog(@"selector = %@ and returnType = %@", key, returnType);
//					if ([returnType isEqualToString:@"@"]) {
//						if ([value isKindOfClass:[NSString class]]) {
//                            NSString* o = [view performSelector:selector];
//							if (o != nil && [o rangeOfString:value].length != 0) {
//								matchCount++;
//							}
//						} else if ([[view performSelector:selector] isEqual:value]) {
//							matchCount++;
//						} else if ([view performSelector:selector] == value) {
//							matchCount++;
//						}
//					} else {
//						//if ([returnType isEqualToString:@"i"]) {
//                        //							NSLog(@"value for int = %d and selector performed = %d", value, [view performSelector:selector]);
//                        //						}
//						if ([view performSelector:selector] == value) {
//							matchCount++;
//						}
//					}
//				} else {
//					matchCount++;
//				}
//			}
//			if (selectors.count == matchCount) {
//				[array addObject:view];
//			}
//		}
//		if (array.count > 0) {
//			break;
//		} else {
//			//NSLog(@"selector = %@", selector);
//			[self redo];
//		}
//	}
//
    for (UIView* v in views) {
        if ([v isHidden]) continue;
        if (([self.selectorName isEqualToString:@"marked"] 
            || [self.selectorName isEqualToString:@"accessibilityLabel"]) &&
            [v isKindOfClass:[UIWebView class]]) {
            
            [self handleWebView:(UIWebView *)v result:res];
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
