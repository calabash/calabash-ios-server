//
//  ScrollOperation.m
//  Calabash
//
//  Created by Karl Krukow on 18/08/11.
//  Copyright (c) 2011 LessPainful. All rights reserved.
//

#import "LPScrollToRowWithIdOperation.h"

@implementation LPScrollToRowWithIdOperation

- (NSString *) description {
	return [NSString stringWithFormat:@"ScrollToRowWithId: %@",_arguments];
}


- (NSIndexPath *)indexPathForRowWithIdentifier:(NSString *) aRowId inTable:(UITableView*) table {
	NSUInteger numberOfSections = [table numberOfSections];
  for (NSUInteger section = 0; section < numberOfSections; section++) {
    NSUInteger numberOfRows = [table numberOfRowsInSection:section];
    for (NSUInteger row = 0; row < numberOfRows; row++) {
      NSIndexPath *path = [NSIndexPath indexPathForRow:row inSection:section];
      UITableViewCell *cell = [table cellForRowAtIndexPath:path];
      if ([cell.accessibilityIdentifier isEqualToString:aRowId]) {
        return path;
      }
    }
  }
  return nil;
}

// row id, scroll position, animated
- (id) performWithTarget:(UIView*)_view error:(NSError **)error {
  if ([_view isKindOfClass:[UITableView class]] == NO) {
    NSLog(@"Warning view: %@ should be a table view for scrolling to row/cell to make sense",_view);
    return nil;
  }
  
  UITableView* table = (UITableView*) _view;
  NSString *rowId = [_arguments objectAtIndex:0];
  if (rowId == nil || [rowId length] == 0) {
    NSLog(@"Warning: row id: '%@' should be non-nil and non-empty", rowId);
    return nil;
  }
  
  NSIndexPath *path = [self indexPathForRowWithIdentifier:rowId inTable:table];
  if (path == nil) {
    NSLog(@"Warning: table doesn't contain row with id '%@'", rowId);
    return nil;
  }
  
  UITableViewScrollPosition sp = UITableViewScrollPositionTop;
  BOOL animate = YES;
  
  
  if ([_arguments count] > 1) {
    NSString *scrollPositionArg = [_arguments objectAtIndex:1];
    if ([@"middle" isEqualToString:scrollPositionArg]) {
      sp = UITableViewScrollPositionMiddle;
    } else if ([@"bottom" isEqualToString:scrollPositionArg]) {
      sp = UITableViewScrollPositionBottom;
    } else if ([@"none" isEqualToString:scrollPositionArg]) {
      sp = UITableViewScrollPositionNone;
    }
  }
  
  if ([_arguments count] > 2) {
    NSNumber *ani = [_arguments objectAtIndex:2];
    animate = [ani boolValue];
  }
  
  [table scrollToRowAtIndexPath:path atScrollPosition:sp animated:animate];
  return _view;
}
@end
