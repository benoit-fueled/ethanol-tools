//
//  ETHLogger.h
//  Ethanol
//
//  Created by Stephane Copin on 12/17/14.
//  Copyright (c) 2014 Fueled. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_OPTIONS(NSUInteger, ETHLogFlag) {
  ETHLogFlagFatal   = (1 << 0),
  ETHLogFlagError   = (1 << 1),
  ETHLogFlagWarning = (1 << 2),
  ETHLogFlagInfo    = (1 << 3),
  ETHLogFlagDebug   = (1 << 4),
  ETHLogFlagVerbose = (1 << 5),
  ETHLogFlagTrace   = (1 << 6),
};

typedef NS_OPTIONS(NSUInteger, ETHLogLevel) {
  ETHLogLevelOff     =  0,
  ETHLogLevelFatal   =  ETHLogFlagFatal,
  ETHLogLevelError   = (ETHLogFlagError   | ETHLogLevelFatal),
  ETHLogLevelWarning = (ETHLogFlagWarning | ETHLogLevelError),
  ETHLogLevelInfo    = (ETHLogFlagInfo    | ETHLogLevelWarning),
  ETHLogLevelDebug   = (ETHLogFlagDebug   | ETHLogLevelInfo),
  ETHLogLevelVerbose = (ETHLogFlagVerbose | ETHLogLevelDebug),
  ETHLogLevelTrace   = (ETHLogFlagTrace   | ETHLogLevelVerbose),
  ETHLogLevelAll     = NSUIntegerMax,
};

/**
 *  This provides an interface (To be registered wth ETHInjector) that can be used as a way to implement any kind of
 *  logging framework in a generic manner.
 *  Ethanol provides for now only one logger, implemented via CocoaLumberjack, called CocoaLumberjackLogging.
 *  Because such classes should register themselves with ETHInjector, once the subspec is added to your project
 *  there is no other action to do other than directly use the ETHLog<Level> macros.
 *  The ETHLog<Level> macros uses the [ETHFramework ethanolLogLevel] property and the supplied flag to determine
 *  whether the log should be displayed or not. The available levels are defined in Ethanol/ETHConstants.h
 *  Also, by default, the logging for Ethanol itself is disable. You can enable it by including the subspec
 *  'EnableInternalLogging'.
 *  You can also chose to completely disable Ethanol's logging system (In objective-c) by defining the macro
 *  ETHANOL_DISABLE_LOGGING in the Build Settings of your app. This ensure that every call to the ETHLog<Level> macros
 *  will be converted into noop.
 *  @note This means that, if the macro ETHANOL_DISABLE_LOGGING is enabled, none of its arguments will be evaluated.
 *  Never include method call, assignment and such in the logging macros!
 */
@protocol ETHLogger <NSObject>

@property (nonatomic, assign) ETHLogLevel logLevel;

- (void)log:(ETHLogFlag)flag file:(NSString *)file function:(NSString *)function line:(int)line format:(NSString *)format, ... NS_FORMAT_FUNCTION(5,6);
- (void)log:(ETHLogFlag)flag file:(NSString *)file function:(NSString *)function line:(int)line format:(NSString *)format arguments:(va_list)arguments;

@end

#undef _ETHLog

#undef _ETHTryLog

#undef ETHLogTrace
#undef ETHLogVerbose
#undef ETHLogDebug
#undef ETHLogInfo
#undef ETHLogWarning
#undef ETHLogError
#undef ETHLogFatal

#define _ETHLog(flag, formatString, ...) \
  do { \
    if(([ETHFramework ethanolLogLevel] & (flag)) == (flag)) { \
      [[[ETHFramework injector] instanceForProtocol:@protocol(ETHLogger)] log:(flag) file:[NSString stringWithUTF8String:__FILE__] function:NSStringFromSelector(_cmd) line:__LINE__ format:(formatString), ## __VA_ARGS__]; \
    } \
  } while(0)

#if !defined(ETHANOL_DISABLE_LOGGING) && (!defined(IS_ETHANOL_SOURCES) || (defined(IS_ETHANOL_SOURCES) && defined(ETHANOL_ENABLE_INTERNAL_LOGGING)))
#define _ETHTryLog(flag, formatString, ...) _ETHLog(flag, formatString, ## __VA_ARGS__)
#else
#define _ETHTryLog(flag, formatString, ...) do { } while(0)
#endif

#define ETHLogTrace(format, ...)   _ETHTryLog(ETHLogFlagTrace,   format, ## __VA_ARGS__)
#define ETHLogVerbose(format, ...) _ETHTryLog(ETHLogFlagVerbose, format, ## __VA_ARGS__)
#define ETHLogDebug(format, ...)   _ETHTryLog(ETHLogFlagDebug,   format, ## __VA_ARGS__)
#define ETHLogInfo(format, ...)    _ETHTryLog(ETHLogFlagInfo,    format, ## __VA_ARGS__)
#define ETHLogWarning(format, ...) _ETHTryLog(ETHLogFlagWarning, format, ## __VA_ARGS__)
#define ETHLogError(format, ...)   _ETHTryLog(ETHLogFlagError,   format, ## __VA_ARGS__)
#define ETHLogFatal(format, ...)   _ETHTryLog(ETHLogFlagFatal,   format, ## __VA_ARGS__)
