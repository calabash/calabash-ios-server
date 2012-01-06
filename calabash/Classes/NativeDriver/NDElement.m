//
//  NDElement.m
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

#import "NDElement.h"

// For native and web
NSString *kById = @"id";
NSString *kByClassName = @"class name";

// For native
NSString *kByText = @"text";
NSString *kByPartialText = @"partial text";
NSString *kByPlaceholder = @"placeholder";
NSString *kPlaceholderAttribute = @"placeholder";

// For web
NSString *kByCssSelector = @"css selector";
NSString *kByLinkText = @"link text";
NSString *kByName = @"name";
NSString *kByPartialLinkText = @"partial link text";
NSString *kByTagName = @"tag name";
NSString *kByXpath = @"xpath";

@implementation NDElement

// Returns true if the find-by strategy is only valid for native elements.
+ (BOOL)isNativeOnlyStrategy:(NSString *)by {
  return ([by isEqualToString:kByText]
          || [by isEqualToString:kByPartialText]
          || [by isEqualToString:kByPlaceholder]);
}

// Returns true if the find-by strategy is only valid for web elements.
+ (BOOL)isWebOnlyStrategy:(NSString *)by {
  return ([by isEqualToString:kByCssSelector]
          || [by isEqualToString:kByLinkText]
          || [by isEqualToString:kByName]
          || [by isEqualToString:kByPartialLinkText]
          || [by isEqualToString:kByTagName]
          || [by isEqualToString:kByXpath]);
}

// type empty string.
- (void)clear {
  [self sendKeys:[NSArray array]];
}

// Returns text attribute.
- (NSString *)text {
  return [self attribute:@"text"];
}

// Implemented in the subclasses if this feature is available.
- (NSString *)attribute:(NSString *)name {
  return nil;
}

// Implemented in the subclasses if this feature is available.
- (void)click {
  // do nothing
}

// Implemented in the subclasses if this feature is available.
- (NSArray *)findElementsBy:(NSString *)by
                      value:(NSString *)value
                   maxCount:(NSUInteger)maxCount {
  return nil;
}

// Implemented in the subclasses if this feature is available.
- (BOOL)isAlive {
  return YES;
}

// Implemented in the subclasses if this feature is available.
- (BOOL)isSelectable {
  return NO;
}

// Implemented in the subclasses if this feature is available.
- (BOOL)isSelected {
  return NO;
}

// Implemented in the subclasses if this feature is available.
- (BOOL)isDisplayed {
  return YES;
}

// Implemented in the subclasses if this feature is available.
- (BOOL)isEnabled {
  return YES;
}

// Implemented in the subclasses if this feature is available.
- (NSString *)tagName {
  return nil;
}

// Implemented in the subclasses if this feature is available.
- (void)sendKeys:(NSArray *)array {
  // do nothing
}

// type return key.
- (void)submit {
  [self sendKeys:[NSArray arrayWithObject:@"\n"]];
}

@end

