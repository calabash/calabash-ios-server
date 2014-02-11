//
//  LPEnv.m
//  calabash
//
//  Created by Karl Krukow on 1/30/14.
//  Copyright (c) 2014 Xamarin. All rights reserved.
//

#import "LPEnv.h"


@implementation LPEnv {
  NSDictionary *_env;
}
+ (LPEnv *) sharedEnv {
  static LPEnv *sharedEnv = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedEnv = [[LPEnv alloc] init];
  });
  return sharedEnv;
}


- (id) init {
  self = [super init];
  if (self) {
    _env = [[[NSProcessInfo processInfo] environment] retain];
  }
  return self;
}


// TODO LPEnv.m [super dealloc] must be called _last_
- (void) dealloc {
  [super dealloc];
  [_env release];
}


- (BOOL) isSet:(NSString *) key {
  return [_env valueForKey:key] != nil;
}


- (id) valueForKey:(NSString *) key {
  return [_env valueForKey:key];
}


+ (BOOL) calabashDebugEnabled {
  NSString *debugVal = [[LPEnv sharedEnv] valueForKey:@"CALABASH_DEBUG"];
  return debugVal && ![debugVal isEqualToString:@"0"];
}

@end
