//
//  LPUIAChannel.m
//  LPSimpleExample
//
//  Created by Karl Krukow on 11/16/13.
//  Copyright (c) 2013 Xamarin. All rights reserved.
//
//  Adapted from Subliminal's SLTerminal
//
//  For details http://github.com/inkling/Subliminal
//
//  Subliminal is Copyright 2013 Inkling Systems, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//
//  Nov 2013 Modified to fit with Calabash
//  by Karl Krukow <karl.krukow@xamarin.com>

#import "LPUIAChannel.h"

const static NSString *LPUIAChannelUIAPrefsRequestKey               = @"__calabashRequest";
const static NSString *LPUIAChannelUIAPrefsResponseKey              = @"__calabashResponse";
const static NSString *LPUIAChannelUIAPrefsIndexKey                 = @"index";
const static NSString *LPUIAChannelUIAPrefsCommandKey               = @"command";
const static NSTimeInterval LPUIAChannelUIADelay                    = 0.1;
    
// This is calibrated with respect to errors reported on Travis.
// It should be a comfortable margin--the actual discrepancy between
// Travis' execution times, and what we (had) thought would suffice,
// is closer to 0.05.
const NSTimeInterval SLTerminalEvaluationDelay = 0.075;
    
@implementation LPUIAChannel {
    dispatch_queue_t _uiaQueue;
    NSUInteger _scriptIndex;
    BOOL _scriptLoggingEnabled;
}

+(LPUIAChannel *)sharedChannel {
    static LPUIAChannel *sharedChannel = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedChannel = [[LPUIAChannel alloc] init];
    });
    return sharedChannel;
}

-(id)init {
    self = [super init];
    if (self) {
        _uiaQueue = dispatch_queue_create("calabash.uia_queue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

-(void)dealloc {
    [super dealloc];
    dispatch_release(_uiaQueue);
}



+(void)runAutomationCommand:(NSString*)command
                       then:(void(^)(NSDictionary *result))resultHandler {
    
    [[LPUIAChannel sharedChannel] runAutomationCommand:command
                                                  then:resultHandler];
}

-(void)runAutomationCommand:(NSString*)command
                       then:(void(^)(NSDictionary *))resultHandler {
    
    dispatch_async(_uiaQueue, ^{
        [self requestExecutionOf:command];
        
        NSDictionary *result = nil;
        while (1) {//Loop waiting for response
            NSDictionary *resultPrefs = [self userPreferences];
            NSDictionary *currentResponse = [resultPrefs objectForKey: LPUIAChannelUIAPrefsResponseKey];
            
            if (currentResponse) {
                NSUInteger responseIndex = [(NSNumber*)[currentResponse objectForKey: LPUIAChannelUIAPrefsIndexKey ]
                                                        unsignedIntegerValue];
                if (responseIndex == _scriptIndex) {
                    result = currentResponse;
                    break;
                }
            }
            [NSThread sleepForTimeInterval: LPUIAChannelUIADelay];
        }
        _scriptIndex++;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            resultHandler(result);
        });
        
    });
}

-(void)requestExecutionOf:(NSString *)command {
#if TARGET_IPHONE_SIMULATOR
    [self simulatorRequestExecutionOf:command];
#else
    [self deviceRequestExecutionOf:command];
#endif
}

-(NSDictionary *)userPreferences {
    NSDictionary *prefs = nil;
#if TARGET_IPHONE_SIMULATOR
    prefs = [NSDictionary dictionaryWithContentsOfFile:[self simulatorPreferencesPath]];
#else
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults synchronize];
    prefs = [defaults dictionaryRepresentation];
#endif
    return prefs;
}
-(void)simulatorRequestExecutionOf:(NSString *)command {
    NSMutableDictionary *prefs = [NSMutableDictionary dictionaryWithContentsOfFile:[self simulatorPreferencesPath]];
    if (!prefs) {
        prefs = [NSMutableDictionary dictionary];
    }
    NSDictionary *uiaRequest   = [self requestForCommand:command];
    
    [prefs setObject:uiaRequest forKey:LPUIAChannelUIAPrefsRequestKey];
    BOOL success = [prefs writeToFile:[self simulatorPreferencesPath] atomically:YES];
    NSLog(@"Success..");
    
    
}

-(void)deviceRequestExecutionOf:(NSString*)command {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults synchronize];
    NSDictionary *uiaRequest   = [self requestForCommand:command];
    
    [defaults setObject:uiaRequest forKey:(NSString*)LPUIAChannelUIAPrefsRequestKey];
    [defaults synchronize];
}

-(NSDictionary*)requestForCommand:(NSString*)command {
    return [NSDictionary dictionaryWithObjectsAndKeys:
                @(_scriptIndex), LPUIAChannelUIAPrefsIndexKey,
                command, LPUIAChannelUIAPrefsCommandKey,
            nil];
}

#pragma mark - Communication

/**
 Performs a round trip to `SLTerminal.js` by evaluating the script and returning the
 result of `eval()` or throwing an exception.
 
 `SLTerminal` and `SLTerminal.js` execute in lock-step order by waiting for each other
 to update their respective keys within the application's preferences. `SLTerminal.js`
 polls the "scriptIndex" key and waits for it to increment before evaluating the
 "script" key. `SLTerminal` waits for the result by polling for the existence of the
 "resultIndex" key. `SLTerminal` then checks the "result" and "exception" keys for
 the result of `eval()`.
 
 Preferences Keys
 ----------------
 
 Application
 "scriptIndex": SLTerminal.js waits for this number to increment
 "script": The input to eval()
 
 Script
 "resultIndex": The app waits for this number to appear
 "result": The output of eval(), may be empty
 "exception": The textual representation of a javascript exception, will be empty if no exceptions occurred.
 
 */

/*
- (NSString *)evalWithFormat:(NSString *)script, ... {
    NSParameterAssert(script);
    
    va_list args;
    va_start(args, script);
    NSString *statement = [[NSString alloc] initWithFormat:script arguments:args];
    va_end(args);
    
    return [self eval:statement];
}
*/


- (void)setScriptLoggingEnabled:(BOOL)scriptLoggingEnabled {
    if (scriptLoggingEnabled != _scriptLoggingEnabled) {
        [self enableScriptLogging:scriptLoggingEnabled];
        _scriptLoggingEnabled = scriptLoggingEnabled;
    }
}

- (void)enableScriptLogging:(BOOL)enableScriptLogging {
    /*
    if (dispatch_get_current_queue() != self.evalQueue) {
        // dispatch_async so that this can be called by the application
        // before testing has started
        dispatch_async(self.evalQueue, ^{
            [self enableScriptLogging:enableScriptLogging];
        });
        return;
    }
    [self evalWithFormat:@"%@.%@ = %@",
     self.scriptNamespace, SLTerminalScriptLoggingEnabledVariable,
     (enableScriptLogging ? @"true" : @"false")];
     */
}

- (void)shutDown {
//    [self evalWithFormat:@"%@.%@ = true;", self.scriptNamespace, SLTerminalHasShutDownVariable];
}


#if TARGET_IPHONE_SIMULATOR
// in the simulator, UIAutomation uses a target-specific plist in ~/Library/Application Support/iPhone Simulator/[system version]/Library/Preferences/[bundle ID].plist
// _not_ the NSUserDefaults plist, in the sandboxed Library
// see http://stackoverflow.com/questions/4977673/reading-preferences-set-by-uiautomations-uiaapplication-setpreferencesvaluefork
- (NSString *)simulatorPreferencesPath {
    static NSString *path = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *plistRootPath = nil, *relativePlistPath = nil;
        NSString *plistName = [NSString stringWithFormat:@"%@.plist", [[NSBundle mainBundle] bundleIdentifier]];
        
        // 1. get into the simulator's app support directory by fetching the sandboxed Library's path
        NSString *userDirectoryPath = [[[[NSFileManager defaultManager] URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] lastObject] path];
        // 2. get out of our application directory, back to the root support directory for this system version
        plistRootPath = [userDirectoryPath substringToIndex:([userDirectoryPath rangeOfString:@"Applications"].location)];
        
        // 3. locate, relative to here, /Library/Preferences/[bundle ID].plist
        relativePlistPath = [NSString stringWithFormat:@"Library/Preferences/%@", plistName];
        
        // 4. and unescape spaces, if necessary (i.e. in the simulator)
        NSString *unsanitizedPlistPath = [plistRootPath stringByAppendingPathComponent:relativePlistPath];
        path = [unsanitizedPlistPath stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    });
    return [path retain];
}
#endif // TARGET_IPHONE_SIMULATOR


@end
