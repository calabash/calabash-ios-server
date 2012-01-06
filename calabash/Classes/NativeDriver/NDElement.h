//
//  NDElement.h
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

enum { kFindEverything = 0U };

// For native and web
extern NSString *kById;
extern NSString *kByClassName;

// For native
extern NSString *kByText;
// matches all elements whose text contains or equals the given string.
extern NSString *kByPartialText;
extern NSString *kByPlaceholder;
extern NSString *kPlaceholderAttribute;

// For web
extern NSString *kByCssSelector;
extern NSString *kByLinkText;
extern NSString *kByName;
extern NSString *kByPartialLinkText;
extern NSString *kByTagName;
extern NSString *kByXpath;

// An interface of actions to UI elements.
@interface NDElement : NSObject

// Returns true if the find-by strategy is only valid for native elements.
+ (BOOL)isNativeOnlyStrategy:(NSString *)by;

// Returns true if the find-by strategy is only valid for web elements.
+ (BOOL)isWebOnlyStrategy:(NSString *)by;

// Get the attribute with the given name.
- (NSString *)attribute:(NSString *)name;

// Clear the contents of this element if it is an input field. Otherwise, do
// nothing.
- (void)clear;

// Simulate a click on the element.
- (void)click;

// Finds elements inside this element. Returns an array of |NDElement|.
- (NSArray *)findElementsBy:(NSString *)by
                      value:(NSString *)value
                   maxCount:(NSUInteger)maxCount;

// Return true if the element is still on key window.
- (BOOL)isAlive;

// Return true if the element is selectable.
- (BOOL)isSelectable;

// Is the element selected?
// This method is only valid on checkboxes and radio buttons.
- (BOOL)isSelected;

// Is the element displayed on the screen?
- (BOOL)isDisplayed;

// Is the element enabled?
- (BOOL)isEnabled;

// Get the tag name of this element, not the value of the name attribute:
// will return "input" for the element <input name="foo">. For native elements,
// returns the class name.
- (NSString *)tagName;

// Use this method to simulate typing into an element, which may set its value.
- (void)sendKeys:(NSArray *)array;

// Type return key into the element. If the element is Web element, this method
// will submit this form, or the form containing this element.
- (void)submit;

// The text contained in the element.
- (NSString *)text;

@end
