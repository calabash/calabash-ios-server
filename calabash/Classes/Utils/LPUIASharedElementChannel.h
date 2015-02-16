//
//  LPUIASharedElementChannel.h
//
//  Created by Karl Krukow on 11/23/14.
//  Copyright (c) 2014 Xamarin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LPSharedUIATextField.h"

typedef void(^UIACommandHandler)(NSDictionary *result);

@interface LPUIASharedElementChannel : NSObject<LPUIAResponseReceiver>
@property (nonatomic, copy) UIACommandHandler currentHandler;

+ (LPUIASharedElementChannel *) sharedChannel;

+ (void) runAutomationCommand:(NSString *) command then:(UIACommandHandler) resultHandler;

- (void) runAutomationCommand:(NSString *) command then:(UIACommandHandler) resultHandler;

@end

