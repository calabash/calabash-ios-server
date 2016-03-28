//
//  UIScriptASTWith.m
//  Created by Karl Krukow on 12/08/11.
//  Copyright 2011 LessPainful. All rights reserved.
//

#import "UIScriptASTWith.h"
#import "LPWebQuery.h"
#import "LPReflectUtils.h"
#import "LPWebQuery.h"
#import "LPWebViewUtils.h"
#import "LPCocoaLumberjack.h"
#import "LPConstants.h"

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

- (NSArray *)handleIFrameQueryFromIFrameResult:(NSDictionary *)iFrameResult {
  NSDictionary *iframeInfo = iFrameResult[IFRAME_INFO_KEY];
  
  LPWebQueryType queryType = [iframeInfo[QUERY_TYPE_KEY] unsignedIntegerValue];
  UIView<LPWebViewProtocol> *webView = iFrameResult[WEBVIEW_KEY];
  NSString *iframeSelector = iframeInfo[QUERY_KEY];
  
  if (iframeSelector == nil) {
    LPLogError(@"Missing query string for IFrame Query");
    return [NSArray array];
  } else if (webView == nil) {
    LPLogError(@"Missing webview for IFrame query");
    return [NSArray array];
  }
  
  NSArray *results = [LPWebQuery arrayByEvaluatingQuery:(NSString *)self.objectValue
                                          frameSelector:iframeSelector
                                                   type:queryType
                                                webView:webView
                                       includeInvisible:YES];
  /*
   *  And now we must offset the iframe query results by the frame (left, top) of the original 
   *  iframe.
   */
  NSMutableArray *ret = [NSMutableArray arrayWithCapacity:results.count];
  
  NSDictionary *iFrameRect = iFrameResult[@"rect"];
  float xOffset, yOffset;
  
  xOffset = [iFrameRect[@"left"] floatValue];
  yOffset = [iFrameRect[@"top"] floatValue];
  
  for (NSDictionary *result in results) {
    NSMutableDictionary *mResult = [result mutableCopy];
    
    NSMutableDictionary *mRect = [mResult[@"rect"] mutableCopy];
    mRect[@"x"] = @([mRect[@"x"] floatValue] + xOffset);
    mRect[@"left"] = @([mRect[@"left"] floatValue] + xOffset);
    mRect[@"center_x"] = @([mRect[@"center_x"] floatValue] + xOffset);
    mRect[@"y"] = @([mRect[@"y"] floatValue] + yOffset);
    mRect[@"top"] = @([mRect[@"top"] floatValue] + yOffset);
    mRect[@"center_y"] = @([mRect[@"center_y"] floatValue] + yOffset);
    
    mResult[@"rect"] = mRect;
    [ret addObject:mResult];

    [mResult release];
    [mRect release];
  }
  return ret;
}


- (NSArray *) handleWebView:(UIView<LPWebViewProtocol> *) webView visibility:(UIScriptASTVisibilityType) visibility {
  if (!self.selectorName) {
    LPLogError(@"WebView only supports css/xpath selectors");
    return [NSMutableArray array];
  }

  if (self.valueType == UIScriptLiteralTypeString) {
    LPWebQueryType type = LPWebQueryTypeCSS;
    if ([[self selectorName] isEqualToString:@"xpath"]) {
      type = LPWebQueryTypeXPATH;
    } else if ([[self selectorName] isEqualToString:@"css"]) {
      type = LPWebQueryTypeCSS;
    }

    return [LPWebQuery arrayByEvaluatingQuery:(NSString *) self.objectValue
                                frameSelector:WEBVIEW_DOCUMENT_FRAME_SELECTOR
                                         type:type
                                      webView:webView
                             includeInvisible:visibility == UIScriptASTVisibilityTypeAll];
  } else {
    LPLogError(@"Attempting to look for non string in web view");
    return [NSMutableArray array];
  }
}


- (NSMutableArray *) evalWith:(NSArray *) views direction:(UIScriptASTDirectionType) dir visibility:(UIScriptASTVisibilityType) visibility {

  NSMutableArray *res = [NSMutableArray arrayWithCapacity:8];

  for (id result in views) {
    if ([result isKindOfClass:[NSDictionary class]]) {
      NSString *key = NSStringFromSelector(self.selector);
      if ([result[key] isEqual:self.objectValue]) {
        [res addObject:result];
      } else if ([LPWebViewUtils isIFrameResult:result]) {
        [res addObjectsFromArray:[self handleIFrameQueryFromIFrameResult:result]];
      }
    } else {
      UIView *v = (UIView *)result;
      if ([LPWebViewUtils isWebView:v]) {
        [res addObjectsFromArray:[self handleWebView:(UIView<LPWebViewProtocol> *) v
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
              LPLogError(@"Perform %@ with target %@ caught %@: %@", _selectorName,v, [exception name], [exception reason]);
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


@end
