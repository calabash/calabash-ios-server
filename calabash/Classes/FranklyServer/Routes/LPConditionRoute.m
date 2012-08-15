
//
//  LPConditionRoute.m
//  calabash
//
//  Created by Karl Krukow on 29/01/12.
//  Copyright (c) 2012 LessPainful. All rights reserved.
//

#import "LPConditionRoute.h"
#import "LPHTTPResponse.h"
#import "LPHTTPConnection.h"
#import "LPResources.h"
#import "LPRecorder.h"
#import "UIScriptParser.h"
#import "LPTouchUtils.h"
#import "LPJSONUtils.h"
#import <QuartzCore/QuartzCore.h>


@implementation LPConditionRoute
@synthesize timer=_timer;
@synthesize maxCount;
@synthesize curCount;
@synthesize parser;


// Should only return YES after the LPHTTPConnection has read all available data.
- (BOOL)isDone 
{
    return !self.timer && [super isDone];
}

-(void) beginOperation {
    self.done = NO;
    id query = [self.data objectForKey:@"query"];
    NSString *condition = [self.data objectForKey:@"condition"];
    if (!condition)
    {
        NSLog(@"condition not specified");
        [self failWithMessageFormat: @"condition parameter missing" message:nil];            
        return;
    }
    NSNumber *count = [self.data objectForKey:@"count"];
    if (!count)
    {
        count = [NSNumber numberWithInt:5];
    }
    if ([count integerValue] <= 0)
    {
        [self failWithMessageFormat: @"Count should be positive..." message:nil];            
        return;
    }
    self.maxCount = [count integerValue];
    self.curCount = 0;
    NSNumber *freq = [self.data objectForKey:@"frequency"];
    if (!freq)
    {
        freq = [NSNumber numberWithDouble:0.2];
    }

    
    NSArray* result = nil;
    if (query)
    {
        self.parser = [UIScriptParser scriptParserWithObject:query];
        [self.parser parse];
        
        NSMutableArray* views = [NSMutableArray arrayWithCapacity:32];
        for (UIWindow *window in [[UIApplication sharedApplication] windows])
        {
            [views addObjectsFromArray:[window subviews]];
        }
        
        result = [self.parser evalWith:views];
    }
        
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObject:condition forKey:@"condition" ];
    if (result)
    {
        [params setObject:result forKey:@"views"];
        [params setObject:self.parser  forKey:@"parser"];
        
    }
        
    self.timer = [NSTimer scheduledTimerWithTimeInterval:[freq doubleValue] 
                                                      target:self 
                                                    selector:@selector(checkConditionWithTimer:) 
                                                    userInfo:params repeats:YES];        
    [self checkConditionWithTimer:self.timer];  
    

}
-(void)checkConditionWithTimer:(NSTimer *)aTimer
{
    self.curCount += 1;
    NSString *condition = [aTimer.userInfo objectForKey:@"condition"];
    if ([condition isEqualToString:@"NONE_ANIMATING"])
    {
        UIScriptParser *parse = [aTimer.userInfo objectForKey:@"parser"];
        NSMutableArray* initialViews = [NSMutableArray arrayWithCapacity:32];
        for (UIWindow *window in [[UIApplication sharedApplication] windows]) 
        {
            [initialViews addObjectsFromArray:[window subviews]];
        }
        
        NSArray *views = [parse evalWith:initialViews];
        
        for (id v in views)
        {
            if ([v isKindOfClass:[UIView class]])
            {
                UIView *view = (UIView *)v;
                if ([[view.layer animationKeys] count] > 0)
                {
                    [self failWithMessageFormat:@"Found animating view: %@" message:v];
                    return;
                }
            }
            
        }
        if (self.curCount == self.maxCount)
        {
            [self succeedWithResult:[NSArray array]];
        }
        return;
        
    }
    else if ([condition isEqualToString:@"NO_NETWORK_INDICATOR"])
    {
        if ([[UIApplication sharedApplication] isNetworkActivityIndicatorVisible])
        {
            [self failWithMessageFormat:@"Network activity indicator visible" message:nil];
            return;
        }
        if (self.curCount == self.maxCount)
        {
            [self succeedWithResult:[NSArray array]];
        }
        return;
        
    }
    [self failWithMessageFormat:@"Unknown condition %@" message:condition];
    
}

-(void)failWithMessageFormat:(NSString *)messageFmt message:(NSString *)message
{
    [self.timer invalidate];    
    self.timer = nil;
    self.parser = nil;
    [super failWithMessageFormat:messageFmt message:message];
}

-(void)succeedWithResult:(NSArray *)result
{
    [self.timer invalidate];    
    self.timer = nil;
    self.parser = nil;
    [super succeedWithResult:result];
}

-(void) dealloc 
{
    self.timer = nil;
    self.parser = nil;    
    [super dealloc];
}

@end

