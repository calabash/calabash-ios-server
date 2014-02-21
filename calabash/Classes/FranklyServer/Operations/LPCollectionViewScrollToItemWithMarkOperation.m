//
//  LPCollectionViewScrollToItemWithMarkOperation.m
//  calabash
//
//  Created by Julien Curro on 18/02/14.
//  Copyright (c) 2014 Xamarin. All rights reserved.
//

#import "LPCollectionViewScrollToItemWithMarkOperation.h"

@implementation LPCollectionViewScrollToItemWithMarkOperation

- (NSString *) description {
  return [NSString stringWithFormat:@"CollectionViewScrollToItem: %@",
          _arguments];
}

- (NSIndexPath *) indexPathForItemWithMark:(NSString *) aMark inCollection:(UICollectionView *) aCollection {
  NSUInteger numberOfSections = [aCollection numberOfSections];
  for (NSUInteger section = 0; section < numberOfSections; section++) {
    NSUInteger numberOfItems = [aCollection numberOfItemsInSection:section];
    for (NSUInteger item = 0; item < numberOfItems; item++) {
      NSIndexPath *path = [NSIndexPath indexPathForItem:item inSection:section];
      // only returns visible cells
      UICollectionViewCell *cell = [aCollection cellForItemAtIndexPath:path];
      if (cell == nil) {
        // ask the dataSource for the cell
        cell = [aCollection.dataSource collectionView:aCollection cellForItemAtIndexPath:path];
      }
      
      // is the cell itself marked?
      if ([self view:cell hasMark:aMark]) {return path;}
      // are any of it's subviews marked?
      if ([self cell:cell contentViewHasSubviewMarked:aMark]) {return path;}
    }
  }
  return nil;
}


//                 required      optional     optional
// _arguments ==> [item mark, scroll position, animated]
- (id) performWithTarget:(UIView *) _view error:(NSError **) error {
  
  // UICollectionView appears in iOS 6
  Class clz = NSClassFromString(@"UICollectionView");
  if (clz == nil) {
    NSLog(@"Warning UICollectionView is not supported on this version of iOS:  '%@'",
          [[UIDevice currentDevice] systemVersion]);
    return nil;
  }

  if ([_view isKindOfClass:[UICollectionView class]] == NO) {
    NSLog(@"Warning view: %@ should be a collection view for scrolling to item/cell to make sense",
          _view);
    return nil;
  }
  
  UICollectionView *collection = (UICollectionView *) _view;  
  NSString *itemId = [_arguments objectAtIndex:0];
  if (itemId == nil || [itemId length] == 0) {
    NSLog(@"Warning: item id: '%@' should be non-nil and non-empty", itemId);
    return nil;
  }
  
  NSIndexPath *path = [self indexPathForItemWithMark:itemId inCollection:collection];
  if (path == nil) {
    NSLog(@"Warning: collection doesn't contain item with id '%@'", itemId);
    return nil;
  }
  
  UICollectionViewScrollPosition scrollPosition = UICollectionViewScrollPositionTop;
  BOOL animate = YES;
  
  
  if ([_arguments count] > 1) {
    NSString *position = [_arguments objectAtIndex:1];
    
    // avoid a nasty if/else if conditional
    NSDictionary *opts = @{@"top" : @(UICollectionViewScrollPositionTop), @"center_vertical" : @(UICollectionViewScrollPositionCenteredVertically), @"bottom" : @(UICollectionViewScrollPositionBottom), @"left" : @(UICollectionViewScrollPositionLeft), @"center_horizontal" : @(UICollectionViewScrollPositionCenteredHorizontally), @"right" : @(UICollectionViewScrollPositionRight)};
    NSNumber *posNum = [opts objectForKey:position];
    
    if (posNum == nil) {
      NSLog(@"Warning:  requesting to scroll to position '%@' but that is not one of these valid positions: '%@'",
            position, [opts allKeys]);
      return nil;
    }
    
    scrollPosition = [posNum unsignedIntegerValue];
  }
  
  if ([_arguments count] > 2) {
    NSNumber *ani = [_arguments objectAtIndex:2];
    animate = [ani boolValue];
  }
  
  [collection scrollToItemAtIndexPath:path atScrollPosition:scrollPosition
                             animated:animate];
  
  return _view;
}

@end
