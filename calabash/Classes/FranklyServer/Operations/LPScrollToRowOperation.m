//
//  ScrollOperation.m
//  Calabash
//
//  Created by Karl Krukow on 18/08/11.
//  Copyright (c) 2011 LessPainful. All rights reserved.
//

#import "LPScrollToRowOperation.h"

@implementation LPScrollToRowOperation

- (NSString *) description {
  return [NSString stringWithFormat:@"ScrollToRow: %@", _arguments];
}


- (NSIndexPath *) indexPathForRow:(NSUInteger) row inTable:(UITableView *) table {
  NSInteger numberOfSections = [table numberOfSections];
  NSInteger i = 0;
  for (; i < numberOfSections; i++) {
    NSInteger numberOfRowsInSection = [table numberOfRowsInSection:i];
    if (row < numberOfRowsInSection) {
      return [NSIndexPath indexPathForRow:row inSection:i];
    } else {
      row -= numberOfSections;
    }
  }
  return nil;
}


- (id) performWithTarget:(UIView *) _view error:(NSError **) error {
  if ([_view isKindOfClass:[UITableView class]]) {
    UITableView *table = (UITableView *) _view;
    NSNumber *rowNum = [_arguments objectAtIndex:0];
    if ([_arguments count] >= 2) {
      NSInteger row = [rowNum integerValue];
      NSInteger sec = [[_arguments objectAtIndex:1] integerValue];
      NSIndexPath *path = [NSIndexPath indexPathForRow:row inSection:sec];

      if ((sec >= 0 && sec < [table numberOfSections]) && (row >= 0 && row < [table numberOfRowsInSection:sec])) {
        UITableViewScrollPosition sp = UITableViewScrollPositionTop;
        BOOL animate = YES;
        if ([_arguments count] >= 3) {
          NSString *pos = [_arguments objectAtIndex:2];
          if ([@"middle" isEqualToString:pos]) {
            sp = UITableViewScrollPositionMiddle;
          } else if ([@"bottom" isEqualToString:pos]) {
            sp = UITableViewScrollPositionBottom;
          } else if ([@"none" isEqualToString:pos]) {
            sp = UITableViewScrollPositionNone;
          }
        }
        if ([_arguments count] >= 4) {
          NSNumber *ani = [_arguments objectAtIndex:3];
          animate = [ani boolValue];
        }

        [table scrollToRowAtIndexPath:path atScrollPosition:sp
                             animated:animate];
        return _view;
      } else {
        NSLog(@"Warning: table doesn't contain indexPath: %@", path);
        return nil;
      }
    } else {
      NSIndexPath *indexPathForRow = [self indexPathForRow:[rowNum unsignedIntegerValue]
                                                   inTable:table];
      if (!indexPathForRow) {
        return nil;
      }
      [table scrollToRowAtIndexPath:indexPathForRow
                   atScrollPosition:UITableViewScrollPositionTop animated:YES];
      return _view;
    }
  }
  NSLog(@"Warning view: %@ should be a table view for scrolling to row/cell to make sense",
          _view);
  return nil;
}
@end
