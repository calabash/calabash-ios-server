//
//  LPLog.m
//  calabash
//
//  Created by Karl Krukow on 1/30/14.
//  Copyright (c) 2014 Xamarin. All rights reserved.
//

#import "LPLog.h"
#import "LPEnv.h"


@implementation LPLog {
  LPLogLevel _logLevel;
}

+ (LPLog *) sharedLog {
  static LPLog *sharedLog = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedLog = [[LPLog alloc] init];
  });
  return sharedLog;
}


+ (LPLogLevel) currentLevel {
  return [[LPLog sharedLog] currentLevel];
}


+ (void) setLevelFromString:(NSString *) logLevel {
  [[LPLog sharedLog] setLevelFromString:logLevel];
}


- (void) setLevelFromString:(NSString *) logLevel {
  if ([@"debug" isEqualToString:[logLevel lowercaseString]]) {
    _logLevel = LPLogLevelDebug;
  } else if ([@"info" isEqualToString:[logLevel lowercaseString]]) {
    _logLevel = LPLogLevelInfo;
  } else if ([@"error" isEqualToString:[logLevel lowercaseString]]) {
    _logLevel = LPLogLevelError;
  }
}


- (LPLogLevel) currentLevel {
  return _logLevel;
}


+ (NSString *) currentLevelString {
  switch ([LPLog currentLevel]) {
    case LPLogLevelDebug:return @"debug";
    case LPLogLevelInfo:return @"info";
    case LPLogLevelError:return @"error";
    default:return nil;
  }
}


- (id) init {
  self = [super init];
  if (self) {
    _logLevel = [LPEnv calabashDebugEnabled] ? LPLogLevelDebug : LPLogLevelInfo;
  }
  return self;
}


- (BOOL) shouldLogAtLevel:(LPLogLevel) level {
  return (level >= _logLevel);
}


//Not 100% sure if this va_* is necessary
+ (void) debug:(NSString *) formatString, ...; {
  if (![[LPLog sharedLog] shouldLogAtLevel:LPLogLevelDebug]) {return;}
  va_list args;
  va_start(args, formatString);
  NSLogv(formatString, args);
  va_end(args);
}


+ (void) info:(NSString *) formatString, ... {
  if (![[LPLog sharedLog] shouldLogAtLevel:LPLogLevelInfo]) {return;}
  va_list args;
  va_start(args, formatString);
  NSLogv(formatString, args);
  va_end(args);
}


+ (void) error:(NSString *) formatString, ... {
  if (![[LPLog sharedLog] shouldLogAtLevel:LPLogLevelError]) {return;}
  va_list args;
  va_start(args, formatString);
  NSLogv(formatString, args);
  va_end(args);
}

@end
