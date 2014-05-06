//
//  LPInterpolateRoute.m
//  LPSimpleExample
//
//  Created by Karl Krukow on 14/03/12.
//  Copyright (c) 2012 LessPainful. All rights reserved.
//

#import "LPAsyncPlaybackRoute.h"
#import "LPHTTPConnection.h"
#import "LPResources.h"
#import "LPRecorder.h"
#import "UIScriptParser.h"
#import "LPTouchUtils.h"
#import "LPInterpolateRoute.h"


@implementation LPInterpolateRoute

@synthesize events = _events;
@synthesize parser1;
@synthesize parser2;


// Should only return YES after the LPHTTPConnection has read all available data.
- (BOOL) isDone {
  return !self.events && [super isDone];
}


- (void) beginOperation {
  self.done = NO;
  NSString *base64Events = [self.data objectForKey:@"events"];
  id queryStart = [self.data objectForKey:@"start"];
  id queryEnd = [self.data objectForKey:@"end"];

  NSDictionary *offset_start = [self.data valueForKey:@"offset_start"];
  NSNumber *off_start_x = [offset_start valueForKey:@"x"];
  NSNumber *off_start_y = [offset_start valueForKey:@"y"];

  CGPoint offsetPointStart = CGPointMake([off_start_x floatValue],
          [off_start_y floatValue]);

  NSDictionary *offset_end = [self.data valueForKey:@"offset_end"];
  NSNumber *off_end_x = [offset_end valueForKey:@"x"];
  NSNumber *off_end_y = [offset_end valueForKey:@"y"];

  CGPoint offsetPointEnd = CGPointMake([off_end_x floatValue],
          [off_end_y floatValue]);

  UIView *targetView = nil;
  self.parser1 = [UIScriptParser scriptParserWithObject:queryStart];
  self.parser2 = [UIScriptParser scriptParserWithObject:queryEnd];
  [self.parser1 parse];
  [self.parser2 parse];
  NSMutableArray *views = [NSMutableArray arrayWithCapacity:32];
  for (UIWindow *window in [LPTouchUtils applicationWindows]) {
    [views addObject:window];
  }
  NSArray *resultStart = [self.parser1 evalWith:views];
  NSArray *resultEnd = [self.parser2 evalWith:views];

  CGPoint centerStart;
  if (resultStart == nil || [resultStart count] == 0) {
    centerStart = CGPointMake(0, 0);
  } else {
    id startAt = [resultStart objectAtIndex:0];
    if ([startAt isKindOfClass:[UIView class]]) {
      centerStart = [LPTouchUtils centerOfView:startAt];
    } else {
      CGPointMakeWithDictionaryRepresentation(
              (CFDictionaryRef) [startAt valueForKey:@"center"], &centerStart);
    }
  }
  centerStart = CGPointMake(centerStart.x + offsetPointStart.x,
          centerStart.y + offsetPointStart.y);


  CGPoint centerEnd;
  if (resultEnd == nil || [resultEnd count] == 0) {
    centerEnd = CGPointMake(0, 0);
  } else {
    id endAt = [resultEnd objectAtIndex:0];
    targetView = endAt;
    if ([endAt isKindOfClass:[UIView class]]) {
      centerEnd = [LPTouchUtils centerOfView:endAt];
    } else {
      CGPointMakeWithDictionaryRepresentation(
              (CFDictionaryRef) [endAt valueForKey:@"center"], &centerEnd);
    }
  }

  centerEnd = CGPointMake(centerEnd.x + offsetPointEnd.x,
          centerEnd.y + offsetPointEnd.y);


  NSArray *baseEvents = [LPResources eventsFromEncoding:base64Events];


  self.events = [LPResources interpolateEvents:baseEvents fromPoint:centerStart
                                       toPoint:centerEnd];

  //NSLog(@"PLAY Events:\n%@",self.events);

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
  [[LPRecorder sharedRecorder] load:self.events];
  [[LPRecorder sharedRecorder]
          playbackWithDelegate:self doneSelector:@selector(playbackDone:)];
}


//When this event occurs, jsonResponse has already been determined.
- (void) playbackDone:(NSDictionary *) details {
  self.done = YES;
  self.events = nil;
  self.parser1 = nil;
  self.parser2 = nil;
  [self.conn responseHasAvailableData:self];
}


- (void) dealloc {
  self.parser1 = nil;
  self.parser2 = nil;
  self.events = nil;
  [super dealloc];
}

@end
