//
//  NDMainThreadRunner.m
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

#import "NDMainThreadRunner.h"

@interface NDMainThreadRunner ()

@property(retain) id result;

- (id)initWithSelector:(SEL)selector args:(id)args target:(id)target;
- (void)perform;

@end

@implementation NDMainThreadRunner

@synthesize result = result_;

- (id)initWithSelector:(SEL)selector args:(id)args target:(id)target {
  if (([super init])) {
    selector_ = selector;
    args_ = [args retain];
    target_ = [target retain];
  }
  return self;
}

- (void)dealloc {
  [args_ release];
  [target_ release];
  [result_ release];
  [super dealloc];
}

- (void)perform {
  self.result = [target_ performSelector:selector_ withObject:args_];
}

+ (id)performSelector:(SEL)selector args:(id)args target:(id)target {
  NDMainThreadRunner *runner =
      [[[NDMainThreadRunner alloc] initWithSelector:selector
                                               args:args
                                             target:target] autorelease];
  [runner performSelectorOnMainThread:@selector(perform)
                           withObject:nil
                        waitUntilDone:YES];
  return [runner result];
}

@end
