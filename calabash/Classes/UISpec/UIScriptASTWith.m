//
//  UIScriptASTWith.m
//  Created by Karl Krukow on 12/08/11.
//  Copyright 2011 LessPainful. All rights reserved.
//

#import "UIScriptASTWith.h"
#import "LPWebQuery.h"
#import "LPReflectUtils.h"

@implementation UIScriptASTWith
@synthesize selectorName = _selectorName;
@synthesize selector = _selector;
@synthesize objectValue = _objectValue;
@synthesize boolValue = _boolValue;
@synthesize boolValue2;
@synthesize integerValue = _integerValue;
@synthesize integerValue2;
@synthesize timeout;
@synthesize selectorSpec;

@synthesize valueType = _valueType;
@synthesize valueType2;


- (id) initWithSelectorName:(NSString *) selectorName {
  self = [super init];
  if (self) {
    self.valueType = UIScriptLiteralTypeUnknown;
    self.valueType2 = UIScriptLiteralTypeUnknown;
    self.selectorName = selectorName;
    self.selector = NSSelectorFromString(selectorName);
    self.timeout = 3;
  }
  return self;
}


- (id) initWithSelectorSpec:(NSArray *) selectorSpec_ {
  self = [super init];
  if (self) {
    self.valueType = UIScriptLiteralTypeUnknown;
    self.valueType2 = UIScriptLiteralTypeUnknown;
    self.selectorSpec = selectorSpec_;
    self.timeout = 3;
  }
  return self;
}


- (NSString *) description {
  NSString *fm = nil;
  if (self.selectorName) {
    fm = [NSString stringWithFormat:@"with %@:",
                                    NSStringFromSelector(self.selector)];
  } else {
    fm = [NSString stringWithFormat:@"with %@:", self.selectorSpec];
  }

  switch (self.valueType) {
    case UIScriptLiteralTypeIndexPath: {
      NSIndexPath *ip = (id) [self objectValue];
      return [NSString stringWithFormat:@"%@%@,%@", fm, @([ip row]), @([ip section])];
    }

    case UIScriptLiteralTypeString:
      return [NSString stringWithFormat:@"%@'%@'", fm, self.objectValue];
    case UIScriptLiteralTypeInteger:
      return [NSString stringWithFormat:@"%@%@", fm, @(self.integerValue)];
    case UIScriptLiteralTypeBool:
      return [NSString stringWithFormat:@"%@%@", fm,
                                        self.boolValue ? @"YES" : @"NO"];
    default:return @"UIScriptLiteralTypeUnknown";
  }
}


- (NSArray *) handleWebView:(UIWebView *) webView visibility:(UIScriptASTVisibilityType) visibility {
  if (!self.selectorName) {
    NSLog(@"WebView only supports css/xpath selectors");
    return [NSMutableArray array];
  }

  if (self.valueType == UIScriptLiteralTypeString) {
    LPWebQueryType type = LPWebQueryTypeCSS;
    if ([[self selectorName] isEqualToString:@"marked"]) {
      type = LPWebQueryTypeFreeText;
    } else if ([[self selectorName] isEqualToString:@"xpath"]) {
      type = LPWebQueryTypeXPATH;
    } else if ([[self selectorName] isEqualToString:@"css"]) {
      type = LPWebQueryTypeCSS;
    }

    return [LPWebQuery evaluateQuery:(NSString *) self.objectValue ofType:type
                           inWebView:webView
                    includeInvisible:visibility == UIScriptASTVisibilityTypeAll];
  } else {
    NSLog(@"Attempting to look for non string in web view");
    return [NSMutableArray array];
  }
}


- (NSMutableArray *) evalWith:(NSArray *) views direction:(UIScriptASTDirectionType) dir visibility:(UIScriptASTVisibilityType) visibility {

  NSMutableArray *res = [NSMutableArray arrayWithCapacity:8];

  for (UIView *v in views) {
    if ([v isKindOfClass:[NSDictionary class]]) {
      NSDictionary *dict = (NSDictionary *) v;
      NSString *key = NSStringFromSelector(self.selector);
      if ([[dict valueForKey:key] isEqual:self.objectValue]) {
        [res addObject:dict];
      }
    } else {
      if ([v isKindOfClass:[UIWebView class]]) {
        [res addObjectsFromArray:[self handleWebView:(UIWebView *) v
                                          visibility:visibility]];
        continue;
      }
      if ([self.selectorName isEqualToString:@"marked"]) {
        NSString *val = nil;
        if ([v respondsToSelector:@selector(accessibilityIdentifier)]) {
          val = [v accessibilityIdentifier];
          if ([val isEqualToString:(NSString *) self.objectValue]) {
            [res addObject:v];
            continue;
          }
        }
        val = [v accessibilityLabel];
        if ([val isEqualToString:(NSString *) self.objectValue]) {
          [res addObject:v];
        }
        continue;
      }
      if ([self.selectorName isEqualToString:@"id"]) {
        NSString *val = nil;
        if ([v respondsToSelector:@selector(accessibilityIdentifier)]) {
          val = [v accessibilityIdentifier];
          if ([val isEqualToString:(NSString *) self.objectValue]) {
            [res addObject:v];
            continue;
          }
        }
        continue;
      }

      if ([v isKindOfClass:[UITableViewCell class]] && [self.selectorName isEqualToString:@"indexPath"]) {
        UITableViewCell *cell = (UITableViewCell *) v;
        NSIndexPath *indexPath = (NSIndexPath *) self.objectValue;
        id tableView = [cell superview];
        while (tableView && ![tableView isKindOfClass:[UITableView class]]) {
          tableView = [tableView superview];
        }
        if (tableView) {
          UITableView *tv = (UITableView *) tableView;
          if ([indexPath isEqual:[tv indexPathForCell:cell]]) {
            [res addObject:cell];
          }
        }
        continue;
      }

      if (self.selectorName) {
        if ([v respondsToSelector:_selector]) {
          void *val = [v performSelector:_selector];
          switch (self.valueType) {
            case UIScriptLiteralTypeInteger:
              if ((NSInteger) val == self.integerValue) {
                [res addObject:v];
              }
              break;
            case UIScriptLiteralTypeString: {
              if (val != nil && ([(NSString *) val isEqualToString:(NSString *) self.objectValue])) {
                [res addObject:v];
              }
              break;
            }
            case UIScriptLiteralTypeBool:
              if (self.boolValue == (BOOL) val) {
                [res addObject:v];
              }
              break;
            default:break;
          }
        }
      } else {
        NSError *error = nil;
        id val = [LPReflectUtils invokeSpec:self.selectorSpec onTarget:v
                                  withError:&error];
        if (val && !error) {
          switch (self.valueType) {
            case UIScriptLiteralTypeInteger: {
              NSInteger i = [val integerValue];
              if (i == self.integerValue) {
                [res addObject:v];
              }
              break;
            }
            case UIScriptLiteralTypeString: {
              if (val != nil && ([(NSString *) val isEqualToString:(NSString *) self.objectValue])) {
                [res addObject:v];
              }
              break;
            }
            case UIScriptLiteralTypeBool: {
              BOOL b = [val boolValue];
              if (self.boolValue == b) {
                [res addObject:v];
              }
              break;
            }
            default:break;
          }
        }
      }
    }
  }
  return res;
}


- (void) dealloc {
  self.selector = nil;
  self.selectorName = nil;
  self.selectorSpec = nil;
  [_objectValue release];
  _objectValue = nil;
  [super dealloc];
}


@end
