//
//  NDWebElement.m
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

#import "NDWebElement.h"

#import "atoms.h"
#import "errorcodes.h"
#import "NDJavaScriptRunner.h"
#import "NSException+WebDriver.h"

static NSString *kClassNameStrategy = @"className";
static NSString *kCssSelectorStrategy = @"css";
static NSString *kIdStrategy = @"id";
static NSString *kLinkTextStrategy = @"linkText";
static NSString *kNameStrategy = @"name";
static NSString *kPartialLinkTextStrategy = @"partialLinkText";
static NSString *kTagNameStrategy = @"tagName";
static NSString *kXpathStrategy = @"xpath";
static NSString *kElementIdKey = @"ELEMENT";

static NSDictionary *wireProtocolToAtomsStrategy =
    [[NSDictionary alloc] initWithObjectsAndKeys:
        kClassNameStrategy, kByClassName,
        kCssSelectorStrategy, kByCssSelector,
        kIdStrategy, kById,
        kLinkTextStrategy, kByLinkText,
        kNameStrategy, kByName,
        kPartialLinkTextStrategy, kByPartialLinkText,
        kTagNameStrategy, kByTagName,
        kXpathStrategy, kByXpath,
        nil];

@interface NDWebElement ()

- (id)initWithWebView:(UIWebView *)webView
          webDriverId:(NSString *)webDriverId;

- (NSDictionary *)idDictionary;

- (id)executeAtom:(const char* const)atom
         withArgs:(NSArray *)args;

- (id)executeJsFunction:(NSString *)script
                withArgs:(NSArray *)args;

- (NSDictionary *)buildLocator:(NSString *)by
                         value:(NSString *)value;

@end

@implementation NDWebElement

@synthesize webView = webView_;
@synthesize webDriverId = webDriverId_;

// Initialize a new element.
- (id)initWithWebView:(UIWebView *)webView
          webDriverId:(NSString *)webDriverId {
  if ((self = [super init])) {
    webView_ = [webView retain];
    webDriverId_ = [webDriverId copy];
  }
  return self;
}

- (void)dealloc {
  [webView_ release];
  [webDriverId_ release];
  [super dealloc];
}

#pragma mark NDWebElement methods

+ (NDWebElement *)elementWithWebView:(UIWebView *)webView
                         webDriverId:(NSString *)webDriverId {
  return [[[NDWebElement alloc] initWithWebView:webView
                                    webDriverId:webDriverId] autorelease];
}

// Creates a WebDriver API style dictionary to identify this element.
- (NSDictionary *)idDictionary {
  return [NSDictionary dictionaryWithObject:webDriverId_ forKey:kElementIdKey];
}

// Executes a WebDriver atom defined in atoms.h.
- (id)executeAtom:(const char* const)atom
         withArgs:(NSArray *)args {
  return [NDJavaScriptRunner
          executeJsFunction:[NSString stringWithUTF8String:atom]
                   withArgs:args
                    webView:webView_];
}

// Executes a string as a JavaScript Function.
- (id)executeJsFunction:(NSString *)script
               withArgs:(NSArray *)args {
  return [NDJavaScriptRunner executeJsFunction:script
                                      withArgs:args
                                       webView:webView_];
}

#pragma mark NDElement Methods

// Get an attribute with the given name.
- (id)attribute:(NSString *)name {
  return [self executeAtom:webdriver::atoms::GET_ATTRIBUTE
                  withArgs:[NSArray arrayWithObjects:
                            [self idDictionary], name, nil]];
}

- (void)clear {
  [self executeAtom:webdriver::atoms::CLEAR
           withArgs:[NSArray arrayWithObject:[self idDictionary]]];
}

- (void)click {
  [self executeAtom:webdriver::atoms::CLICK
           withArgs:[NSArray arrayWithObject:[self idDictionary]]];
}

// Returns YES if the |UIWebView| is on the key window.
// If the |UIWebView| is on the key window but the target element is disappeard
// from DOM tree, subsequent JavaScript execution will fail with WebDriver
// exception. We will not check inside |UIWebView|.
- (BOOL)isAlive {
  return [[webView_ window] isKeyWindow];
}

// Always returns YES.
- (BOOL)isSelectable {
  // TODO(tkaizu): Check if the element is an option element, a checkbox or a
  //               radio button.
  return YES;
}

// This method is only valid on option elements, checkboxes and radio buttons.
// If the element is not selectable, throws a WebDriver exception. The exception
// should be wrapped and returned to the NativeDriver client.
- (BOOL)isSelected {
  return [[self executeAtom:webdriver::atoms::IS_SELECTED
                   withArgs:[NSArray arrayWithObject:[self idDictionary]]]
          boolValue];
}

- (BOOL)isDisplayed {
  // Check the |UIWebView| is displayed
  UIView *view = webView_;
  while (view != nil) {
    if ([view isHidden]) {
      return NO;
    }
    view = view.superview;
  }
  // Check the DOM element is displayed
  return [[self executeAtom:webdriver::atoms::IS_DISPLAYED
                   withArgs:[NSArray arrayWithObject:[self idDictionary]]]
          boolValue];
}

- (BOOL)isEnabled {
  return [[self executeAtom:webdriver::atoms::IS_ENABLED
                   withArgs:[NSArray arrayWithObject:[self idDictionary]]]
          boolValue];
}

// Get the tag name of this element, not the value of the name attribute:
// will return "input" for the element <input name="foo">
- (NSString *)tagName {
  NSString *name = [self
      executeJsFunction:@"function(){return arguments[0].tagName;}"
               withArgs:[NSArray arrayWithObject:[self idDictionary]]];
  return [name lowercaseString];
}

- (void)sendKeys:(NSArray *)array {
  NSString *stringToType = [array componentsJoinedByString:@""];
  [self executeAtom:webdriver::atoms::TYPE
           withArgs:[NSArray arrayWithObjects:[self idDictionary],
                     stringToType, nil]];
}

- (void)submit {
  [self executeAtom:webdriver::atoms::SUBMIT
           withArgs:[NSArray arrayWithObject:[self idDictionary]]];
}

- (NSString *)text {
  return [self executeAtom:webdriver::atoms::GET_TEXT
                  withArgs:[NSArray arrayWithObject:[self idDictionary]]];
}

#pragma mark findElements methods

// Converts an element |query| understood by the WebDriver wire protocol to a
// locator strategy supported by the browser automation atoms.
- (NSDictionary *)buildLocator:(NSString *)by
                         value:(NSString *)value {
  NSString *strategy = [wireProtocolToAtomsStrategy objectForKey:by];
  if (strategy == nil) {
    NSString *message =
        [NSString stringWithFormat:@"Unsupported strategy: %@", by];
    @throw [NSException webDriverExceptionWithMessage:message
                                        andStatusCode:EUNHANDLEDERROR];
  }
  return [NSDictionary dictionaryWithObject:value forKey:strategy];
}

// Finds elements inside this element. Returns an array of |NDWebElement|.
// This method can be executed without webDriverId. If webDriverId is nil, finds
// all elements inside the webView.
- (NSArray *)findElementsBy:(NSString *)by
                      value:(NSString *)value
                   maxCount:(NSUInteger)maxCount {
  // Convert query to atoms.h format.
  NSDictionary *locator = [self buildLocator:by value:value];

  // If webDriverId is nil, find from top level. Otherwise, find from this
  // element.
  NSArray *args = nil;
  if (webDriverId_) {
    args = [NSArray arrayWithObjects:locator, [self idDictionary], nil];
  } else {
    args = [NSArray arrayWithObject:locator];
  }

  // Execute atom.
  NSArray *webResults = nil;
  if (maxCount == 1U) {
    // To get better performance, use FIND_ELEMENT if searching only 1 element.
    NSDictionary *firstFound = [self executeAtom:webdriver::atoms::FIND_ELEMENT
                                        withArgs:args];
    // FIND_ELEMENT returns NSNull if no element was found. It should not be
    // added to the results.
    if (![firstFound isKindOfClass:[NSNull class]]) {
      webResults = [NSArray arrayWithObject:firstFound];
    }
  } else {
    webResults = [self executeAtom:webdriver::atoms::FIND_ELEMENTS
                          withArgs:args];
    // FIND_ELEMENTS returns 0-length array if no element was found. No special
    // handling required here.
  }

  // Convert results to NDWebElement.
  NSMutableArray *results = [NSMutableArray array];
  for (NSDictionary *foundDictionary in webResults) {
    if (maxCount != kFindEverything && [results count] >= maxCount) {
      break;
    }
    NSString *foundWebDriverId = [foundDictionary objectForKey:kElementIdKey];
    [results addObject:[NDWebElement elementWithWebView:webView_
                                            webDriverId:foundWebDriverId]];
  }
  return results;
}

// Finds elements inside specified webView. Returns an array of |NDWebElement|.
+ (NSArray *)findElementsBy:(NSString *)by
                      value:(NSString *)value
                   maxCount:(NSUInteger)maxCount
                    webView:(UIWebView *)webView {
  NDWebElement *rootElement = [NDWebElement elementWithWebView:webView
                                                   webDriverId:nil];
  return [rootElement findElementsBy:by value:value maxCount:maxCount];
}

@end
