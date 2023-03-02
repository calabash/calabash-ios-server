#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPTTYLogFormatter.h"
#import <stdatomic.h>
#import <libkern/OSAtomic.h>

static NSString *const CalLogFormatterDateFormat = @"yyyy-MM-dd HH:mm:ss.SSS";
static NSString *const CalLogFormatterDateFormatterKey = @"sh.calaba.CalSSO-CalLogFormatter-NSDateFormatter";
@interface LPTTYLogFormatter () {
  atomic_int_fast32_t atomicLoggerCount;
  NSDateFormatter *threadUnsafeDateFormatter;
}

- (NSString *)stringFromDate:(NSDate *)date;

@end

@implementation LPTTYLogFormatter

- (NSString *)stringFromDate:(NSDate *)date {
  atomic_int_fast32_t loggerCount = atomic_fetch_add_explicit(&atomicLoggerCount, 0, memory_order_relaxed);

  if (loggerCount <= 1) {
    // Single-threaded mode.

    if (!threadUnsafeDateFormatter) {
      threadUnsafeDateFormatter = [[NSDateFormatter alloc] init];
      [threadUnsafeDateFormatter setDateFormat:CalLogFormatterDateFormat];
    }

    return [threadUnsafeDateFormatter stringFromDate:date];
  } else {
    // Multi-threaded mode.
    // NSDateFormatter is NOT thread-safe.
    NSMutableDictionary *threadDictionary = [[NSThread currentThread] threadDictionary];
    NSDateFormatter *dateFormatter = threadDictionary[CalLogFormatterDateFormatterKey];

    if (dateFormatter == nil) {
      dateFormatter = [[NSDateFormatter alloc] init];
      [dateFormatter setDateFormat:CalLogFormatterDateFormat];

      threadDictionary[CalLogFormatterDateFormatterKey] = dateFormatter;
    }

    return [dateFormatter stringFromDate:date];
  }
}

- (NSString *)formatLogMessage:(LPLogMessage *)logMessage {
  NSString *logLevel;
  switch (logMessage->_flag) {
    case LPLogFlagError    : logLevel = @"ERROR"; break;
    case LPLogFlagWarning  : logLevel = @" WARN"; break;
    case LPLogFlagInfo     : logLevel = @ "INFO"; break;
    case LPLogFlagDebug    : logLevel = @"DEBUG"; break;
    default                : logLevel = @"DEBUG"; break;
  }

  NSString *dateAndTime = [self stringFromDate:(logMessage.timestamp)];
  NSString *logMsg = logMessage->_message;

  NSString *filenameAndNumber = [NSString stringWithFormat:@"%@:%@",
                                 logMessage->_fileName, @(logMessage->_line)];
  return [NSString stringWithFormat:@"%@ %@ %@ | %@",
          dateAndTime,
          logLevel,
          filenameAndNumber,
          logMsg];
}

- (void)didAddToLogger:(id <LPLogger>)logger {
  atomic_fetch_add_explicit(&atomicLoggerCount, 1, memory_order_relaxed);
}

- (void)willRemoveFromLogger:(id <LPLogger>)logger {
  atomic_fetch_sub_explicit(&atomicLoggerCount, 1, memory_order_relaxed);
}
@end
