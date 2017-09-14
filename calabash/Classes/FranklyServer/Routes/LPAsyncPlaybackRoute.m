//
//  LPAsyncPlaybackRoute.m
//  calabash
//
//  Created by Karl Krukow on 29/01/12.
//  Copyright (c) 2012 LessPainful. All rights reserved.
//

#import "LPAsyncPlaybackRoute.h"
#import "LPHTTPConnection.h"
#import "LPQUResources.h"
#import "LPRecorder.h"
#import "LPTouchUtils.h"
#import "LPOperation.h"
#import "UIAutomation.h"
#import "LPCocoaLumberjack.h"

@class UIDevice;

@implementation LPAsyncPlaybackRoute
@synthesize events = _events;


- (BOOL) isDone {
  return !self.events && [super isDone];
}


- (void) beginOperation {
  self.done = NO;
  NSString *base64Events = [self.data objectForKey:@"events"];
  id query = [self.data objectForKey:@"query"];
  UIView *targetView = nil;
  if (query != nil) {
    NSArray *result = [LPOperation performQuery:query];


    if ([result count] > 0) {
      id v = [result objectAtIndex:0];//autopick first?

      NSDictionary *offset = [self.data valueForKey:@"offset"];
      NSNumber *x = [offset valueForKey:@"x"];
      NSNumber *y = [offset valueForKey:@"y"];

      CGPoint offsetPoint = CGPointMake([x floatValue], [y floatValue]);

      CGPoint center;
      if ([v isKindOfClass:[UIView class]]) {
        center = [LPTouchUtils centerOfView:v];
      } else {

        CGPointMakeWithDictionaryRepresentation(
                (CFDictionaryRef) [v valueForKey:@"center"], &center);
      }

      targetView = v;

      NSArray *baseEvents = [LPQUResources eventsFromEncoding:base64Events];


      self.events = [LPQUResources transformEvents:baseEvents toPoint:CGPointMake(
              center.x + offsetPoint.x, center.y + offsetPoint.y)];
    } else {
      LPLogDebug(@"query %@ found no views. NO-OP.", query);
      self.done = YES;
      self.jsonResponse = [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"query %@ found no views. Is accessibility enabled?",
                                                                                                query], @"reason",
                                                                     @"", @"details",
                                                                     @"FAILURE", @"outcome",
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
    self.events = [LPQUResources eventsFromEncoding:base64Events];
    if (!self.events || [self.events count] < 1) {
      LPLogDebug(@"BAD EVENTS: %@", base64Events);
      self.done = YES;
      self.jsonResponse = [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"Bad events %@",
                                                                                                base64Events], @"reason",
                                                                     @"", @"details",
                                                                     @"FAILURE", @"outcome",
                                                                     nil];
      return;
    }
    if (offset) {
      NSDictionary *firstEvent = [self.events objectAtIndex:0];
      NSDictionary *windowLoc = [firstEvent valueForKey:@"WindowLocation"];
      if (windowLoc == nil || [[firstEvent valueForKey:@"Type"]
              integerValue] == 50) {
        LPLogDebug(@"Offset for non window located event: %@", firstEvent);
        self.done = YES;
        self.jsonResponse = [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"Offset for non window located event: %@",
                                                                                                  firstEvent], @"reason",
                                                                       @"", @"details",
                                                                       @"FAILURE", @"outcome",
                                                                       nil];
        return;
      }

      NSArray *transformed = [LPQUResources transformEvents:self.events
                                                  toPoint:CGPointMake(
                                                          offsetPoint.x,
                                                          offsetPoint.y)];
      if ([transformed count] == [self.events count]) {
        self.events = transformed;
      }
    }
  }

  if ([self.data objectForKey:@"reverse"]) {
    self.events = [[_events reverseObjectEnumerator] allObjects];
  }
  //LPLogDebug(@"PLAY Events:\n%@",self.events);
  NSDictionary *firstEvent = [self.events objectAtIndex:0];
  NSDictionary *windowLoc = [firstEvent valueForKey:@"WindowLocation"];

  if (!targetView && windowLoc != nil) {
    CGPoint touchPoint = CGPointMake([[windowLoc valueForKey:@"X"] floatValue],
            [[windowLoc valueForKey:@"Y"] floatValue]);
    for (UIWindow *window in [LPTouchUtils applicationWindows]) {
      if (![window respondsToSelector:@selector(screen)] || [window screen] == [UIScreen mainScreen]) {
        targetView = [window hitTest:touchPoint withEvent:nil];
        break;
      }
    }
  }


//    NSString *base64Prototype = [self.data objectForKey:@"prototype"];
//    if (base64Prototype) {
//        NSArray* protoEvents = [LPQUResources eventsFromEncoding:base64Prototype];
//
//        LPLogDebug(@"Prototype Events\n%@",protoEvents);
//
//    }

  [self play:self.events];
  NSArray *resultArray = nil;
  if (targetView == nil) {
    resultArray = [NSArray array];
  } else {
    resultArray = [NSArray arrayWithObject:targetView];
  }

  self.jsonResponse = [NSDictionary dictionaryWithObjectsAndKeys:resultArray, @"results",
                                                                 @"SUCCESS", @"outcome",
                                                                 nil];
}


- (void) play:(NSArray *) events {
  LPRecorder *recorder = [LPRecorder sharedRecorder];
  [recorder load:self.events];
  [recorder playbackWithCallbackDelegate:self
                            doneSelector:@selector(playbackDone:)];
}


//When this event occurs, jsonResponse has already been determined.
- (void) playbackDone:(NSDictionary *) details {
  self.done = YES;
  self.events = nil;
  [self.conn responseHasAvailableData:self];
}


- (void) dealloc {
  self.events = nil;
  [super dealloc];
}

@end

