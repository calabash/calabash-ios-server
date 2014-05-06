//
//  UIScriptASTClassName.m
//  Created by Karl Krukow on 12/08/11.
//  Copyright 2011 LessPainful. All rights reserved.
//

#import "UIScriptASTClassName.h"
#import "LPTouchUtils.h"


@implementation UIScriptASTClassName
@synthesize className = _className;


- (id) initWithClassName:(NSString *) className {
  self = [super init];
  if (self) {
    if ([@"*" isEqualToString:className]) {
      className = @"UIView";
    }
    self.className = [[className copy] autorelease];
    _class = NSClassFromString(self.className);
  }
  return self;
}


- (NSMutableArray *) evalWith:(NSArray *) views direction:(UIScriptASTDirectionType) dir visibility:(UIScriptASTVisibilityType) visibility {

  NSMutableArray *res = [NSMutableArray arrayWithCapacity:8];

  for (UIView *view in views) {
    switch (dir) {
      case UIScriptASTDirectionTypeDescendant:
        [self evalDescWith:view result:res visibility:visibility];
        break;
      case UIScriptASTDirectionTypeChild:
        [self evalChildWith:view result:res visibility:visibility];
        break;
      case UIScriptASTDirectionTypeParent:
        [self evalParentsWith:view result:res visibility:visibility];
        break;
      case UIScriptASTDirectionTypeSibling:
        [self evalSiblingsWith:view result:res visibility:visibility];
        break;
      case UIScriptASTDirectionTypeAcc:
        [self evalAccessibilityWith:view result:res visibility:visibility];
        break;
      case UIScriptASTDirectionTypeAccParent:
        [self evalAccessibilityParentWith:view result:res visibility:visibility];
        break;
    }
  }


  return res;
}


static NSInteger sortFunction(UIView *v1, UIView *v2, void *ctx) {
  CGPoint p1 = v1.frame.origin;
  CGPoint p2 = v2.frame.origin;
  if (p1.x < p2.x) {
    return -1;
  } else if (p1.x == p2.x) {
    if (p1.y < p2.y) {
      return -1;
    } else if (p1.y == p2.y) {
      return 0;
    } else {
      return 1;
    }
  } else {
    return 1;
  }
}


- (void) addView:(UIView *) view toArray:(NSMutableArray *) res ifMatchesVisibility:(UIScriptASTVisibilityType) visibility {
  if (visibility == UIScriptASTVisibilityTypeAll || [LPTouchUtils isViewVisible:view]) {
    [res addObject:view];
  }
}

-(void)addAccessibilityElement:(UIAccessibilityElement *) view toArray:(NSMutableArray *) res ifMatchesVisibility:(UIScriptASTVisibilityType) visibility {
  if (res) {
    [res addObject:view]; //TODO how to decide visibility?
  }
}


- (void) evalDescWith:(UIView *) view result:(NSMutableArray *) res visibility:(UIScriptASTVisibilityType) visibility {
  if ([view isKindOfClass:_class]) {
    [self addView:view toArray:res ifMatchesVisibility:visibility];
  }

  for (UIView *subview in [[view subviews]
          sortedArrayUsingFunction:sortFunction context:view]) {
    [self evalDescWith:subview result:res visibility:visibility];
  }
}


- (void) evalChildWith:(UIView *) view result:(NSMutableArray *) res visibility:(UIScriptASTVisibilityType) visibility {
  for (UIView *childView in [view subviews]) {
    if ([childView isKindOfClass:_class]) {
      [self addView:childView toArray:res ifMatchesVisibility:visibility];
    }
  }
}


- (void) evalParentsWith:(UIView *) view result:(NSMutableArray *) res visibility:(UIScriptASTVisibilityType) visibility {
//    if ([view isKindOfClass:_class]) {
//        [res addObject:view];
//    }
  //I guess view itself isnt part of parents.
  UIView *parentView = [view superview];
  if ([parentView isKindOfClass:_class]) {
    [self addView:parentView toArray:res ifMatchesVisibility:visibility];
  }

  if (parentView) {
    [self evalParentsWith:parentView result:res visibility:visibility];
  }
}


- (void) evalSiblingsWith:(UIView *) view result:(NSMutableArray *) res visibility:(UIScriptASTVisibilityType) visibility {
  UIView *parentView = [view superview];
  NSArray *children = [parentView subviews];
  for (UIView *siblingOrSelf in children) {
    if (siblingOrSelf != view && [siblingOrSelf isKindOfClass:_class]) {
      [self addView:siblingOrSelf toArray:res ifMatchesVisibility:visibility];
    }
  }
}

- (void) evalAccessibilityWith:(id) view result:(NSMutableArray *) res visibility:(UIScriptASTVisibilityType) visibility {
  
  
  if ([self accessibilityMatch: view]) {
    [self addAccessibilityElement:view toArray:res ifMatchesVisibility:visibility];
  }
  
  if ([view respondsToSelector:@selector(subviews)]) {
    for (UIView *subview in [[view subviews]
                             sortedArrayUsingFunction:sortFunction context:view]) {
      [self evalAccessibilityWith:subview result:res visibility:visibility];
    }
  }

  if ([view respondsToSelector:@selector(accessibilityElementCount)]) {
    NSInteger count = [view accessibilityElementCount];
    if (count == 0 || count == NSNotFound) {
      return;
    }
    for (NSInteger i=0;i<count;i++) {
      id accEl = [view accessibilityElementAtIndex:i];
      [self evalAccessibilityWith:accEl result: res visibility:visibility];
    }
  }
}

- (void) evalAccessibilityParentWith:(id) view result:(NSMutableArray *) res visibility:(UIScriptASTVisibilityType) visibility {
  if ([view respondsToSelector:@selector(accessibilityContainer)]) {
    id container = [view accessibilityContainer];
    [self addAccessibilityElement:container toArray:res ifMatchesVisibility:visibility];
  }
}

-(BOOL)accessibilityMatch:(id)view {
  if ([view isKindOfClass:_class]) {
    return true;
  }
  if (![view isAccessibilityElement]) {
    return false;
  }
  UIAccessibilityTraits traits = [view accessibilityTraits];
  if ([@"UIView" isEqualToString:self.className]) {
    return true;
  }
  else if ([self buttonTrait] && (traits & UIAccessibilityTraitButton)) {
    return true;
  }
  else if ([self linkTrait] && (traits & UIAccessibilityTraitLink)) {
    return true;
  }
  else if ([self searchFieldTrait] && (traits & UIAccessibilityTraitSearchField)) {
    return true;
  }
  else if ([self imageTrait] && (traits & UIAccessibilityTraitImage)) {
    return true;
  }
  else if ([self selectedTrait] && (traits & UIAccessibilityTraitSelected)) {
    return true;
  }
  else if ([self playsSoundTrait] && (traits & UIAccessibilityTraitPlaysSound)) {
    return true;
  }
  else if ([self keyBoardKeyTrait] && (traits & UIAccessibilityTraitKeyboardKey)) {
    return true;
  }
  else if ([self staticTextTrait] && (traits & UIAccessibilityTraitStaticText)) {
    return true;
  }
  else if ([self summaryTrait] && (traits & UIAccessibilityTraitSummaryElement)) {
    return true;
  }
  else if ([self notEnabledTrait] && (traits & UIAccessibilityTraitNotEnabled)) {
    return true;
  }
  else if ([self updatesFrequentlyTrait] && (traits & UIAccessibilityTraitUpdatesFrequently)) {
    return true;
  }
  else if ([self startsMediaSessionTrait] && (traits & UIAccessibilityTraitStartsMediaSession)) {
    return true;
  }
  else if ([self adjustableTrait] && (traits & UIAccessibilityTraitAdjustable)) {
    return true;
  }
  else if ([self allowsDirectInteractionTrait] && (traits & UIAccessibilityTraitAllowsDirectInteraction)) {
    return true;
  }
  else if ([self causesPageTurnTrait] && (traits & UIAccessibilityTraitCausesPageTurn)) {
    return true;
  }
  else if ([self headerTrait] && (traits & UIAccessibilityTraitHeader)) {
    return true;
  }
  return false;
}

-(BOOL)buttonTrait {
  return [@"UIButton" isEqualToString:self.className] ||
            [@"UIAccessibilityTraitButton" isEqualToString:self.className];
}

-(BOOL)linkTrait {
  return [@"UILink" isEqualToString:self.className] ||
            [@"UIAccessibilityTraitLink" isEqualToString:self.className];
}

-(BOOL)searchFieldTrait {
  return [@"UISearchField" isEqualToString:self.className] ||
          [@"UIAccessibilityTraitSearchField" isEqualToString:self.className];
}

-(BOOL)imageTrait {
  return [@"UIImageView" isEqualToString:self.className] ||
          [@"UIAccessibilityTraitImage" isEqualToString:self.className];
}

-(BOOL)selectedTrait {
  return [@"UIAccessibilityTraitSelected" isEqualToString:self.className];
}

-(BOOL)playsSoundTrait {
  return [@"UIAccessibilityTraitPlaysSound" isEqualToString:self.className];
}

-(BOOL)keyBoardKeyTrait {
  return [@"UIAccessibilityTraitKeyboardKey" isEqualToString:self.className];
}

-(BOOL)staticTextTrait {
  return [@"UILabel" isEqualToString:self.className] ||
          [@"UIAccessibilityTraitStaticText" isEqualToString:self.className];
}

-(BOOL)summaryTrait {
  return [@"UIAccessibilityTraitSummaryElement" isEqualToString:self.className];
}

-(BOOL)notEnabledTrait {
  return [@"UIAccessibilityTraitNotEnabled" isEqualToString:self.className];
}

-(BOOL)updatesFrequentlyTrait {
  return [@"UIAccessibilityTraitUpdatesFrequently" isEqualToString:self.className];
}

-(BOOL)startsMediaSessionTrait {
  return [@"UIAccessibilityTraitStartsMediaSession" isEqualToString:self.className];
}

-(BOOL)adjustableTrait {
  return [@"UIAccessibilityTraitAdjustable" isEqualToString:self.className];
}

-(BOOL)allowsDirectInteractionTrait {
  return [@"UIAccessibilityTraitAllowsDirectInteraction" isEqualToString:self.className];
}

-(BOOL)causesPageTurnTrait {
  return [@"UIAccessibilityTraitCausesPageTurn" isEqualToString:self.className];
}

-(BOOL)headerTrait {
  return [@"UIAccessibilityTraitHeader" isEqualToString:self.className];
}


- (NSString *) description {
  return [NSString stringWithFormat:@"view:'%@'", self.className];
}


- (void) dealloc {
  _class = NULL;
  [_className release];
  _className = nil;
  [super dealloc];
}

@end
