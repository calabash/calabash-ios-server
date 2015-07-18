#import "LPCollectionViewScrollToItemOperation.h"

#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

@implementation LPCollectionViewScrollToItemOperation

//                 <===               required                ===>
// _arguments ==> [item_num, section_num, scroll postion, animated]
- (id) performWithTarget:(id) target error:(NSError *__autoreleasing*) error {

  // UICollectionView appears in iOS 6
  Class clz = NSClassFromString(@"UICollectionView");
  if (clz == nil) {
    NSLog(@"Warning UICollectionView is not supported on this version of iOS:  '%@'",
            [[UIDevice currentDevice] systemVersion]);
    return nil;
  }

  if ([target isKindOfClass:[UICollectionView class]] == NO) {
    NSLog(@"Warning view: %@ should be an instance of UICollectionView but found '%@'",
            target, target == nil ? nil : [target class]);
    return nil;
  }

  UICollectionView *collection = (UICollectionView *) target;

  NSArray *arguments = self.arguments;

  if ([arguments count] != 4) {
    NSLog(@"Warning:  required 4 args but found only '%@' - %@",
            @([arguments count]), arguments);
    return nil;
  }

  NSInteger itemIndex = [[arguments objectAtIndex:0] integerValue];
  NSInteger section = [[arguments objectAtIndex:1] integerValue];

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

  NSDictionary *opts =
  @{
    @"top" : @(UICollectionViewScrollPositionTop),
    @"center_vertical" : @(UICollectionViewScrollPositionCenteredVertically),
    @"bottom" : @(UICollectionViewScrollPositionBottom),
    @"left" : @(UICollectionViewScrollPositionLeft),
    @"center_horizontal" : @(UICollectionViewScrollPositionCenteredHorizontally),
    @"right" : @(UICollectionViewScrollPositionRight)
    };

  NSString *position = [arguments objectAtIndex:2];

  NSNumber *posNum = [opts objectForKey:position];
  if (posNum == nil) {
    NSLog(@"Warning:  requesting to scroll to position '%@' but that is not one of these valid positions: '%@'",
            position, [opts allKeys]);
    return nil;
  }

  UICollectionViewScrollPosition scrollPosition = [posNum unsignedIntegerValue];

  NSNumber *animateNum = [arguments objectAtIndex:3];
  BOOL animate = [animateNum boolValue];

  NSIndexPath *ip = [NSIndexPath indexPathForItem:itemIndex inSection:section];

  if ([[NSThread currentThread] isMainThread]) {
    [collection scrollToItemAtIndexPath:ip
                       atScrollPosition:scrollPosition
                               animated:animate];
  } else {
    dispatch_sync(dispatch_get_main_queue(), ^{
      [collection scrollToItemAtIndexPath:ip
                         atScrollPosition:scrollPosition
                                 animated:animate];
    });
  }

  return collection;
}

@end
