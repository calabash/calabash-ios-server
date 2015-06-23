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

// Disable legacy macros
#ifndef LP_LEGACY_MACROS
    #define LP_LEGACY_MACROS 0
#endif

#import "LPLog.h"

/**
 * The constant/variable/method responsible for controlling the current log level.
 **/
#ifndef LP_LOG_LEVEL_DEF
    #ifdef lpLogLevel
        #define LP_LOG_LEVEL_DEF lpLogLevel
    #else
        #define LP_LOG_LEVEL_DEF LPLogLevelVerbose
    #endif
#endif

/**
 * Whether async should be used by log messages, excluding error messages that are always sent sync.
 **/
#ifndef LP_LOG_ASYNC_ENABLED
    #define LP_LOG_ASYNC_ENABLED YES
#endif

/**
 * This is the single macro that all other macros below compile into.
 * This big multiline macro makes all the other macros easier to read.
 **/
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

/**
 * Define version of the macro that only execute if the log level is above the threshold.
 * The compiled versions essentially look like this:
 *
 * if (logFlagForThisLogMsg & lpLogLevel) { execute log message }
 *
 * When LP_LOG_LEVEL_DEF is defined as lpLogLevel.
 *
 * As shown further below, Lumberjack actually uses a bitmask as opposed to primitive log levels.
 * This allows for a great amount of flexibility and some pretty advanced fine grained logging techniques.
 *
 * Note that when compiler optimizations are enabled (as they are for your release builds),
 * the log messages above your logging threshold will automatically be compiled out.
 *
 * (If the compiler sees LP_LOG_LEVEL_DEF/lpLogLevel declared as a constant, the compiler simply checks to see
 *  if the 'if' statement would execute, and if not it strips it from the binary.)
 *
 * We also define shorthand versions for asynchronous and synchronous logging.
 **/
#define LP_LOG_MAYBE(async, lvl, flg, ctx, tag, fnct, frmt, ...) \
        do { if(lvl & flg) LP_LOG_MACRO(async, lvl, flg, ctx, tag, fnct, frmt, ##__VA_ARGS__); } while(0)

/**
 * Ready to use log macros with no context or tag.
 **/
#define LPLogError(frmt, ...)   LP_LOG_MAYBE(NO,                LP_LOG_LEVEL_DEF, LPLogFlagError,   0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define LPLogWarn(frmt, ...)    LP_LOG_MAYBE(LP_LOG_ASYNC_ENABLED, LP_LOG_LEVEL_DEF, LPLogFlagWarning, 0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define LPLogInfo(frmt, ...)    LP_LOG_MAYBE(LP_LOG_ASYNC_ENABLED, LP_LOG_LEVEL_DEF, LPLogFlagInfo,    0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define LPLogDebug(frmt, ...)   LP_LOG_MAYBE(LP_LOG_ASYNC_ENABLED, LP_LOG_LEVEL_DEF, LPLogFlagDebug,   0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define LPLogVerbose(frmt, ...) LP_LOG_MAYBE(LP_LOG_ASYNC_ENABLED, LP_LOG_LEVEL_DEF, LPLogFlagVerbose, 0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)

