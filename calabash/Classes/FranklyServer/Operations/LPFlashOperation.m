//
//  FlashOperation.h
//  Created by Karl Krukow on 22/04/13.
//  Copyright (c) 2013 Xamarin. All rights reserved.
//

#import "LPOperation.h"
#import "LPFlashOperation.h"
#import "LPTouchUtils.h"
#import "LPJSONUtils.h"

@implementation LPFlashOperation

- (NSString *) description {
  return [NSString stringWithFormat:@"Flash: %@", _arguments];
}

- (id) performWithTarget:(UIView *) _view error:(NSError **) error {

  if ([[NSThread currentThread] isMainThread]) {
    [LPTouchUtils flashView:_view forDuration:2];
  } else {
    dispatch_sync(dispatch_get_main_queue(), ^{
      [LPTouchUtils flashView:_view forDuration:2];
    });
  }
  return [LPJSONUtils jsonifyObject:_view];
}

@end
