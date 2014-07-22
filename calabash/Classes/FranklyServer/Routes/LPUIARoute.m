//
//  LPUIARoute.m
//  calabash
//
//  Created by Karl Krukow on 08/04/12.
//  Copyright (c) 2013 Xamarin. All rights reserved.
//

#import "LPUIARoute.h"
#import "LPUIAChannel.h"
#import "LPJSONUtils.h"

@implementation LPUIARoute

- (BOOL) supportsMethod:(NSString *) method atPath:(NSString *) path {
  return [method isEqualToString:@"POST"];
}

- (id) handleRequestForPath: (NSArray *)path withConnection:(id)connection {
  if (![self canHandlePostForPath:path]) {
    return nil;
  }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-method-access"
  self.conn = connection;
  self.data = [LPJSONUtils deserializeDictionary:[connection postDataAsString]];
  return [self httpResponseForMethod:@"POST"
        URI:  [path componentsJoinedByString:@"/"]];
#pragma clang diagnostic push
}
- (BOOL) canHandlePostForPath: (NSArray *)path {
 return [@"uia" isEqualToString:[path lastObject]];
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
