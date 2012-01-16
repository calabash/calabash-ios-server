//
//  PlaybackRoute.m
//  Created by Karl Krukow on 18/08/11.
//  Copyright (c) 2011 LessPainful. All rights reserved.
//

#import "LPPlaybackRoute.h"
#import "LPResources.h"
#import "LPRecorder.h"
#import "UIScriptParser.h"
#import "LPTouchUtils.h"
@implementation LPPlaybackRoute
@synthesize events=_events;
@synthesize done=_done;

- (BOOL)supportsMethod:(NSString *)method atPath:(NSString *)path {
    return [method isEqualToString:@"POST"];
}
- (NSDictionary *)JSONResponseForMethod:(NSString *)method URI:(NSString *)path data:(NSDictionary*)data {
    self.done = NO;
    NSString *base64Events = [data objectForKey:@"events"];
    NSString *query = [data objectForKey:@"query"];
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
            UIView* v = [result objectAtIndex:0];//autopick first
            NSDictionary *offset = [data valueForKey:@"offset"];
            NSNumber *x = [offset valueForKey:@"x"];
            NSNumber *y = [offset valueForKey:@"y"];
            
            CGPoint offsetPoint = CGPointMake([x floatValue], [y floatValue]);
            
            CGPoint center = [LPTouchUtils centerOfView:v];
            NSArray* baseEvents = [LPResources eventsFromEncoding:base64Events];
            
            targetView = v;
            self.events = [LPResources transformEvents:baseEvents 
                                          toPoint:CGPointMake(center.x+offsetPoint.x, center.y+offsetPoint.y)];
            

            


        } else {
            NSLog(@"query %@ found no views. NO-OP.",query);
            return [NSDictionary dictionaryWithObjectsAndKeys:
                    [NSString stringWithFormat: @"query %@ found no views. Is accessibility enabled?",query],@"reason",
                    @"",@"details",
                    @"FAILURE",@"outcome",
                    nil];
        }
        

    } else {
        self.events = [LPResources eventsFromEncoding:base64Events];
    }
    
    if ([data objectForKey:@"reverse"]) {
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
    
    NSLog(@"SOURCE Events\n%@",self.events);
    NSLog(@"----------");
    NSString *base64Prototype = [data objectForKey:@"prototype"];
    if (base64Prototype) {
        NSArray* protoEvents = [LPResources eventsFromEncoding:base64Prototype];
       
        NSLog(@"Prototype Events\n%@",protoEvents);
        
        
    }
    
    [self play:self.events];
    NSArray *resultArray = nil;
    if (targetView == nil) {
        resultArray = [NSArray array];
    } else {
        resultArray = [NSArray arrayWithObject:targetView];
    }
    
    return [NSDictionary dictionaryWithObjectsAndKeys:
                resultArray, @"results",
                @"SUCCESS",@"outcome",
            nil];
                              
}
-(void) play:(NSArray *)events {
    _done = NO;
    [[LPRecorder sharedRecorder] load: self.events];
    [[LPRecorder sharedRecorder] playbackWithDelegate: self doneSelector: @selector(playbackDone:)];
//    [self waitUntilPlaybackDone];
}
     
//-(void) waitUntilPlaybackDone {
//    while(!_done) {
//        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 3, false);
//    }
//}
     
-(void) playbackDone:(NSDictionary *)details {
    _done = YES;
    self.events=nil;
}
     


@end
