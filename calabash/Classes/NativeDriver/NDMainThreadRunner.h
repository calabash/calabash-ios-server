//
//  NDMainThreadRunner.h
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

// Performs action on main thread. Waits until the execution finished and
// returns the result.
@interface NDMainThreadRunner : NSObject {
 @private
  SEL selector_;
  id args_;
  id target_;
  id result_;
}

// Calls [target performSelector:selector withObject:args] on main thread.
+ (id)performSelector:(SEL)selector args:(id)args target:(id)target;

@end
