#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPASLLogFormatter.h"

@implementation LPASLLogFormatter

- (NSString *)formatLogMessage:(LPLogMessage *)logMessage {
  NSString *logLevel;
  switch (logMessage->_flag) {
    case LPLogFlagError    : logLevel = @"ERROR"; break;
    case LPLogFlagWarning  : logLevel = @" WARN"; break;
    case LPLogFlagInfo     : logLevel = @ "INFO"; break;
    case LPLogFlagDebug    : logLevel = @"DEBUG"; break;
    default                : logLevel = @"DEBUG"; break;
  }

  NSString *logMsg = logMessage->_message;

  NSString *filenameAndNumber = [NSString stringWithFormat:@"%@:%@",
                                 logMessage->_fileName, @(logMessage->_line)];
  return [NSString stringWithFormat:@"%@ %@ | %@",
          logLevel,
          filenameAndNumber,
          logMsg];
}

@end
