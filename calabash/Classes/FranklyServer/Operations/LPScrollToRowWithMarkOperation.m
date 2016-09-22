#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPScrollToRowWithMarkOperation.h"
#import "LPCocoaLumberjack.h"

@implementation LPScrollToRowWithMarkOperation

- (NSIndexPath *) indexPathForRowWithMark:(NSString *) aMark inTable:(UITableView *) aTable {
  NSUInteger numberOfSections = [aTable numberOfSections];

  id<UITableViewDataSource> dataSource = aTable.dataSource;

  NSIndexPath *path = nil;
  UITableViewCell *cell = nil;

  for (NSUInteger section = 0; section < numberOfSections; section++) {
    NSUInteger numberOfRows = [aTable numberOfRowsInSection:section];
    for (NSUInteger row = 0; row < numberOfRows; row++) {
      path = [NSIndexPath indexPathForRow:row inSection:section];

      cell = [dataSource tableView:aTable cellForRowAtIndexPath:path];

      if ([self view:cell hasMark:aMark]) { return path; }
      if ([self view:cell.textLabel hasMark:aMark]) { return path; }
      if ([self view:cell.detailTextLabel hasMark:aMark]) { return path; }
      if ([self view:cell hasSubviewWithMark:aMark]) { return path; }
      if ([self view:cell.contentView hasSubviewWithMark:aMark]) { return path; }
    }
  }
  return nil;
}

//                 required      optional     optional
// _arguments ==> [row mark, scroll position, animated]
- (id) performWithTarget:(id) target error:(NSError *__autoreleasing*) error {

  if (!target) {
    LPLogWarn(@"Cannot perform operation on nil target");
    return nil;
  }

  if (![[target class] isSubclassOfClass:[UITableView class]]) {
    LPLogWarn(@"View: %@ should be an instance of UITableView but found '%@'",
              target, NSStringFromClass([target class]));
    return nil;
  }

  NSArray *arguments = self.arguments;

  UITableView *table = (UITableView *) target;
  NSString *rowId = [arguments objectAtIndex:0];
  if (rowId == nil || [rowId length] == 0) {
    LPLogWarn(@"Row id: '%@' should be non-nil and non-empty", rowId);
    return nil;
  }

  NSIndexPath *path = [self indexPathForRowWithMark:rowId inTable:table];
  if (path == nil) {
    LPLogWarn(@"Table doesn't contain row with id '%@'", rowId);
    return nil;
  }

  UITableViewScrollPosition sp = UITableViewScrollPositionTop;
  BOOL animate = YES;


  if ([arguments count] > 1) {
    NSString *scrollPositionArg = [arguments objectAtIndex:1];
    if ([@"middle" isEqualToString:scrollPositionArg]) {
      sp = UITableViewScrollPositionMiddle;
    } else if ([@"bottom" isEqualToString:scrollPositionArg]) {
      sp = UITableViewScrollPositionBottom;
    } else if ([@"none" isEqualToString:scrollPositionArg]) {
      sp = UITableViewScrollPositionNone;
    }
  }

  if ([arguments count] > 2) {
    NSNumber *ani = [arguments objectAtIndex:2];
    animate = [ani boolValue];
  }

  [table scrollToRowAtIndexPath:path atScrollPosition:sp animated:animate];

  return target;
}

@end
