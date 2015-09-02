//
//  LPLog.h
//  calabash
//
//  Created by Karl Krukow on 1/30/14.
//  Copyright (c) 2014 Xamarin. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
  LPLoggerLevelDebug = 1,
  LPLoggerLevelInfo = 5,
  LPLoggerLevelError = 10
} LPLoggerLevel;

@interface LPLogger : NSObject

+ (LPLoggerLevel) currentLevel;

+ (NSString *) currentLevelString;

+ (void) setLevelFromString:(NSString *) logLevel;

+ (void) debug:(NSString *) formatString, ...;

+ (void) info:(NSString *) formatString, ...;

+ (void) error:(NSString *) formatString, ...;

@end
