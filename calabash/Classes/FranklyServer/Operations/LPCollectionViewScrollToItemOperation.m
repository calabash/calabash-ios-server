#import "LPCollectionViewScrollToItemOperation.h"
#import "LPCocoaLumberjack.h"

#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

@implementation LPCollectionViewScrollToItemOperation

//                 <===               required                ===>
// _arguments ==> [item_num, section_num, scroll postion, animated]
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

  UICollectionView *collection = (UICollectionView *) target;

  NSArray *arguments = self.arguments;

  if ([arguments count] != 4) {
    LPLogWarn(@"Required 4 args but found only '%@' - %@",
            @([arguments count]), arguments);
    return nil;
  }

  NSInteger itemIndex = [[arguments objectAtIndex:0] integerValue];
  NSInteger section = [[arguments objectAtIndex:1] integerValue];

  NSInteger numSections = [collection numberOfSections];
  if (section >= numSections) {
    LPLogWarn(@"Requested to scroll to section '%@' but view only has '%@' sections",
            @(section), @(numSections));
    return nil;
  }

  NSInteger numItemInSection = [collection numberOfItemsInSection:section];
  if (itemIndex >= numItemInSection) {
    LPLogWarn(@"Requested to scroll to item '%@' in section '%@' but that section on has '%@' items",
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
    LPLogWarn(@"Requesting to scroll to position '%@' but that is not one of these valid positions: '%@'",
            position, [opts allKeys]);
    return nil;
  }

  UICollectionViewScrollPosition scrollPosition = [posNum unsignedIntegerValue];

  NSNumber *animateNum = [arguments objectAtIndex:3];
  BOOL animate = [animateNum boolValue];

  NSIndexPath *ip = [NSIndexPath indexPathForItem:itemIndex inSection:section];

  [collection scrollToItemAtIndexPath:ip
                     atScrollPosition:scrollPosition
                             animated:animate];
  return collection;
}

@end
