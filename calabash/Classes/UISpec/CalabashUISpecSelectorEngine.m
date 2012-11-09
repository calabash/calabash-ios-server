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
    UIView *window = [[UIApplication sharedApplication] keyWindow];
    
    UIScriptParser *parser = [[UIScriptParser alloc] initWithUIScript:query];
    [parser parse];
    return [parser evalWith:window.subviews];    
}
@end
