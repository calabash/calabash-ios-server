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

#define MAX_LOOP_COUNT 1200

const static NSString *LPUIAChannelUIAPrefsRequestKey = @"__calabashRequest";
const static NSString *LPUIAChannelUIAPrefsResponseKey = @"__calabashResponse";
const static NSString *LPUIAChannelUIAPrefsIndexKey = @"index";
const static NSString *LPUIAChannelUIAPrefsCommandKey = @"command";
const static NSTimeInterval LPUIAChannelUIADelay = 0.1;

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


// todo LPUIAChannel.m [super dealloc] should be called _last_
- (void) dealloc {
  [super dealloc];
  dispatch_release(_uiaQueue);
}


+ (void) runAutomationCommand:(NSString *) command then:(void (^)(NSDictionary *result)) resultHandler {

  [[LPUIAUserPrefsChannel sharedChannel]
   runAutomationCommand:command then:resultHandler];
}


- (void) runAutomationCommand:(NSString *) command then:(void (^)(NSDictionary *)) resultHandler {

  dispatch_async(_uiaQueue, ^{
    [self requestExecutionOf:command];

    NSDictionary *result = nil;
    NSUInteger loopCount = 0;
    while (1) {//Loop waiting for response
      NSDictionary *resultPrefs = [self userPreferences];
      NSDictionary *currentResponse = [resultPrefs objectForKey:LPUIAChannelUIAPrefsResponseKey];

      if (currentResponse) {
        NSUInteger responseIndex = [(NSNumber *) [currentResponse objectForKey:LPUIAChannelUIAPrefsIndexKey] unsignedIntegerValue];
        if (responseIndex == _scriptIndex) {
          result = currentResponse;
          break;
        }
      }
      [NSThread sleepForTimeInterval:LPUIAChannelUIADelay];
      loopCount++;
      if (loopCount >= MAX_LOOP_COUNT) {
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
  NSMutableDictionary *prefs = [NSMutableDictionary dictionaryWithContentsOfFile:[self simulatorPreferencesPath]];
  if (!prefs) {
    prefs = [NSMutableDictionary dictionary];
  }
  NSDictionary *uiaRequest   = [self requestForCommand:command];

  [prefs setObject:uiaRequest forKey:LPUIAChannelUIAPrefsRequestKey];
  [prefs writeToFile:[self simulatorPreferencesPath] atomically:YES];
}
#endif // TARGET_IPHONE_SIMULATOR


- (void) deviceRequestExecutionOf:(NSString *) command {
  NSInteger i=0;
  while (i<MAX_LOOP_COUNT) {
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
  NSDictionary *defaults = [self userPreferences];
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

    // 2. Find the app's Library directory so we can deduce the plist path.
    NSArray *userLibDirURLs = [[NSFileManager defaultManager] URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask];
    NSURL *userLibraryURL = [userLibDirURLs lastObject];
    NSString *userLibraryPath = [userLibraryURL path];

    // 3. Use the the library path to deduce the simulator environment.
    if ([userLibraryPath rangeOfString:@"CoreSimulator"].location == NSNotFound) {
      NSString *sandboxPath = [userLibraryPath substringToIndex:([userLibraryPath rangeOfString:@"Applications"].location)];
      NSString *relativePlistPath = [NSString stringWithFormat:@"Library/Preferences/%@", plistName];
      NSString *unsanitizedPlistPath = [sandboxPath stringByAppendingPathComponent:relativePlistPath];
      path = [[unsanitizedPlistPath stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] copy];
    } else {
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

- (NSString *) stringForXcode61PreferencesPlistWithUserLibraryPath:(NSString *) aUserLibraryPath
                                                         plistName:(NSString *) aPlistName
                                                          tokenKey:(NSString *) aTokenKey
                                                        tokenValue:(NSString *) aTokenValue {
  NSString *relativePlistPath = [NSString stringWithFormat:@"Preferences/%@", aPlistName];
  NSString *unsanitizedPlistPath = [aUserLibraryPath stringByAppendingPathComponent:relativePlistPath];
  NSString *path = [unsanitizedPlistPath stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

  if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
    return nil;
  }

  NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:path];
  if ([[dictionary objectForKey:aTokenKey] isEqualToString:aTokenValue]) {
    return path;
  } else {
    return nil;
  }
}

- (NSString *) stringForXcode60PreferencesPlistWithUserLibraryPath:(NSString *) aUserLibraryPath
                                                         plistName:(NSString *) aPlistName {
  // Xcode 6.0 and 6.0.1 have a buggy NSUserDefaults implementation.  Values
  // may or may not be written when [NSUserDefaults synchronize] is called, so
  // it is not worth checking for the key/token pair.
  NSRange range = [aUserLibraryPath rangeOfString:@"data"];
  NSString *simulatorDataPath = [aUserLibraryPath substringToIndex:range.location + range.length];
  NSString *relativePlistPath = [NSString stringWithFormat:@"Library/Preferences/%@", aPlistName];
  NSString *unsanitizedPlistPath = [simulatorDataPath stringByAppendingPathComponent:relativePlistPath];
  return [unsanitizedPlistPath stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

#endif // TARGET_IPHONE_SIMULATOR

@end
