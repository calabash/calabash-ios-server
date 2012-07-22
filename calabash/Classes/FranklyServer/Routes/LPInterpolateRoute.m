//
//  LPPanningRoute.m
//  LPSimpleExample
//
//  Created by Karl Krukow on 14/03/12.
//  Copyright (c) 2012 Trifork. All rights reserved.
//

#import "LPAsyncPlaybackRoute.h"
#import "LPHTTPResponse.h"
#import "LPHTTPConnection.h"
#import "LPResources.h"
#import "LPRecorder.h"
#import "UIScriptParser.h"
#import "LPTouchUtils.h"
#import "LPJSONUtils.h"
#import "LPInterpolateRoute.h"


@implementation LPInterpolateRoute

@synthesize events=_events;

// Should only return YES after the LPHTTPConnection has read all available data.
- (BOOL)isDone {
    return self.done && self.events == nil && self.jsonResponse == nil;
}


-(void) playbackEvents {
    self.done = NO;
    NSString *base64Events = [self.data objectForKey:@"events"];
    NSString *queryStart = [self.data objectForKey:@"start"];
    NSString *queryEnd = [self.data objectForKey:@"end"];

    NSDictionary *offset_start = [self.data valueForKey:@"offset_start"];
    NSNumber *off_start_x = [offset_start valueForKey:@"x"];
    NSNumber *off_start_y = [offset_start valueForKey:@"y"];    
        
    CGPoint offsetPointStart = CGPointMake([off_start_x floatValue], [off_start_y floatValue]);

    NSDictionary *offset_end = [self.data valueForKey:@"offset_end"];
    NSNumber *off_end_x = [offset_end valueForKey:@"x"];
    NSNumber *off_end_y = [offset_end valueForKey:@"y"];    
    
    CGPoint offsetPointEnd = CGPointMake([off_end_x floatValue], [off_end_y floatValue]);

    UIView *targetView = nil;
    UIScriptParser *parseStart = [[UIScriptParser alloc] initWithUIScript:queryStart];
    UIScriptParser *parseEnd = [[UIScriptParser alloc] initWithUIScript:queryEnd];
    [parseStart parse];
    [parseEnd parse];
    NSMutableArray* views = [NSMutableArray arrayWithCapacity:32];
    for (UIWindow *window in [[UIApplication sharedApplication] windows]) 
    {
        [views addObjectsFromArray:[window subviews]];
    }
    NSArray* resultStart = [parseStart evalWith:views];
    NSArray* resultEnd = [parseEnd evalWith:views];
    if (resultStart == nil || [resultStart count] == 0)
    {
        self.done = YES;
        self.jsonResponse = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSString stringWithFormat: @"start %@ found no views. Is accessibility enabled?",queryStart],@"reason",
                             @"",@"details",
                             @"FAILURE",@"outcome",
                             nil];
        self.events = nil;
        [self.conn responseHasAvailableData:self];
        return;
    }
    id startAt = [resultStart objectAtIndex:0];

    if (resultEnd == nil || [resultEnd count] == 0)
    {
        self.done = YES;
        self.jsonResponse = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSString stringWithFormat: @"end %@ found no views. Is accessibility enabled?",queryEnd],@"reason",
                             @"",@"details",
                             @"FAILURE",@"outcome",
                             nil];
        self.events = nil;
        [self.conn responseHasAvailableData:self];
        return;
    }
    id endAt = [resultEnd objectAtIndex:0];

    CGPoint centerStart;
    if ([startAt isKindOfClass:[UIView class]]) 
    {
       centerStart = [LPTouchUtils centerOfView:startAt];         
    }    
    else                
    {        
       CGPointMakeWithDictionaryRepresentation((CFDictionaryRef)[startAt valueForKey:@"center"], &centerStart);
    }
    centerStart = CGPointMake(centerStart.x + offsetPointStart.x, centerStart.y + offsetPointStart.y);
            
        
    CGPoint centerEnd;
    if ([endAt isKindOfClass:[UIView class]]) 
    {
        centerEnd = [LPTouchUtils centerOfView:endAt];                
    }
    else                
    {
        
        CGPointMakeWithDictionaryRepresentation((CFDictionaryRef)[startAt valueForKey:@"center"], &centerEnd);
    }
    centerEnd = CGPointMake(centerEnd.x + offsetPointEnd.x, centerEnd.y + offsetPointEnd.y);
    
            
    NSArray* baseEvents = [LPResources eventsFromEncoding:base64Events];
            
    targetView = endAt;
    self.events = [LPResources interpolateEvents:baseEvents 
                                       fromPoint:centerStart
                                         toPoint:centerEnd];
    
    //NSLog(@"PLAY Events:\n%@",self.events);    
    
    [self play:self.events];
    NSArray *resultArray = nil;
    if (targetView == nil) {
        resultArray = [NSArray array];
    } else {
        resultArray = [NSArray arrayWithObject:targetView];
    }
    
    self.jsonResponse = [NSDictionary dictionaryWithObjectsAndKeys:
                         resultArray, @"results",
                         @"SUCCESS",@"outcome",
                         nil];
    
    
}




- (void) play:(NSArray *)events 
{
    [[LPRecorder sharedRecorder] load: self.events];
    [[LPRecorder sharedRecorder] playbackWithDelegate: self doneSelector: @selector(playbackDone:)];    
}

//When this event occurs, jsonResponse has already been determined.
-(void) playbackDone:(NSDictionary *)details 
{
    self.done = YES;
    self.events = nil;
    [self.conn responseHasAvailableData:self];
}

-(void) dealloc 
{
    self.events = nil;
    [super dealloc];
}

@end
