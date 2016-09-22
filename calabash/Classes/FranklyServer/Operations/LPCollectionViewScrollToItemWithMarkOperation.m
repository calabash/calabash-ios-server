//
//  LPCollectionViewScrollToItemWithMarkOperation.m
//  calabash
//
//  Created by Julien Curro on 18/02/14.
//  Copyright (c) 2014 Xamarin. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPCollectionViewScrollToItemWithMarkOperation.h"
#import "LPCocoaLumberjack.h"

@implementation LPCollectionViewScrollToItemWithMarkOperation

- (NSIndexPath *) indexPathForItemWithMark:(NSString *) aMark
                              inCollection:(UICollectionView *) aCollection {
  NSUInteger numberOfSections = [aCollection numberOfSections];

  id<UICollectionViewDataSource> dataSource = aCollection.dataSource;

  NSIndexPath *path = nil;
  UICollectionViewCell *cell = nil;

  for (NSUInteger section = 0; section < numberOfSections; section++) {
    NSUInteger numberOfItems = [aCollection numberOfItemsInSection:section];
    for (NSUInteger item = 0; item < numberOfItems; item++) {
      path = [NSIndexPath indexPathForItem:item inSection:section];
      cell = [dataSource collectionView:aCollection cellForItemAtIndexPath:path];

      if ([self view:cell hasMark:aMark]) { return path; }
      if ([self view:cell hasSubviewWithMark:aMark]) { return path; }
      if ([self view:cell.contentView hasSubviewWithMark:aMark]) { return path; }
    }
  }
  return nil;
}

//                 required      optional     optional
// _arguments ==> [item mark, scroll position, animated]
- (id) performWithTarget:(id) target error:(NSError *__autoreleasing*) error {

  if (!target) {
    LPLogWarn(@"Cannot perform operation on nil target");
    return nil;
  }

  if (![[target class] isSubclassOfClass:[UICollectionView class]]) {
    LPLogWarn(@"View: %@ should be an instance of UICollectionView but found '%@'",
              target, NSStringFromClass([target class]));
    return nil;
  }

  NSArray *arguments = self.arguments;

  UICollectionView *collection = (UICollectionView *) target;
  NSString *itemId = [arguments objectAtIndex:0];
  if (itemId == nil || [itemId length] == 0) {
    LPLogWarn(@"Item id: '%@' should be non-nil and non-empty", itemId);
    return nil;
  }
  
  NSIndexPath *path = [self indexPathForItemWithMark:itemId inCollection:collection];
  if (path == nil) {
    LPLogWarn(@"Collection doesn't contain item with id '%@'", itemId);
    return nil;
  }
  
  UICollectionViewScrollPosition scrollPosition = UICollectionViewScrollPositionTop;
  BOOL animate = YES;
  
  
  if ([arguments count] > 1) {
    NSString *position = [arguments objectAtIndex:1];
    
    NSDictionary *opts =
    @{
      @"top" : @(UICollectionViewScrollPositionTop),
      @"center_vertical" : @(UICollectionViewScrollPositionCenteredVertically),
      @"bottom" : @(UICollectionViewScrollPositionBottom),
      @"left" : @(UICollectionViewScrollPositionLeft),
      @"center_horizontal" : @(UICollectionViewScrollPositionCenteredHorizontally),
      @"right" : @(UICollectionViewScrollPositionRight)
      };

    NSNumber *posNum = [opts objectForKey:position];
    
    if (!posNum) {
      LPLogWarn(@"Requesting to scroll to position '%@' but that is not one of these valid positions: '%@'",
            position, [opts allKeys]);
      return nil;
    }
    
    scrollPosition = [posNum unsignedIntegerValue];
  }
  
  if ([arguments count] > 2) {
    NSNumber *ani = [arguments objectAtIndex:2];
    animate = [ani boolValue];
  }

  [collection scrollToItemAtIndexPath:path
                     atScrollPosition:scrollPosition
                             animated:animate];
  return target;
}

@end
