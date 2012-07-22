//
//  LPAsyncPlaybackRoute.m
//  calabash
//
//  Created by Karl Krukow on 29/01/12.
//  Copyright (c) 2012 LessPainful. All rights reserved.
//

#import "LPAsyncPlaybackRoute.h"
#import "LPHTTPResponse.h"
#import "LPHTTPConnection.h"
#import "LPResources.h"
#import "LPRecorder.h"
#import "UIScriptParser.h"
#import "LPTouchUtils.h"
#import "LPJSONUtils.h"


@implementation LPAsyncPlaybackRoute
@synthesize events=_events;

- (BOOL)isDone 
{
    return !self.events && [super isDone];
}



-(void) beginOperation 
{
    self.done = NO;
    NSString *base64Events = [self.data objectForKey:@"events"];
    NSString *query = [self.data objectForKey:@"query"];
    UIView *targetView = nil;
    if (query != nil) {
        UIScriptParser *parser = [[UIScriptParser alloc] initWithUIScript:query];
        [parser parse];
        NSMutableArray* views = [NSMutableArray arrayWithCapacity:32];
        for (UIWindow *window in [[UIApplication sharedApplication] windows]) 
        {
            [views addObjectsFromArray:[window subviews]];
            //        if (![window respondsToSelector:@selector(screen)] || [window screen] == [UIScreen mainScreen]) {
            //            break;
            //        }
        }
        NSArray* result = [parser evalWith:views];
        
        if ([result count] >0) {
            id v = [result objectAtIndex:0];//autopick first?
            
            NSDictionary *offset = [self.data valueForKey:@"offset"];
            NSNumber *x = [offset valueForKey:@"x"];
            NSNumber *y = [offset valueForKey:@"y"];
            
        
            
            CGPoint offsetPoint = CGPointMake([x floatValue], [y floatValue]);
            
            CGPoint center;
            if ([v isKindOfClass:[UIView class]]) 
            {
                center = [LPTouchUtils centerOfView:v];                
            }
            else                
            {
                
                CGPointMakeWithDictionaryRepresentation((CFDictionaryRef)[v valueForKey:@"center"], &center);
            }

            NSString *centerView = NSStringFromCGPoint(center);
            
            NSLog(@"Center %@", centerView);
            
            id win = v;
            if ([win isKindOfClass:[UIView class]])
            {
                if ([win isKindOfClass:[UIWindow class]])
                {
                    CGPoint newCenter = [win convertPoint:center toWindow:nil];
                    NSLog(@"Window center:%@",NSStringFromCGPoint(newCenter));
                }
                
            }
            

            
            NSArray* baseEvents = [LPResources eventsFromEncoding:base64Events];
            
            targetView = v;
            self.events = [LPResources transformEvents:baseEvents 
                                               toPoint:CGPointMake(center.x+offsetPoint.x, center.y+offsetPoint.y)];
            
            
            
            
            
        } else {
            NSLog(@"query %@ found no views. NO-OP.",query);
            self.done = YES;
            self.jsonResponse = [NSDictionary dictionaryWithObjectsAndKeys:
                    [NSString stringWithFormat: @"query %@ found no views. Is accessibility enabled?",query],@"reason",
                    @"",@"details",
                    @"FAILURE",@"outcome",
                    nil];
            self.events = nil;
            [self.conn responseHasAvailableData:self];
            return;
        }
        
        
    } else {
        NSDictionary *offset = [self.data valueForKey:@"offset"];
        NSNumber *x = [offset valueForKey:@"x"];
        NSNumber *y = [offset valueForKey:@"y"];
        
        CGPoint offsetPoint = CGPointMake([x floatValue], [y floatValue]);
        self.events = [LPResources eventsFromEncoding:base64Events];
        if (!self.events || [self.events count] < 1) {
            NSLog(@"BAD EVENTS: %@", base64Events);
            self.done = YES;
            self.jsonResponse = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSString stringWithFormat: @"Bad events %@",base64Events],@"reason",
                                 @"",@"details",
                                 @"FAILURE",@"outcome",
                                 nil];
            return;


        }
        if (offset)
        {
            NSDictionary *firstEvent = [self.events objectAtIndex:0];
            NSDictionary* windowLoc = [firstEvent valueForKey:@"WindowLocation"];
            if (windowLoc == nil || [[firstEvent valueForKey:@"Type"] integerValue] == 50) {
                NSLog(@"Offset for non window located event: %@", firstEvent);
                self.done = YES;
                self.jsonResponse = [NSDictionary dictionaryWithObjectsAndKeys:
                                     [NSString stringWithFormat: @"Offset for non window located event: %@", firstEvent],@"reason",
                                     @"",@"details",
                                     @"FAILURE",@"outcome",
                                     nil];
                return;
            }
            
            NSArray* transformed = [LPResources transformEvents:self.events 
                                                        toPoint:CGPointMake(offsetPoint.x, offsetPoint.y)];
            if ([transformed count] == [self.events count]) {
                self.events = transformed;
            }
        }
        
    }
    
    if ([self.data objectForKey:@"reverse"]) {
        self.events = [[_events reverseObjectEnumerator] allObjects];
    }
    //NSLog(@"PLAY Events:\n%@",self.events);    
    NSDictionary *firstEvent = [self.events objectAtIndex:0];
    NSDictionary* windowLoc = [firstEvent valueForKey:@"WindowLocation"];
        
    if (!targetView && windowLoc != nil) {
        CGPoint touchPoint = CGPointMake([[windowLoc valueForKey:@"X"] floatValue], 
                                         [[windowLoc valueForKey:@"Y"] floatValue]);
        for (UIWindow *window in [[UIApplication sharedApplication] windows]) {                
           if (![window respondsToSelector:@selector(screen)] || [window screen] == [UIScreen mainScreen]) {
                targetView = [window hitTest:touchPoint withEvent:nil];
                break;
           }
        }
            
    }        
    
    
//    NSString *base64Prototype = [self.data objectForKey:@"prototype"];
//    if (base64Prototype) {
//        NSArray* protoEvents = [LPResources eventsFromEncoding:base64Prototype];
//        
//        NSLog(@"Prototype Events\n%@",protoEvents);
//        
        
//    }
    
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

