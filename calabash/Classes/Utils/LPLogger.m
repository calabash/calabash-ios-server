//
//  LPLog.m
//  calabash
//
//  Created by Karl Krukow on 1/30/14.
//  Copyright (c) 2014 Xamarin. All rights reserved.
//

#import "LPLogger.h"
#import "LPEnv.h"


@implementation LPLogger {
  LPLogLevel _logLevel;
}

+ (LPLogger *) sharedLog {
  static LPLogger *sharedLog = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedLog = [[LPLogger alloc] init];
  });
  return sharedLog;
}


+ (LPLogLevel) currentLevel {
  return [[LPLogger sharedLog] currentLevel];
}


+ (void) setLevelFromString:(NSString *) logLevel {
  [[LPLogger sharedLog] setLevelFromString:logLevel];
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
  switch ([LPLogger currentLevel]) {
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
  if (![[LPLogger sharedLog] shouldLogAtLevel:LPLogLevelDebug]) {return;}
  va_list args;
  va_start(args, formatString);
  NSLogv(formatString, args);
  va_end(args);
}


+ (void) info:(NSString *) formatString, ... {
  if (![[LPLogger sharedLog] shouldLogAtLevel:LPLogLevelInfo]) {return;}
  va_list args;
  va_start(args, formatString);
  NSLogv(formatString, args);
  va_end(args);
}


+ (void) error:(NSString *) formatString, ... {
  if (![[LPLogger sharedLog] shouldLogAtLevel:LPLogLevelError]) {return;}
  va_list args;
  va_start(args, formatString);
  NSLogv(formatString, args);
  va_end(args);
}

@end
