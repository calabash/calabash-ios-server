//
//  LPCalabashSelfRegisteringSelectorEngine.m
//  calabash
//
//  Created by Karl Krukow on 03/11/12.
//  Copyright (c) 2012 LessPainful. All rights reserved.
//

#import "CalabashUISpecSelectorEngine.h"
#import "UIScriptParser.h"

@implementation CalabashUISpecSelectorEngine
- (NSArray *)selectViewsWithSelector:(NSString *)query
{
    
    UIScriptParser *parser = [[UIScriptParser alloc] initWithUIScript:query];
    [parser parse];
    
    NSMutableArray* views = [NSMutableArray arrayWithCapacity:32];
    for (UIWindow *window in [[UIApplication sharedApplication] windows])
    {
        [views addObjectsFromArray:[window subviews]];
    }
   
    return [parser evalWith:views];
}
@end
