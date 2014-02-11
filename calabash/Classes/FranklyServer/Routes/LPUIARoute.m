//
//  LPUIARoute.m
//  calabash
//
//  Created by Karl Krukow on 08/04/12.
//  Copyright (c) 2013 Xamarin. All rights reserved.
//

#import "LPUIARoute.h"
#import "LPUIAChannel.h"

@implementation LPUIARoute

- (BOOL) supportsMethod:(NSString *) method atPath:(NSString *) path {
  return [method isEqualToString:@"POST"];
}


- (void) beginOperation {
  self.done = NO;

  NSString *command = [self.data objectForKey:@"command"];
  [LPUIAChannel runAutomationCommand:command then:^(NSDictionary *result) {
    if (!result) {
      [self failWithMessageFormat:@"Timed out running command %@"
                          message:command];
    } else {
      [self succeedWithResult:[NSArray arrayWithObject:[[result copy]
              autorelease]]];
    }
  }];
}

@end
