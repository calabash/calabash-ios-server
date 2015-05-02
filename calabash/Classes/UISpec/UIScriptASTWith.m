//
//  UIScriptASTWith.m
//  Created by Karl Krukow on 12/08/11.
//  Copyright 2011 LessPainful. All rights reserved.
//

#import "UIScriptASTWith.h"
#import "LPWebQuery.h"
#import "LPReflectUtils.h"
#import "LPWebQuery.h"
#import "LPInvoker.h"

@interface UIScriptASTWith ()

- (NSString *) stringByCoercingAccessibilityAttribute:(SEL) aSelector
                                             ofObject:(id) object;

@end

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


- (NSArray *) handleWebView:(UIView<LPWebViewProtocol> *) webView visibility:(UIScriptASTVisibilityType) visibility {
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

    return [LPWebQuery arrayByEvaluatingQuery:(NSString *) self.objectValue
                                         type:type
                                      webView:webView
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
      if ([v respondsToSelector:@selector(lpIsWebView)] && [v lpIsWebView]) {
        [res addObjectsFromArray:[self handleWebView:(UIView<LPWebViewProtocol> *) v
                                          visibility:visibility]];
        continue;
      }

      if ([self.selectorName isEqualToString:@"marked"]) {
        NSString *val = nil;
        val = [self stringByCoercingAccessibilityAttribute:@selector(accessibilityIdentifier)
                                                  ofObject:v];
        if ([val isEqualToString:(NSString *) self.objectValue]) {
          [res addObject:v];
          continue;
        }

        val = [self stringByCoercingAccessibilityAttribute:@selector(accessibilityLabel)
                                                  ofObject:v];
        if ([val isEqualToString:(NSString *) self.objectValue]) {
          [res addObject:v];
        }
        continue;
      }

      if ([self.selectorName isEqualToString:@"id"]) {
        NSString *val = [self stringByCoercingAccessibilityAttribute:@selector(accessibilityIdentifier)
                                                            ofObject:v];
        if ([val isEqualToString:(NSString *) self.objectValue]) {
          [res addObject:v];
          continue;
        }
        continue;
      }

      if ([self.selectorName isEqualToString:@"indexPath"] &&
          [self isIndexPathAddressable:v]) {
        id cell = v;
        NSIndexPath *indexPath = (NSIndexPath *) self.objectValue;
        id indexPathView = [cell superview];
        while (indexPathView && ![self supportsIndexPathAddressing:indexPathView]) {
          indexPathView = [indexPathView superview];
        }
        if (indexPathView) {
          if ([self indexPath: indexPath addressesCell: cell inIndexPathView:indexPathView]) {
            [res addObject:cell];
          }
        }
        continue;
      }

      if (self.selectorName) {
        if ([v respondsToSelector:_selector]) {
          BOOL Bvalue;
          NSMethodSignature *sig = [v methodSignatureForSelector:_selector];
          NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sig];
          const char *type = [[invocation methodSignature] methodReturnType];
          NSString *returnType = [NSString stringWithFormat:@"%s", type];
          const char *trimmedType = [[returnType substringToIndex:1]
                                     cStringUsingEncoding:NSASCIIStringEncoding];
          BOOL boolReturnType = ('B' == *trimmedType);
          BOOL objectReturnType = ('@' == *trimmedType);

          void *val = nil;
          if (boolReturnType) {
            [invocation setSelector:_selector];
            [invocation setTarget:v];
            @try {
              [invocation invoke];
            }
            @catch (NSException *exception) {
              NSLog(@"Perform %@ with target %@ caught %@: %@", _selectorName,v, [exception name], [exception reason]);
              break;
            }
            [invocation getReturnValue:(void **) &Bvalue];
          }
          else {
            val = [v performSelector:_selector];
          }
          switch (self.valueType) {
            case UIScriptLiteralTypeInteger: {
              if (boolReturnType) {
                if ((self.integerValue == 1 && Bvalue) || (self.integerValue == 0 && !Bvalue)) {
                  [res addObject:v];
                }
              }
              else if ((NSInteger) val == self.integerValue) {
                [res addObject:v];
              }
              break;
            }
            case UIScriptLiteralTypeString: {
              if (objectReturnType) {
                id valObj = (id) val;
                if (valObj != nil
                    && [valObj respondsToSelector:@selector(isEqualToString:)]
                    && ([valObj isEqualToString:(NSString *) self.objectValue])) {
                  [res addObject:v];
                }
              }
              break;
            }
            case UIScriptLiteralTypeBool:
              if (boolReturnType && self.boolValue == Bvalue) {
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

-(BOOL)isIndexPathAddressable:(id)v {
  return [v isKindOfClass:[UITableViewCell class]] || [v isKindOfClass:[UICollectionViewCell class]];
}
-(BOOL)supportsIndexPathAddressing:(id)view {
  return [view respondsToSelector:@selector(cellForRowAtIndexPath:)] ||
         [view respondsToSelector:@selector(cellForItemAtIndexPath:)];
}
-(BOOL)indexPath:(NSIndexPath*)indexPath addressesCell:(id) cell inIndexPathView:(id)indexPathView {
  id viewAtIndexPath = nil;
  if ([indexPathView respondsToSelector:@selector(cellForRowAtIndexPath:)]) {
    viewAtIndexPath = [indexPathView cellForRowAtIndexPath:indexPath];
  }
  else if ([indexPathView respondsToSelector:@selector(cellForItemAtIndexPath:)]) {
    viewAtIndexPath = [indexPathView cellForItemAtIndexPath:indexPath];
  }
  return [cell isEqual:viewAtIndexPath];
}

- (void) dealloc {
  self.selector = nil;
  self.selectorName = nil;
  self.selectorSpec = nil;
  [_objectValue release];
  _objectValue = nil;
  [super dealloc];
}

- (NSString *) stringByCoercingAccessibilityAttribute:(SEL) aSelector
                                             ofObject:(id) object {
  if (![object respondsToSelector:aSelector]) {
    NSLog(@"%@ does not respond to %@; returning nil",
          [object class], NSStringFromSelector(aSelector));
    return nil;
  }

  id attributeValue = [LPInvoker invokeSelector:aSelector withTarget:object];

  if ([attributeValue isKindOfClass:[NSString class]]) {
    return (NSString *) attributeValue;
  }

  if ([attributeValue respondsToSelector:@selector(stringValue)]) {
    return [attributeValue stringValue];
  } else {
    return nil;
  }
}

@end
