#import "LPCocoaLumberjack.h"

#ifndef LP_HTTP_LOG_LEVEL_DEF
  #ifdef lpHTTPLogLevel
    #define LP_HTTP_LOG_LEVEL_DEF lpHTTPLogLevel
  #else
    #define LP_HTTP_LOG_LEVEL_DEF LPLogLevelOff
  #endif
#endif

#define LPHTTPLogError(frmt, ...)   LP_LOG_MAYBE(NO,  LP_HTTP_LOG_LEVEL_DEF, LPLogFlagError,   80, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define LPHTTPLogWarn(frmt, ...)    LP_LOG_MAYBE(YES, LP_HTTP_LOG_LEVEL_DEF, LPLogFlagWarning, 80, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define LPHTTPLogInfo(frmt, ...)    LP_LOG_MAYBE(YES, LP_HTTP_LOG_LEVEL_DEF, LPLogFlagInfo,    80, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define LPHTTPLogDebug(frmt, ...)   LP_LOG_MAYBE(YES, LP_HTTP_LOG_LEVEL_DEF, LPLogFlagDebug,   80, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define LPHTTPLogVerbose(frmt, ...) LP_LOG_MAYBE(YES, LP_HTTP_LOG_LEVEL_DEF, LPLogFlagVerbose, 80, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define LPHTTPLogTrace()            LP_LOG_MAYBE(YES, LP_HTTP_LOG_LEVEL_DEF, LPLogFlagVerbose, 80, nil, __PRETTY_FUNCTION__, @"%@: %@", LP_THIS_FILE, LP_THIS_METHOD)
