//
//  LPKeyboardRoute.m
//  calabash
//
//  Created by Karl Krukow on 29/01/12.
//  Copyright (c) 2012 LessPainful. All rights reserved.
//

#import "LPKeyboardRoute.h"
#import "LPHTTPConnection.h"
#import "LPResources.h"
#import "LPRecorder.h"
#import "UIScriptParser.h"
#import "LPTouchUtils.h"

// todo missing dealloc method and _events ivar is not released
@implementation LPKeyboardRoute

- (void) beginOperation {
  _events = nil;
  _playbackDone = NO;
  NSString *characterString = [self.data objectForKey:@"key"];

  NSArray *events = [LPResources eventsFromEncoding:[self.data objectForKey:@"events"]];
  UIWindow *keyboardWindow = nil;

  for (UIWindow *window in [LPTouchUtils applicationWindows]) {
    if ([NSStringFromClass([window class]) isEqual:@"UITextEffectsWindow"]) {
      keyboardWindow = window;
      break;
    }
  }

  if (!keyboardWindow) {
    _playbackDone = YES;
    return [self failWithMessageFormat:@"No keyboard displaying..."
                               message:nil];
  }


  UIView *keyboardView = [UIScriptParser findViewByClass:@"UIKBKeyplaneView"
                                                fromView:keyboardWindow];


  if (!keyboardView) {
    _playbackDone = YES;
    return [self failWithMessageFormat:@"Found not UIKBKeyplaneView..."
                               message:nil];
  }



  //cf KIF: https://github.com/square/KIF/blob/master/Classes/KIFTestStep.m

  // If we didn't find the standard keyboard view, then we may have a custom keyboard

  id /*UIKBKeyplane*/ keyplane = [keyboardView valueForKey:@"keyplane"];
  NSArray *keys = [keyplane valueForKey:@"keys"];

  id keyToTap = nil;

  for (id/*UIKBKey*/ key in keys) {
    NSString *representedString = [key valueForKey:@"representedString"];
    // Find the key based on the key's represented string
    if ([representedString isEqual:characterString]) {
      keyToTap = key;
    }

    if ([representedString length] > 0) {

      if ([characterString isEqualToString:@"Return"] && [representedString characterAtIndex:0] == (unichar) 10) {
        keyToTap = key;
      }
    }
  }

  if (keyToTap) {
    UIView *v = [UIScriptParser findViewByClass:@"UIKeyboardAutomatic"
                                       fromView:keyboardWindow];
    UIView *sup = [v superview];

    CGRect parentFrame = [sup convertRect:v.frame
                                   toView:nil];//[sup convertRect:v.frame toView:sup];

    CGRect frame = [keyToTap frame];
    CGPoint point = CGPointMake(
            parentFrame.origin.x + frame.origin.x + 0.5 * frame.size.width,
            parentFrame.origin.y + frame.origin.y + 0.5 * frame.size.height);

    point = [(UIWindow *) keyboardWindow convertPoint:point toWindow:nil];
    point = [LPTouchUtils translateToScreenCoords:point];
    _events = [[LPResources transformEvents:events toPoint:point] retain];
    self.done = YES;
    self.jsonResponse = [NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObject:v], @"results",
                                                                   @"SUCCESS", @"outcome",
                                                                   nil];

    [self play:_events];
  } else {
    _playbackDone = YES;
    [self failWithMessageFormat:@"Found no key: %@" message:characterString];
  }
}


- (void) play:(NSArray *) events {
  _playbackDone = NO;
  [[LPRecorder sharedRecorder] load:_events];
  [[LPRecorder sharedRecorder]
          playbackWithDelegate:self doneSelector:@selector(playbackDone:)];
}

//-(void) waitUntilPlaybackDone {
//    while(!_done) {
//        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 3, false);
//    }
//}

- (void) playbackDone:(NSDictionary *) details {
  _playbackDone = YES;
  [_events release];
  _events = nil;
  [self.conn responseHasAvailableData:self];
}


// Should only return YES after the LPHTTPConnection has read all available data.
- (BOOL) isDone {
  return _playbackDone && [super isDone];
}


@end
