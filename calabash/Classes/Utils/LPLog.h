//
//  LPLog.h
//  calabash
//
//  Created by Karl Krukow on 1/30/14.
//  Copyright (c) 2014 Xamarin. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {LPLogLevelDebug = 1, LPLogLevelInfo = 5, LPLogLevelError = 10} LPLogLevel;

@interface LPLog : NSObject

+ (LPLogLevel) currentLevel;

+ (NSString *) currentLevelString;

+ (void) setLevelFromString:(NSString *) logLevel;

+ (void) debug:(NSString *) formatString, ...;

+ (void) info:(NSString *) formatString, ...;

+ (void) error:(NSString *) formatString, ...;

@end
