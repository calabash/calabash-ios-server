//
//  LPUIARouteOverSharedElement.m
//  calabash
//
//  Created by Karl Krukow on 11/23/14.
//  Copyright (c) 2014 Xamarin. All rights reserved.
//

#import "LPUIARouteOverSharedElement.h"
#import "LPUIASharedElementChannel.h"
#import "LPJSONUtils.h"

@implementation LPUIARouteOverSharedElement

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
                                 URI:[path componentsJoinedByString:@"/"]];
#pragma clang diagnostic push
}

- (BOOL) canHandlePostForPath: (NSArray *)path {
  return [@"uia" isEqualToString:[path lastObject]];
}

- (void) beginOperation {
  self.done = NO;

  NSString *command = [self.data objectForKey:@"command"];
  [LPUIASharedElementChannel runAutomationCommand:command then:^(NSDictionary *result) {
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
