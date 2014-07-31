//
//  LPUIAChannel.h
//
//  Created by Karl Krukow on 11/16/13.
//  Copyright (c) 2013 Xamarin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LPUIAUserPrefsChannel : NSObject

+ (LPUIAUserPrefsChannel *) sharedChannel;

+ (void) runAutomationCommand:(NSString *) command then:(void (^)(NSDictionary *result)) resultHandler;

- (void) runAutomationCommand:(NSString *) command then:(void (^)(NSDictionary *result)) resultHandler;

@end
