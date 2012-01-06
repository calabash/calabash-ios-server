//
//  NDJavaScriptRunner.h
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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// Provides a feature to execute JavaScript in |UIWebView|s.
@interface NDJavaScriptRunner : NSObject {
 @private
  NSString *script_;
  UIWebView *webView_;
  NSDictionary *executionResult_;
}

// Executes a JavaScript function in the |UIWebView|. Each script argument must
// be a JSON friendly value: NSNumber, NSString, NSNull, NSArray, or
// NSDictionary. If an argument value is a NSDictionary and contains the
// "ELEMENT" key, it will be interpreted as a DOM element reference, as defined
// by the WebDriver wire protocol:
//   http://code.google.com/p/selenium/wiki/JsonWireProtocol
//
// Returns the script result; throws an exception if it fails.
+ (id)executeJsFunction:(NSString *)functionAsString
               withArgs:(NSArray *)args
                webView:(UIWebView *)webView;

@end
