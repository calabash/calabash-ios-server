#import <Foundation/Foundation.h>

/**
 NSObject on NSObject_LPAdditions category.
 http://www.tomdalling.com/blog/cocoa/why-performselector-is-more-dangerous-than-i-thought
 */
@interface NSObject (NSObject_LPAdditions)

- (id) performSelectorSafely:(SEL)aSelector;
- (BOOL) selectorReturnsObjectOrVoid:(SEL) aSelector;
- (BOOL) selectorReturnsNonObjectAndNonVoid:(SEL) aSelector;

@end
