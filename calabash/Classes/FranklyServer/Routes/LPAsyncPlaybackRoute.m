//
//  LPAsyncPlaybackRoute.m
//  calabash
//
//  Created by Karl Krukow on 29/01/12.
//  Copyright (c) 2012 LessPainful. All rights reserved.
//

#import "LPAsyncPlaybackRoute.h"
#import "HTTPResponse.h"
#import "HTTPConnection.h"
#import "LPResources.h"
#import "LPRecorder.h"
#import "UIScriptParser.h"
#import "LPTouchUtils.h"
#import "LPJSONUtils.h"
#import "LPOperation.h"


@implementation LPAsyncPlaybackRoute
{
    dispatch_queue_t queue;
}
@synthesize events=_events;
@synthesize parser=_parser;

- (BOOL)isDone 
{
    return !self.events && [super isDone];
}
- (BOOL) canHandlePostForPath: (NSArray *)path
{
    return [path containsObject:@"play"];
}


-(BOOL)matchesPath:(NSArray *)path
{
    return [path containsObject:@"play"];
}

-(void) beginOperation 
{
        self.done = NO;
        NSString *base64Events = [self.data objectForKey:@"events"];
        id query = [self.data objectForKey:@"query"];
        UIView *targetView = nil;
        if (query != nil) {
            __block NSArray* result;
            dispatch_sync(dispatch_get_main_queue(), ^{
                result = [[LPOperation performQuery:query] retain];
            });
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
                
                
                NSArray* baseEvents = [LPResources eventsFromEncoding:base64Events];
                
                targetView = v;
                self.events = [LPResources transformEvents:baseEvents
                                                   toPoint:CGPointMake(center.x+offsetPoint.x, center.y+offsetPoint.y)];
                
                
                
                
                [result release];
                
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

    queue = dispatch_get_current_queue();
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[LPRecorder sharedRecorder] load: self.events];
        [[LPRecorder sharedRecorder] playbackWithDelegate: self doneSelector: @selector(playbackDone:)];
        
    });
    
}

//When this event occurs, jsonResponse has already been determined.
-(void) playbackDone:(NSDictionary *)details 
{
    dispatch_async(queue, ^{
        self.done = YES;
        self.events = nil;
        self.parser = nil;
        [self.conn responseHasAvailableData:self];

    });
}


-(void) dealloc 
{
    self.events = nil;
    self.parser = nil;    
    [super dealloc];
}

@end

