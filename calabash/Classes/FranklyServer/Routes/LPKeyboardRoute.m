//
//  LPKeyboardRoute.m
//  calabash
//
//  Created by Karl Krukow on 29/01/12.
//  Copyright (c) 2012 LessPainful. All rights reserved.
//

#import "LPKeyboardRoute.h"
#import "LPHTTPResponse.h"
#import "LPHTTPConnection.h"
#import "LPResources.h"
#import "LPRecorder.h"
#import "UIScriptParser.h"
#import "LPTouchUtils.h"
#import "LPJSONUtils.h"
#import <QuartzCore/QuartzCore.h>


@implementation LPKeyboardRoute

-(void)beginOperation
{
    _events = nil;
    _playbackDone = NO;
    NSString *characterString = [self.data objectForKey:@"key"];
    NSArray *events = [LPResources eventsFromEncoding:[self.data objectForKey:@"events"]]; 
    UIView *view = nil;
    NSLog(@"Preparing to enter: %@",characterString);
    for (UIWindow *window in [UIApplication sharedApplication].windows) 
    {
        if ([NSStringFromClass([window class]) isEqual:@"UITextEffectsWindow"]) 
        {
            view = window;
            break;
        }
    }
    
    NSLog(@"Target window: %@",view);
    
    if (!view) 
    {
        _playbackDone = YES;
        return [self failWithMessageFormat:@"No keyboard displaying..." message:nil];
    }
    
    UIScriptParser *parser = [[UIScriptParser alloc] initWithUIScript:@"view:'UIKBKeyplaneView'"];
    [parser parse];
        
    NSMutableArray* views = [NSMutableArray arrayWithObject:view];
    NSArray* result = [parser evalWith:views];
    
    if ([result count]==0) 
    {
        _playbackDone = YES;
        return [self failWithMessageFormat:@"Found not UIKBKeyplaneView..." message:nil];        
    }
    NSLog(@"Target KBKeyplane: %@",view);
    
    
    //cf KIF: https://github.com/square/KIF/blob/master/Classes/KIFTestStep.m
    UIView *keyboardView = [result objectAtIndex:0];
    
    // If we didn't find the standard keyboard view, then we may have a custom keyboard
    
    id /*UIKBKeyplane*/ keyplane = [keyboardView valueForKey:@"keyplane"];
    NSArray *keys = [keyplane valueForKey:@"keys"];
    
    id keyToTap = nil;
    
    for (id/*UIKBKey*/ key in keys) {
        NSString *representedString = [key valueForKey:@"representedString"];
        // Find the key based on the key's represented string
        if ([representedString isEqual:characterString]) 
        {
            NSLog(@"Target key: %@",key);
            keyToTap = key;
        }
        
        if ([representedString length]>0)
        {
            
            if ([characterString isEqualToString:@"Return"] && [representedString characterAtIndex:0]==(unichar)10)
            {
                keyToTap = key;
            }
        }
    }             
    
    if (keyToTap) 
    {
        UIScriptParser *parser = [[UIScriptParser alloc] initWithUIScript:@"view:'UIKeyboardAutomatic'"];
        [parser parse];
        NSMutableArray* views = [NSMutableArray arrayWithObject:view];
        NSArray* result = [parser evalWith:views];
        UIView *v = [result objectAtIndex:0];
        
        UIView *sup = [v superview];
        
        CGRect parentFrame = [sup convertRect:v.frame toView:nil];//[sup convertRect:v.frame toView:sup];
        
        CGRect frame = [keyToTap frame];
        CGPoint point = CGPointMake(parentFrame.origin.x + frame.origin.x + 0.5 * frame.size.width,
                                    parentFrame.origin.y + frame.origin.y + 0.5 * frame.size.height);
        
        point = [(UIWindow*)view convertPoint:point toWindow:nil];
        point=[LPTouchUtils translateToScreenCoords:point];
        _events =  [[LPResources transformEvents:events toPoint:point] retain];
        self.done = YES;
        self.jsonResponse = [NSDictionary dictionaryWithObjectsAndKeys:
                             result, @"results",
                             @"SUCCESS",@"outcome",
                             nil];

        [self play:_events];
                
    }
    else 
    {
        _playbackDone = YES;
        [self failWithMessageFormat:@"Found no key: %@" message:characterString];        
    }

}

-(void) play:(NSArray *)events {
    _playbackDone = NO;
    [[LPRecorder sharedRecorder] load: _events];
    [[LPRecorder sharedRecorder] playbackWithDelegate: self doneSelector: @selector(playbackDone:)];
    
}

//-(void) waitUntilPlaybackDone {
//    while(!_done) {
//        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 3, false);
//    }
//}

-(void) playbackDone:(NSDictionary *)details {
    _playbackDone = YES;
    [_events release];
    _events=nil;
    [self.conn responseHasAvailableData:self];

}

// Should only return YES after the LPHTTPConnection has read all available data.
- (BOOL)isDone 
{
    return _playbackDone && [super isDone];
}



@end
