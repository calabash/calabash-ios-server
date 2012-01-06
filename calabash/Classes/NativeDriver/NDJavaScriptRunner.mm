//
//  NDJavaScriptRunner.mm
//  iPhoneNativeDriver
//
//  Copyright 2011 Google Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

#import "NDJavaScriptRunner.h"
#import "NSException+WebDriver.h"
#import "LPJSONUtils.h"

#import "atoms.h"
#import "errorcodes.h"

static NSString *kExecutionScript = @"(%@)(%@,%@,true)";
static NSString *kMessageKey = @"message";
static NSString *kStatusKey = @"status";
static NSString *kValueKey = @"value";

// Private methods for NDJavaScriptRunner.
@interface NDJavaScriptRunner ()

@property(nonatomic, retain) NSDictionary *executionResult;

- (id)initWithScript:(NSString *)script
             webView:(UIWebView *)webView;

- (id)verifyResult:(NSDictionary *)resultDict;

- (void)executeScriptWithArgs:(NSArray *)args;

@end

@implementation NDJavaScriptRunner

@synthesize executionResult = executionResult_;

// Initializes new instance.
- (id)initWithScript:(NSString *)script
             webView:(UIWebView *)webView {
  if ((self = [super init])) {
    script_ = [script copy];
    webView_ = [webView retain];
  }
  return self;
}

- (void)dealloc {
  [script_ release];
  [webView_ release];
  [executionResult_ release];
  [super dealloc];
}

// Executes a JavaScript in the |UIWebView|.
+ (id)executeJsFunction:(NSString *)script
               withArgs:(NSArray *)args
                webView:(UIWebView *)webView {
  NDJavaScriptRunner *runner =
      [[[NDJavaScriptRunner alloc] initWithScript:script
                                          webView:webView] autorelease];
  [runner performSelectorOnMainThread:@selector(executeScriptWithArgs:)
                           withObject:args
                        waitUntilDone:YES];

  return [runner verifyResult:[runner executionResult]];
}

// Verifies result dictionary. If status is |SUCCESS|, returns 226value. If not,
// throws WebDriver Exception.
- (id)verifyResult:(NSDictionary *)resultDict {
  int status = [(NSNumber *) [resultDict objectForKey:kStatusKey] intValue];
  if (status != SUCCESS) {
    NSDictionary *value = (NSDictionary *) [resultDict objectForKey:kValueKey];
    NSString *message = (NSString *) [value objectForKey:kMessageKey];
    @throw [NSException webDriverExceptionWithMessage:message
                                        andStatusCode:status];
  }
  return [resultDict objectForKey:kValueKey];
}

// Executes |script| with |EXECUTE_SCRIPT| atom. The result can be retrieved via
// |executionResult| property.
- (void)executeScriptWithArgs:(NSArray *)args {
  NSString *executeScript = [NSString stringWithFormat:kExecutionScript,
      [NSString stringWithUTF8String:webdriver::atoms::EXECUTE_SCRIPT],
      script_, [LPJSONUtils serializeArray:args]];
  NSString *result =
      [webView_ stringByEvaluatingJavaScriptFromString:executeScript];

  self.executionResult = [LPJSONUtils deserializeDictionary: result];
}

@end
