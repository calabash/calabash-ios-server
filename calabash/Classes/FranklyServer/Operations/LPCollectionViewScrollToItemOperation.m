//  Copyright (c) 2011 Xamarin. All rights reserved.
#import "LPCollectionViewScrollToItemOperation.h"

@implementation LPCollectionViewScrollToItemOperation

- (NSString *) description {
  return [NSString stringWithFormat:@"CollectionViewScrollToRow: %@",
                                    _arguments];
}


//                 <===               required                ===>
// _arguments ==> [item_num, section_num, scroll postion, animated]
- (id) performWithTarget:(UIView *) aView error:(NSError **) aError {

  // UICollectionView appears in iOS 6
  Class clz = NSClassFromString(@"UICollectionView");
  if (clz == nil) {
    NSLog(@"Warning UICollectionView is not supported on this version of iOS:  '%@'",
            [[UIDevice currentDevice] systemVersion]);
    return nil;
  }

  if ([aView isKindOfClass:[UICollectionView class]] == NO) {
    NSLog(@"Warning view: %@ should be an instance of UICollectionView but found '%@'",
            aView, aView == nil ? nil : [aView class]);
    return nil;
  }

  UICollectionView *collection = (UICollectionView *) aView;

  if ([_arguments count] != 4) {
    NSLog(@"Warning:  required 4 args but found only '%@' - %@",
            @([_arguments count]), _arguments);
    return nil;
  }

  NSInteger itemIndex = [[_arguments objectAtIndex:0] integerValue];
  NSInteger section = [[_arguments objectAtIndex:1] integerValue];

  NSInteger numSections = [collection numberOfSections];
  if (section >= numSections) {
    NSLog(@"Warning:  requested to scroll to section '%@' but view only has '%@' sections",
            @(section), @(numSections));
    return nil;
  }

  NSInteger numItemInSection = [collection numberOfItemsInSection:section];
  if (itemIndex >= numItemInSection) {
    NSLog(@"Warning:  requested to scroll to item '%@' in section '%@' but that section on has '%@' items",
            @(itemIndex), @(section), @(numItemInSection));
    return nil;
  }

  // avoid a nasty if/else if conditional
  NSDictionary *opts = @{@"top" : @(UICollectionViewScrollPositionTop), @"center_vertical" : @(UICollectionViewScrollPositionCenteredVertically), @"bottom" : @(UICollectionViewScrollPositionBottom), @"left" : @(UICollectionViewScrollPositionLeft), @"center_horizontal" : @(UICollectionViewScrollPositionCenteredHorizontally), @"right" : @(UICollectionViewScrollPositionRight)};

  NSString *position = [_arguments objectAtIndex:2];

  NSNumber *posNum = [opts objectForKey:position];
  if (posNum == nil) {
    NSLog(@"Warning:  requesting to scroll to position '%@' but that is not one of these valid positions: '%@'",
            position, [opts allKeys]);
    return nil;
  }


  UICollectionViewScrollPosition scrollPosition = [posNum unsignedIntegerValue];

  NSNumber *animateNum = [_arguments objectAtIndex:3];
  BOOL animate = [animateNum boolValue];

  NSIndexPath *ip = [NSIndexPath indexPathForItem:itemIndex inSection:section];

  [collection scrollToItemAtIndexPath:ip atScrollPosition:scrollPosition
                             animated:animate];

  return collection;
}

@end
