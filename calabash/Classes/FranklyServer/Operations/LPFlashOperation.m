//
//  FlashOperation.h
//  Created by Karl Krukow on 22/04/13.
//  Copyright (c) 2013 Xamarin. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPOperation.h"
#import "LPFlashOperation.h"
#import "LPTouchUtils.h"
#import "LPJSONUtils.h"

@implementation LPFlashOperation

- (id) performWithTarget:(id) target error:(NSError *__autoreleasing*) error {
  [LPTouchUtils flashView:target forDuration:2];
  return [LPJSONUtils jsonifyObject:target];
}

@end
