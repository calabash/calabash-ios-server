//
//  LPLog.m
//  calabash
//
//  Created by Karl Krukow on 1/30/14.
//  Copyright (c) 2014 Xamarin. All rights reserved.
//

#import "LPLogger.h"
#import "LPEnv.h"

@interface LPLogger ()

@property(assign, atomic, readonly) LPLoggerLevel logLevel;

@end

@implementation LPLogger

@synthesize logLevel = _logLevel;

+ (LPLogger *) sharedLog {
  static LPLogger *sharedLog = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedLog = [[LPLogger alloc] init];
  });
  return sharedLog;
}


+ (LPLoggerLevel) currentLevel {
  return [[LPLogger sharedLog] currentLevel];
}


+ (void) setLevelFromString:(NSString *) logLevel {
  [[LPLogger sharedLog] setLevelFromString:logLevel];
}


- (void) setLevelFromString:(NSString *) logLevel {
  if ([@"debug" isEqualToString:[logLevel lowercaseString]]) {
    _logLevel = LPLoggerLevelDebug;
  } else if ([@"info" isEqualToString:[logLevel lowercaseString]]) {
    _logLevel = LPLoggerLevelInfo;
  } else if ([@"error" isEqualToString:[logLevel lowercaseString]]) {
    _logLevel = LPLoggerLevelError;
  }
}


- (LPLoggerLevel) currentLevel {
  return _logLevel;
}


+ (NSString *) currentLevelString {
  switch ([LPLogger currentLevel]) {
    case LPLoggerLevelDebug:return @"debug";
    case LPLoggerLevelInfo:return @"info";
    case LPLoggerLevelError:return @"error";
    default:return nil;
  }
}


- (id) init {
  self = [super init];
  if (self) {
    _logLevel = [LPEnv calabashDebugEnabled] ? LPLoggerLevelDebug : LPLoggerLevelInfo;
  }
  return self;
}


- (BOOL) shouldLogAtLevel:(LPLoggerLevel) level {
  return (level >= _logLevel);
}


//Not 100% sure if this va_* is necessary
+ (void) debug:(NSString *) formatString, ...; {
  if (![[LPLogger sharedLog] shouldLogAtLevel:LPLoggerLevelDebug]) {return;}
  va_list args;
  va_start(args, formatString);
  NSLogv(formatString, args);
  va_end(args);
}


+ (void) info:(NSString *) formatString, ... {
  if (![[LPLogger sharedLog] shouldLogAtLevel:LPLoggerLevelInfo]) {return;}
  va_list args;
  va_start(args, formatString);
  NSLogv(formatString, args);
  va_end(args);
}


+ (void) error:(NSString *) formatString, ... {
  if (![[LPLogger sharedLog] shouldLogAtLevel:LPLoggerLevelError]) {return;}
  va_list args;
  va_start(args, formatString);
  NSLogv(formatString, args);
  va_end(args);
}

@end
