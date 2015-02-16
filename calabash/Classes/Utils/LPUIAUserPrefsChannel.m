//
//  LPUIAChannel.m
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

#import "LPUIAUserPrefsChannel.h"

const static NSString *LPUIAChannelUIAPrefsRequestKey = @"__calabashRequest";
const static NSString *LPUIAChannelUIAPrefsResponseKey = @"__calabashResponse";
const static NSString *LPUIAChannelUIAPrefsIndexKey = @"index";
const static NSString *LPUIAChannelUIAPrefsCommandKey = @"command";
const static NSTimeInterval LPUIAChannelUIADelay = 0.1;
const static NSInteger LPUIAChannelMaximumLoopCount = 1200;

@implementation LPUIAUserPrefsChannel {
  dispatch_queue_t _uiaQueue;
  NSUInteger _scriptIndex;
  BOOL _scriptLoggingEnabled;
}

+ (LPUIAUserPrefsChannel *) sharedChannel {
  static LPUIAUserPrefsChannel *sharedChannel = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedChannel = [[LPUIAUserPrefsChannel alloc] init];
  });
  return sharedChannel;
}


- (id) init {
  self = [super init];
  if (self) {
    _uiaQueue = dispatch_queue_create("calabash.uia_queue", DISPATCH_QUEUE_SERIAL);
  }
  return self;
}

- (void) dealloc {
  dispatch_release(_uiaQueue);
  [super dealloc];
}


+ (void) runAutomationCommand:(NSString *) command then:(void (^)(NSDictionary *result)) resultHandler {

  [[LPUIAUserPrefsChannel sharedChannel]
   runAutomationCommand:command then:resultHandler];
}


- (void) runAutomationCommand:(NSString *) command then:(void (^)(NSDictionary *)) resultHandler {

  dispatch_async(_uiaQueue, ^{
    [self requestExecutionOf:command];
    NSLog(@"requested execution of command: %@", command);

    NSDictionary *result = nil;
    NSUInteger loopCount = 0;
    while (1) {//Loop waiting for response
      [[NSUserDefaults standardUserDefaults] synchronize];
      NSDictionary *resultPrefs = [self userPreferences];
      NSDictionary *currentResponse = [resultPrefs objectForKey:LPUIAChannelUIAPrefsResponseKey];

      NSLog(@"Current request: %@", [resultPrefs objectForKey:LPUIAChannelUIAPrefsRequestKey]);

      if (currentResponse) {
        NSUInteger responseIndex = [(NSNumber *) [currentResponse objectForKey:LPUIAChannelUIAPrefsIndexKey] unsignedIntegerValue];
        NSLog(@"Current response: %@", currentResponse);
        NSLog(@"Server current index: %lu",(unsigned long) _scriptIndex);
        NSLog(@"response current index: %lu",(unsigned long) responseIndex);
        if (responseIndex == _scriptIndex) {
          result = currentResponse;
          break;
        }
      }
      [NSThread sleepForTimeInterval:LPUIAChannelUIADelay];
      loopCount++;
      if (loopCount >= LPUIAChannelMaximumLoopCount) {
        NSLog(@"Timed out running command %@", command);
        NSLog(@"Server current index: %lu",(unsigned long) _scriptIndex);
        NSDictionary *prefs = [self userPreferences];
        NSLog(@"Current request: %@", [prefs objectForKey:LPUIAChannelUIAPrefsRequestKey]);
        NSLog(@"Current response: %@", [prefs objectForKey:LPUIAChannelUIAPrefsRequestKey]);
        result = nil;
        break;
      }
    }
    _scriptIndex++;

    dispatch_async(dispatch_get_main_queue(), ^{
      resultHandler(result);
    });
  });
}

- (void) requestExecutionOf:(NSString *) command {
#if TARGET_IPHONE_SIMULATOR
  [self simulatorRequestExecutionOf:command];
#else
  [self deviceRequestExecutionOf:command];
#endif
}

- (NSDictionary *) userPreferences {
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

#if TARGET_IPHONE_SIMULATOR
-(void)simulatorRequestExecutionOf:(NSString *)command {
  // In Xcode 6.1 and iOS 8.1, there is synchronization problem between IO
  // performed by NSUserDefaults and the UIAutomation preferences API.  The
  // if condition detects iOS 8.1 which is a proxy for Xcode 6.1 detection.
  // When Xcode 6.1 and iOS 8.1; compensate for the synchronization problem.
  // Earlier iOS versions in Xcode 6.1 do not suffer from the sync problem
  // because NSUserDefaults and UIAutomation preferences API do IO on different
  // files. (>_>)
  NSString *preferencesPlist = [self simulatorPreferencesPath];
  NSMutableDictionary *preferences;
  NSString *systemVersion = [[UIDevice currentDevice] systemVersion];
  if ([systemVersion compare:@"8.1" options:NSNumericSearch] != NSOrderedAscending) {
    NSLog(@"iOS >= 8.1 detected; assuming Xcode >= 6.1");
    NSInteger i = 0;
    while (i < LPUIAChannelMaximumLoopCount) {
      [[NSUserDefaults standardUserDefaults] synchronize];
      preferences  = [NSMutableDictionary dictionaryWithContentsOfFile:preferencesPlist];
      if (!preferences) {
        preferences = [NSMutableDictionary dictionary];
        NSLog(@"Empty preferences... resetting");
      }

      NSDictionary *uiaRequest   = [self requestForCommand:command];
      [preferences setObject:uiaRequest forKey:LPUIAChannelUIAPrefsRequestKey];
      BOOL writeSuccess = [preferences writeToFile:preferencesPlist
                                        atomically:YES];

      if (!writeSuccess) {
        NSLog(@"Preparing for retry of simulatorRequestExecutionOf:");
      }

      if ([self validateRequestWritten:uiaRequest]) {
        return;
      } else {
        i++;
        NSLog(@"Validation of request failed... Retrying - %@ of %@",
              @(i), @(LPUIAChannelMaximumLoopCount));
        [NSThread sleepForTimeInterval:LPUIAChannelUIADelay];
      }
    }
  } else {
    NSLog(@"iOS < 8.1 detected; assuming Xcode < 6.1");
    preferences = [NSMutableDictionary dictionaryWithContentsOfFile:preferencesPlist];

    if (!preferences) {
      preferences = [NSMutableDictionary dictionary];
      NSLog(@"Empty preferences... resetting");
    }
    NSDictionary *uiaRequest   = [self requestForCommand:command];

    [preferences setObject:uiaRequest forKey:LPUIAChannelUIAPrefsRequestKey];
    [preferences writeToFile:preferencesPlist atomically:YES];
  }
}
#endif // TARGET_IPHONE_SIMULATOR

- (void) deviceRequestExecutionOf:(NSString *) command {
  NSInteger i=0;
  while (i<LPUIAChannelMaximumLoopCount) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *uiaRequest = [self requestForCommand:command];

    [defaults setObject:uiaRequest
                 forKey:(NSString *) LPUIAChannelUIAPrefsRequestKey];
    [defaults synchronize];

    if ([self validateRequestWritten: uiaRequest]) {
      return;
    }
    else {
      [NSThread sleepForTimeInterval:LPUIAChannelUIADelay];
      i++;
    }

  }
}

-(BOOL)validateRequestWritten:(NSDictionary*)uiaRequest {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults synchronize];
  NSDictionary *written = [defaults objectForKey:(NSString*)LPUIAChannelUIAPrefsRequestKey];
  if (!written) {
    return NO;
  }
  id indexWritten =[written objectForKey:LPUIAChannelUIAPrefsIndexKey];
  if (!indexWritten) {
    return NO;
  }
  return [indexWritten unsignedIntegerValue] == _scriptIndex;
}


- (NSDictionary *) requestForCommand:(NSString *) command {
  return [NSDictionary dictionaryWithObjectsAndKeys:@(_scriptIndex), LPUIAChannelUIAPrefsIndexKey,
          command, LPUIAChannelUIAPrefsCommandKey,
          nil];
}

#pragma mark - Communication

#if TARGET_IPHONE_SIMULATOR
// In the simulator, UIAutomation does _not_ use the NSUserDefaults plist in the
// sandboxed Application Library.  Instead it uses a target-specific plist
// located in one of the following locations:
//
// Xcode 5
// ~/Library/Application Support/iPhone Simulator/[system version]/Library/Preferences/[bundle ID].plist
//
// Xcode 6.0*
// ~/Library/Developer/CoreSimulator/Devices/[UDID]/data/Library/Preferences/[bundle ID].plist
// see http://stackoverflow.com/questions/4977673/reading-preferences-set-by-uiautomations-uiaapplication-setpreferencesvaluefork
//
// Xcode 6.1 + iOS 8.1 - all other simulator SDKs use Xcode 6.0* rules.
// ~/Library/Developer/CoreSimulator/Devices/[Sim UDID]/data/Containers/Data/Application/[App UDID]/Library/Preferences/[bundle id].plist
- (NSString *)simulatorPreferencesPath {
  static NSString *path = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{

    NSString *plistName = [NSString stringWithFormat:@"%@.plist", [[NSBundle mainBundle] bundleIdentifier]];

    // 1. Find the app's Library directory so we can deduce the plist path.
    NSArray *userLibDirURLs = [[NSFileManager defaultManager] URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask];
    NSURL *userLibraryURL = [userLibDirURLs lastObject];
    NSString *userLibraryPath = [userLibraryURL path];

    // 2. Use the the library path to deduce the simulator environment.

    if ([userLibraryPath rangeOfString:@"CoreSimulator"].location == NSNotFound) {
      // 3. Xcode < 6 environment.
      NSString *sandboxPath = [userLibraryPath substringToIndex:([userLibraryPath rangeOfString:@"Applications"].location)];
      NSString *relativePlistPath = [NSString stringWithFormat:@"Library/Preferences/%@", plistName];
      NSString *unsanitizedPlistPath = [sandboxPath stringByAppendingPathComponent:relativePlistPath];
      path = [[unsanitizedPlistPath stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] copy];
    } else {

      /*
       3. CoreSimulator environments

       * In Xcode 6.1 + iOS >= 8.1, UIAutomation and NSUserDefaults do IO on
         the same plist in the app's sandbox.
       * In Xcode 6.1 and iOS < 8.1, UIAutomation does IO on the a file in
         < SIM DIRECTORY >/data/Library/Preferences/ and NSUserDefaults does
         IO on a plist in the app's sandbox.
       * In Xcode 6.0*, NSUserDefaults and UIAutomation do IO on the same plist
         in < SIM DIRECTORY >/data/Library/Preferences.

       Since iOS 8.1 only ships with Xcode 6.1, we can check the system version
       at runtime and choose the correct plist.
      */

      NSString *systemVersion = [[UIDevice currentDevice] systemVersion];
      if ([systemVersion compare:@"8.1" options:NSNumericSearch] != NSOrderedAscending) {
        NSString *relativePlistPath = [NSString stringWithFormat:@"Preferences/%@", plistName];
        NSString *unsanitizedPlistPath = [userLibraryPath stringByAppendingPathComponent:relativePlistPath];
        path = [[unsanitizedPlistPath stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] copy];
      } else {
        NSRange range = [userLibraryPath rangeOfString:@"data"];
        NSString *simulatorDataPath = [userLibraryPath substringToIndex:range.location + range.length];
        NSString *relativePlistPath = [NSString stringWithFormat:@"Library/Preferences/%@", plistName];
        NSString *unsanitizedPlistPath = [simulatorDataPath stringByAppendingPathComponent:relativePlistPath];
        path = [[unsanitizedPlistPath stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] copy];
      }
    }
  });
  NSLog(@"NSUserDefaults path = %@", path);
  return path;
}

#endif // TARGET_IPHONE_SIMULATOR

@end
