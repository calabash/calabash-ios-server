//
//  LPSharedUIATextField.h
//  LPSimpleExample
//
//  Created by Karl Krukow on 23/11/14.
//  Copyright (c) 2014 Xamarin. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol LPUIAResponseReceiver;

@interface LPSharedUIATextField : UITextField

@property(atomic, retain) NSDictionary *currentMessage;
@property(atomic, assign) BOOL isSynchronized;


+ (LPSharedUIATextField *) sharedTextField;

-(void)synchronizeWithUIAutomation;
-(void)setUIADelegate:(id<LPUIAResponseReceiver>)uiaDelegate;

@end

@protocol LPUIAResponseReceiver

-(void)sharedUIATextField:(LPSharedUIATextField*) uiaTextField didReceiveUIAResponse:(NSDictionary*)uiaResponse;

@end
