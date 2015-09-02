// Software License Agreement (BSD License)
//
// Copyright (c) 2010-2015, Deusty, LLC
// All rights reserved.
//
// Redistribution and use of this software in source and binary forms,
// with or without modification, are permitted provided that the following conditions are met:
//
// * Redistributions of source code must retain the above copyright notice,
//   this list of conditions and the following disclaimer.
//
// * Neither the name of Deusty nor the names of its contributors may be used
//   to endorse or promote products derived from this software without specific
//   prior written permission of Deusty, LLC.

/**
 * Legacy macros used for 1.9.x backwards compatibility.
 *
 * Imported by default when importing a LPLog.h directly and LP_LEGACY_MACROS is not defined and set to 0.
 **/

#warning CocoaLumberjack 1.9.x legacy macros enabled. \
Disable legacy macros by importing CocoaLumberjack.h or LPLogMacros.h instead of LPLog.h or add `#define LP_LEGACY_MACROS 0` before importing LPLog.h.

#ifndef LP_LOG_LEVEL_DEF
    #define LP_LOG_LEVEL_DEF lpLogLevel
#endif

#define LP_LOG_FLAG_ERROR    LPLogFlagError
#define LP_LOG_FLAG_WARN     LPLogFlagWarning
#define LP_LOG_FLAG_INFO     LPLogFlagInfo
#define LP_LOG_FLAG_DEBUG    LPLogFlagDebug
#define LP_LOG_FLAG_VERBOSE  LPLogFlagVerbose

#define LP_LOG_LEVEL_OFF     LPLogLevelOff
#define LP_LOG_LEVEL_ERROR   LPLogLevelError
#define LP_LOG_LEVEL_WARN    LPLogLevelWarning
#define LP_LOG_LEVEL_INFO    LPLogLevelInfo
#define LP_LOG_LEVEL_DEBUG   LPLogLevelDebug
#define LP_LOG_LEVEL_VERBOSE LPLogLevelVerbose
#define LP_LOG_LEVEL_ALL     LPLogLevelAll

#define LP_LOG_ASYNC_ENABLED YES

#define LP_LOG_ASYNC_ERROR    ( NO && LP_LOG_ASYNC_ENABLED)
#define LP_LOG_ASYNC_WARN     (YES && LP_LOG_ASYNC_ENABLED)
#define LP_LOG_ASYNC_INFO     (YES && LP_LOG_ASYNC_ENABLED)
#define LP_LOG_ASYNC_DEBUG    (YES && LP_LOG_ASYNC_ENABLED)
#define LP_LOG_ASYNC_VERBOSE  (YES && LP_LOG_ASYNC_ENABLED)

#define LP_LOG_MACRO(isAsynchronous, lvl, flg, ctx, atag, fnct, frmt, ...) \
        [LPLog log : isAsynchronous                                     \
             level : lvl                                                \
              flag : flg                                                \
           context : ctx                                                \
              file : __FILE__                                           \
          function : fnct                                               \
              line : __LINE__                                           \
               tag : atag                                               \
            format : (frmt), ## __VA_ARGS__]

#define LP_LOG_MAYBE(async, lvl, flg, ctx, fnct, frmt, ...)                       \
        do { if(lvl & flg) LP_LOG_MACRO(async, lvl, flg, ctx, nil, fnct, frmt, ##__VA_ARGS__); } while(0)

#define LP_LOG_OBJC_MAYBE(async, lvl, flg, ctx, frmt, ...) \
        LP_LOG_MAYBE(async, lvl, flg, ctx, __PRETTY_FUNCTION__, frmt, ## __VA_ARGS__)

#define LPLogError(frmt, ...)   LP_LOG_OBJC_MAYBE(LP_LOG_ASYNC_ERROR,   LP_LOG_LEVEL_DEF, LP_LOG_FLAG_ERROR,   0, frmt, ##__VA_ARGS__)
#define LPLogWarn(frmt, ...)    LP_LOG_OBJC_MAYBE(LP_LOG_ASYNC_WARN,    LP_LOG_LEVEL_DEF, LP_LOG_FLAG_WARN,    0, frmt, ##__VA_ARGS__)
#define LPLogInfo(frmt, ...)    LP_LOG_OBJC_MAYBE(LP_LOG_ASYNC_INFO,    LP_LOG_LEVEL_DEF, LP_LOG_FLAG_INFO,    0, frmt, ##__VA_ARGS__)
#define LPLogDebug(frmt, ...)   LP_LOG_OBJC_MAYBE(LP_LOG_ASYNC_DEBUG,   LP_LOG_LEVEL_DEF, LP_LOG_FLAG_DEBUG,   0, frmt, ##__VA_ARGS__)
#define LPLogVerbose(frmt, ...) LP_LOG_OBJC_MAYBE(LP_LOG_ASYNC_VERBOSE, LP_LOG_LEVEL_DEF, LP_LOG_FLAG_VERBOSE, 0, frmt, ##__VA_ARGS__)

