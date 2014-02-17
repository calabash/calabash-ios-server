//
//  FlashOperation.h
//  Created by Karl Krukow on 22/04/13.
//  Copyright (c) 2013 Xamarin. All rights reserved.
//

#import "LPOperation.h"
#import "LPFlashOperation.h"

#import "LPTouchUtils.h"


@implementation LPFlashOperation
- (NSString *) description {
  return [NSString stringWithFormat:@"Flash: %@", _arguments];
}


- (id) performWithTarget:(UIView *) _view error:(NSError **) error {
  [LPTouchUtils flashView:_view forDuration:2];
  return _view;
}


@end
