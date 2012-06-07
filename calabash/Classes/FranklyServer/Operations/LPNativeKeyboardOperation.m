
//
//  TouchDoneNextOperation.m
//  Created by Karl Krukow on 21/08/11.
//  Copyright (c) 2011 LessPainful. All rights reserved.

#import "LPNativeKeyboardOperation.h"
#import "UIScriptParser.h"
#import "LPRecorder.h"
#import "LPResources.h"
#import "LPTouchUtils.h"

@implementation LPNativeKeyboardOperation
- (NSString *) description {
	return [NSString stringWithFormat:@"Touch keyboard"];
}

//cf KIF: https://github.com/square/KIF/blob/master/Classes/KIFTestStep.m
+ (NSString *)_representedKeyboardStringForCharacter:(NSString *)characterString;
{
    // Interpret control characters appropriately
    if ([characterString isEqual:@"\b"]) {
        characterString = @"Delete";
    } 
    
    return characterString;
}


-(id)performWithTarget:(UIView *)view error:(NSError **)error
{
    if ([_arguments count] == 1)
    {
        //support touch done for backwards compat
        return [self touchDone];
    }
    NSString *characterString = [_arguments objectAtIndex:1];
    for (UIWindow *window in [UIApplication sharedApplication].windows) {
        if ([NSStringFromClass([window class]) isEqual:@"UITextEffectsWindow"]) {
            view = window;
            break;
        }
    }
    
    
    UIScriptParser *parser = [[UIScriptParser alloc] initWithUIScript:@"view:'UIKBKeyplaneView'"];
    [parser parse];
    NSMutableArray* views = [NSMutableArray arrayWithObject:view];
    NSArray* result = [parser evalWith:views];
    

    //cf KIF: https://github.com/square/KIF/blob/master/Classes/KIFTestStep.m
    UIView *keyboardView = [result objectAtIndex:0];
    NSMutableDictionary *history = [NSMutableDictionary dictionaryWithCapacity:128];
    
    // If we didn't find the standard keyboard view, then we may have a custom keyboard
    
    id /*UIKBKeyplane*/ keyplane = [keyboardView valueForKey:@"keyplane"];
    BOOL isShiftKeyplane = [[keyplane valueForKey:@"isShiftKeyplane"] boolValue];
    
    NSMutableArray *unvisitedForKeyplane = [history objectForKey:[NSValue valueWithNonretainedObject:keyplane]];
    if (!unvisitedForKeyplane) {
        unvisitedForKeyplane = [NSMutableArray arrayWithObjects:@"More", @"International", nil];
        if (!isShiftKeyplane) {
            [unvisitedForKeyplane insertObject:@"Shift" atIndex:0];
        }
        [history setObject:unvisitedForKeyplane forKey:[NSValue valueWithNonretainedObject:keyplane]];
    }
    
    NSArray *keys = [keyplane valueForKey:@"keys"];
    
    // Interpret control characters appropriately
    characterString = [[self class] _representedKeyboardStringForCharacter:characterString];
    
    id keyToTap = nil;
    id modifierKey = nil;
    NSString *selectedModifierRepresentedString = nil;
    
    while (YES) {
        for (id/*UIKBKey*/ key in keys) {
            NSString *representedString = [key valueForKey:@"representedString"];
            // Find the key based on the key's represented string
            if ([representedString isEqual:characterString]) {
                keyToTap = key;
            }
            
            if (!modifierKey && unvisitedForKeyplane.count && [[unvisitedForKeyplane objectAtIndex:0] isEqual:representedString]) {
                modifierKey = key;
                selectedModifierRepresentedString = representedString;
                [unvisitedForKeyplane removeObjectAtIndex:0];
            }
        }
        
        if (keyToTap) {
            break;
        }
        
        if (modifierKey) {
            break;
        }
        
        if (!unvisitedForKeyplane.count) {
            return NO;
        }
        
        // If we didn't find the key or the modifier, then this modifier must not exist on this keyboard. Remove it.
        [unvisitedForKeyplane removeObjectAtIndex:0];
    }
    
    if (keyToTap) {
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

        _events =  [[LPResources transformEvents: [LPResources eventsFromEncoding:[_arguments objectAtIndex:0]]  
                                         toPoint:point] retain];
        [self play:_events];
        
        
        NSLog(@"Point: %@",NSStringFromCGPoint(point));   
        return keyboardView;
    }
    return nil;
}


- (id) touchDone {
    UIScriptParser* p=[[UIScriptParser alloc]initWithUIScript:@"view:'UIKBKeyView'"];
    [p parse];
    NSMutableArray* views = [NSMutableArray arrayWithCapacity:32];
    for (UIWindow *window in [[UIApplication sharedApplication] windows]) 
    {
        [views addObjectsFromArray:[window subviews]];
    }
    NSArray* result = [p evalWith:views];

    NSUInteger index=-1;
    NSUInteger maxPointIndex=-1;
    CGPoint maxPoint = CGPointZero;
    for (UIView* view in result) {
        index++;
        CGPoint vp = CGPointMake(view.frame.origin.x + view.frame.size.width, view.frame.origin.y + view.frame.size.height);
        
        if (vp.x >= maxPoint.x && vp.y >= maxPoint.y) {
            maxPoint = vp;
            maxPointIndex = index;
        }
    }
    
    UIView* theView = [result objectAtIndex:maxPointIndex];

    _events =  [[LPResources transformEvents: [LPResources eventsFromEncoding:[_arguments objectAtIndex:0]]  
                            toPoint:[LPTouchUtils centerOfView: theView ]] retain];
    [self play:_events];
        
	return theView;
}

-(void) play:(NSArray *)events {
    _done = NO;
    [[LPRecorder sharedRecorder] load: _events];
    [[LPRecorder sharedRecorder] playbackWithDelegate: self doneSelector: @selector(playbackDone:)];

}

//-(void) waitUntilPlaybackDone {
//    while(!_done) {
//        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 3, false);
//    }
//}

-(void) playbackDone:(NSDictionary *)details {
    _done = YES;
    [_events release];
    _events=nil;
}
@end
