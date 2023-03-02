//
//  UIScriptASTPredicate.m
//  LPSimpleExample
//
//  Created by Karl Krukow on 01/02/12.
//  Copyright (c) 2012 LessPainful. All rights reserved.
//

#import "UIScriptASTPredicate.h"

@implementation UIScriptASTPredicate
@synthesize predicate = _predicate;
@synthesize selector = _selector;


- (id) initWithPredicate:(NSPredicate *) pred selector:(SEL) sel {
  self = [super init];
  if (self) {
    self.predicate = pred;
    self.selector = sel;
  }
  return self;
}


- (NSString *) description {
  return [NSString stringWithFormat:@"UIScriptASTPredicate: %@",
                                    [self.predicate description]];
}


- (NSMutableArray *) evalWith:(NSArray *) views direction:(UIScriptASTDirectionType) dir visibility:(UIScriptASTVisibilityType) visibility {

  NSMutableArray *res = [NSMutableArray arrayWithCapacity:8];
  for (id v in views) {
    if ([v isKindOfClass:[NSDictionary class]] || [v respondsToSelector:self.selector]) {
      if ([self evaluatePredicateWithObject:v]) {
        [res addObject:v];
      }
    }
  }
  return res;
}

/*
 INFO:
    From iOS 15.5,
    it is added security action check that fail NSFunctionExpression with the following error:
    "(Foundation) [com.apple.Foundation:general] NSPredicate: NSFunctionExpression with selector 'accessibilityLabel' is forbidden."
    The issue is related to any accessibility property. However, it is used identifier and label properties in tests.
 */
- (BOOL)evaluatePredicateWithObject:(id)object {
  if (@available(iOS 15.5, *)) {
    NSString *identifier = @"accessibilityIdentifier";
    NSString *label = @"accessibilityLabel";
    NSString *predicateDescription = [self.predicate description];
  
    if ([predicateDescription containsString:identifier]) {
      predicateDescription = [self replaceDescription:predicateDescription withObject:object andProperty:identifier];
    }
  
    if ([predicateDescription containsString:label]) {
      predicateDescription = [self replaceDescription:predicateDescription withObject:object andProperty:label];
    }
    
    NSPredicate *newPredicate = [NSPredicate predicateWithFormat:predicateDescription];

    return [newPredicate evaluateWithObject:object];
  }
  
  return [self.predicate evaluateWithObject:object];
}

- (NSString *)replaceDescription:(NSString *) description withObject:(id) object andProperty:(NSString *) propertyName {
  NSString *propertyValue = [object performSelector:NSSelectorFromString(propertyName)];
  NSString *escapedPropertyValue = [propertyValue stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
  NSString *formattedString = [NSString stringWithFormat:@"\"%@\"", escapedPropertyValue];
  NSString *newPredicateString = [description stringByReplacingOccurrencesOfString:propertyName withString:formattedString];
  
  return newPredicateString;
}

- (void) dealloc {
  self.predicate = nil;
  [super dealloc];
}

@end
