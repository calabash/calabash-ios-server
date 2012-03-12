//
//  TextOperation.m
//  FoodFinder
//
//  Created by Karl Krukow on 11/09/11.
//  Copyright (c) 2011 LessPainful. All rights reserved.
//

#import "LPSetTextOperation.h"
#import "LPJSONUtils.h"

@implementation LPSetTextOperation
- (NSString *) description {
	return [NSString stringWithFormat:@"Text: %@",_arguments];
}

- (id) performWithTarget:(id)_view error:(NSError **)error {
    if ([_view isKindOfClass:[NSDictionary class]])
    {
            NSMutableDictionary *mdict = [NSMutableDictionary dictionaryWithDictionary:_view];
            [mdict removeObjectForKey:@"html"];
        
            UIWebView *webView = [mdict valueForKey:@"webView"];
            NSString* json = [LPJSONUtils serializeDictionary:mdict];
            NSLog(@"script: %@",[NSString stringWithFormat:LP_SET_TEXT_JS, json,[_arguments objectAtIndex:0]]);
            NSString* res = [webView stringByEvaluatingJavaScriptFromString:
             [NSString stringWithFormat:LP_SET_TEXT_JS, json]
             ];
            NSLog(@"RESULT: %@", res);
        
    }
    else if ([_view respondsToSelector:@selector(setText:)]) 
    {
        NSString *txt = [_arguments objectAtIndex:0];        
        [_view performSelector:@selector(setText:) withObject:txt];
        return _view;
    }
    
	return nil;
}

@end
