#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif
//
//  LPJSONUtils.m
//  Created by Karl Krukow on 11/08/11.
//  Copyright 2011 LessPainful. All rights reserved.
//

#import "LPJSONUtils.h"
#import "LPCJSONSerializer.h"
#import "LPCJSONDeserializer.h"
#import "LPTouchUtils.h"
#import "LPDevice.h"
#import "LPOrientationOperation.h"
#import "LPInvoker.h"
#import "LPInvocationResult.h"
#import "LPInvocationError.h"
#import <math.h>
#import "LPDecimalRounder.h"
#import "LPCocoaLumberjack.h"

CGFloat LP_MAX_FLOAT = INT32_MAX * 1.0;
CGFloat LP_MIN_FLOAT = INT32_MIN * 1.0;

@interface LPJSONUtils ()

// If the target responds to the selector, invoke the selector on the target and
// insert the value into the dictionary.  LPInvoker is responsible for ensuring
// the value is not nil and is an object (not a primative).
// @todo Add check for nil key
+ (void) dictionary:(NSMutableDictionary *) dictionary
    setObjectforKey:(NSString *) key
         whenTarget:(id) target
         respondsTo:(SEL) selector;

// If the target does not respond to the selector, insert NSNull for key.
// @todo Add check for nil key
+ (void) dictionary:(NSMutableDictionary *) dictionary
 ensureObjectForKey:(NSString *) key
         withTarget:(id) target
           selector:(SEL) selector;

+ (void) insertHitPointIntoMutableDictionary:(NSMutableDictionary *) dictionary;

+ (NSMutableDictionary*)serializeRect:(CGRect)rect;
+ (NSNumber*)normalizeFloat:(CGFloat) x;

@end

@implementation LPJSONUtils

+ (void) dictionary:(NSMutableDictionary *) dictionary
    setObjectforKey:(NSString *) key
         whenTarget:(id) target
         respondsTo:(SEL) selector {
  if ([target respondsToSelector:selector]) {
    LPInvocationResult *result;
    result = [LPInvoker invokeZeroArgumentSelector:selector
                                        withTarget:target];

    [dictionary setObject:result.value forKey:key];
  }
}

+ (void) dictionary:(NSMutableDictionary *) dictionary
 ensureObjectForKey:(NSString *) key
         withTarget:(id) target
           selector:(SEL) selector {
  if ([target respondsToSelector:selector]) {
    LPInvocationResult *result;
    result = [LPInvoker invokeZeroArgumentSelector:selector
                                        withTarget:target];
    [dictionary setObject:result.value forKey:key];
  } else {
    [dictionary setObject:[NSNull null] forKey:key];
  }
}

+ (NSString *) serializeDictionary:(NSDictionary *) dictionary {
  LPCJSONSerializer *serializer = [LPCJSONSerializer serializer];
  return [serializer stringByEnsuringSerializationOfDictionary:dictionary];
}

+ (NSDictionary *) deserializeDictionary:(NSString *) string {
  LPCJSONDeserializer *ds = [LPCJSONDeserializer deserializer];
  NSError *error = nil;
  NSDictionary *res = [ds deserializeAsDictionary:[string dataUsingEncoding:NSUTF8StringEncoding]
                                            error:&error];
  if (error) {
    LPLogDebug(@"Unable to deserialize  %@", string);
  }
  return res;
}

+ (NSString *) serializeArray:(NSArray *) array {
  LPCJSONSerializer *serializer = [LPCJSONSerializer serializer];
  return [serializer stringByEnsuringSerializationOfArray:array];
}

+ (NSArray *) deserializeArray:(NSString *) string {
  LPCJSONDeserializer *ds = [LPCJSONDeserializer deserializer];
  NSError *error = nil;
  NSArray *res = [ds deserializeAsArray:[string dataUsingEncoding:NSUTF8StringEncoding]
                                  error:&error];
  if (error) {
    LPLogDebug(@"Unable to deserialize  %@", string);
  }
  return res;
}

+ (NSString *) serializeObject:(id) obj {
  LPCJSONSerializer *serializer = [LPCJSONSerializer serializer];
  return [serializer stringByEnsuringSerializationOfObject:obj];
}

+ (id) jsonifyObject:(id) object {
  return [self jsonifyObject:object fullDump:NO];
}

+(id)jsonifyObject:(id)object fullDump:(BOOL)dump {
  if (!object) {return nil;}
  if ([object isKindOfClass:[UIColor class]]) {
    UIColor *color = (UIColor*)object;
    CGFloat red, green, blue, alpha;
    [color getRed:&red green:&green blue:&blue alpha:&alpha];
    return @{@"red": @(red), @"green": @(green), @"blue": @(blue), @"alpha": @(alpha), @"type": NSStringFromClass([object class])};
  }
  else if ([object isKindOfClass:[UIView class]]) {
    NSMutableDictionary *viewJson = [self dictionaryByEncodingView:(UIView*) object];
    if (dump) {
      [LPJSONUtils insertHitPointIntoMutableDictionary:viewJson];
      if (viewJson[@"class"]) {
        viewJson[@"type"] = viewJson[@"class"];
        [viewJson removeObjectForKey:@"class"];
      }
    }
    return viewJson;
  }
  else if ([object respondsToSelector:@selector(isAccessibilityElement)] && [object isAccessibilityElement]) {
    NSMutableDictionary *viewJson = [self jsonifyAccessibilityElement:object];
    if (dump) {
      [self dumpAccessibilityElement:object toDictionary:viewJson];
      if (viewJson[@"class"]) {
        viewJson[@"type"] = viewJson[@"class"];
        [viewJson removeObjectForKey:@"class"];
      }

    }
    return viewJson;
  } else if ([object respondsToSelector:@selector(accessibilityElementCount)] &&
             [object respondsToSelector:@selector(accessibilityElementAtIndex:)] &&
             [object accessibilityElementCount] != NSNotFound &&
             [object accessibilityElementCount] > 0 ) {
    NSMutableDictionary *viewJson = [self jsonifyAccessibilityElement: object];
    if (dump) {
      [self dumpAccessibilityElement: object toDictionary:viewJson];
      if (viewJson[@"class"]) {
        viewJson[@"type"] = viewJson[@"class"];
        [viewJson removeObjectForKey:@"class"];
      }

    }
    return viewJson;
  }

  // Sometimes we don't actually want to return an JSON encoded string because
  // the object will be passed throught the serializer again and we'd end up
  // with results like this:
  //
  // > query('tabBarButton', :accessibilityLabel)
  // [
  // [0] "\"Buttons\"",
  // [1] "\"Text\"",
  // [2] "\"Date\"",
  // [3] "\"Scrolling Views\"",
  // [4] "\"Sliders\""
  // ]
  //
  // To my eye this is clearly a bug in this method; we should never exit
  // this method with invalid JSON. Fixing this is beyond the scope of this
  // pull-request. -jjm
  LPCJSONSerializer *serializer = [LPCJSONSerializer serializer];
  NSData *data = [serializer serializeObject:object error:nil];
  if (!data) {
    return [object description];
  } else {
    return object;
  }
}

+ (NSMutableDictionary *) dictionaryByEncodingView:(id) object {
  NSMutableDictionary *result = [NSMutableDictionary dictionary];
  result[@"class"] = NSStringFromClass([object class]);

  // v might not be a UIView.
  if ([object isKindOfClass:[UIView class]]) {
    if ([LPTouchUtils isViewVisible:(UIView*)object]) {
      result[@"visible"] = @(1);
    } else {
      result[@"visible"] = @(0);
    }
  }

  // Be defensive: user *might* have a view with a 'nil' description.
  [LPJSONUtils dictionary:result
          setObjectforKey:@"description"
               whenTarget:object
               respondsTo:@selector(description)];

  // Selector is defined for NSObject(UIKit), but better to be safe than sorry.
  [LPJSONUtils dictionary:result
          setObjectforKey:@"accessibilityElement"
               whenTarget:object
               respondsTo:@selector(isAccessibilityElement)];

  [LPJSONUtils dictionary:result
          setObjectforKey:@"label"
               whenTarget:object
               respondsTo:@selector(accessibilityLabel)];

  [LPJSONUtils dictionary:result
          setObjectforKey:@"id"
               whenTarget:object
               respondsTo:@selector(accessibilityIdentifier)];

  [LPJSONUtils dictionary:result
          setObjectforKey:@"text"
               whenTarget:object
               respondsTo:@selector(text)];

  [LPJSONUtils dictionary:result
          setObjectforKey:@"selected"
               whenTarget:object
               respondsTo:@selector(isSelected)];

  [LPJSONUtils dictionary:result
          setObjectforKey:@"enabled"
               whenTarget:object
               respondsTo:@selector(isEnabled)];

  [LPJSONUtils dictionary:result
          setObjectforKey:@"alpha"
               whenTarget:object
               respondsTo:@selector(alpha)];

  // Setting value.
  NSString *valueKey = @"value";
  if ([object respondsToSelector:@selector(value)]) { // value
    [LPJSONUtils dictionary:result
            setObjectforKey:valueKey
                 whenTarget:object
                 respondsTo:@selector(value)];
  } else if ([object respondsToSelector:@selector(text)]) { // text
    [LPJSONUtils dictionary:result
            setObjectforKey:valueKey
                 whenTarget:object
                 respondsTo:@selector(text)];
  } else if ([object respondsToSelector:@selector(accessibilityValue)]) { // accessibilityValue
    [LPJSONUtils dictionary:result
            setObjectforKey:@"value"
                 whenTarget:object
                 respondsTo:@selector(accessibilityValue)];
  }

  if ([object respondsToSelector:@selector(frame)]) {
    // TODO:  The type on `v` is id which means it can be any object.  Should
    // be able to use the LPInvoker, but it is not (yet) able to handle
    // selectors that return structs.
    NSMethodSignature *signature;
    signature = [[object class] instanceMethodSignatureForSelector:@selector(frame)];
    const char *cEncoding = [signature methodReturnType];
    NSString *encoding = [NSString stringWithCString:cEncoding
                                            encoding:NSASCIIStringEncoding];
    if ([encoding rangeOfString:@"{CGRect"].location == 0) {
      CGRect frame = [object frame];
      result[@"frame"] = [self serializeRect: frame];
    }
  }

  if ([object isKindOfClass:[UIView class]]) {
    UIView *view = (UIView *)object;
    UIWindow *window = [LPTouchUtils windowForView:view];

    if (window) {

      CGPoint center = [LPTouchUtils centerOfView:view];

      CGRect rect = [window convertRect:view.bounds fromView:view];

      UIWindow *frontWindow = [[UIApplication sharedApplication] keyWindow];

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
      if ([frontWindow respondsToSelector:@selector(convertRect:toCoordinateSpace:)]) {
        rect = [frontWindow convertRect:rect toCoordinateSpace:frontWindow];
      } else {
        rect = [frontWindow convertRect:rect fromWindow:window];
      }
#else
      rect = [frontWindow convertRect:rect fromWindow:window];
#endif
      NSMutableDictionary *rectDict = [self serializeRect:rect];
      rectDict[@"center_x"] = [self normalizeFloat:center.x];
      rectDict[@"center_y"] = [self normalizeFloat:center.y];

      result[@"rect"] = rectDict;
    }
  }

  return result;
}

+ (NSMutableDictionary*)serializeRect:(CGRect)rect {
  CGFloat x = rect.origin.x;
  CGFloat y = rect.origin.y;
  CGFloat width = rect.size.width;
  CGFloat height = rect.size.height;

  return
  [@{
     @"x" : [self normalizeFloat:x],
     @"y" : [self normalizeFloat:y],
     @"width" : [self normalizeFloat:width],
     @"height" : [self normalizeFloat:height]
     } mutableCopy];
}

+ (NSNumber*)normalizeFloat:(CGFloat) x {
  if (isinf(x)) {
    return (x == INFINITY ? @(LP_MAX_FLOAT) : @(LP_MIN_FLOAT));
  } else if (x == CGFLOAT_MIN) {
    return @(LP_MIN_FLOAT);
  } else if (x == CGFLOAT_MAX) {
    return @(LP_MAX_FLOAT);
  } else if (x > LP_MAX_FLOAT) {
    return @(LP_MAX_FLOAT);
  } else if (x < LP_MIN_FLOAT) {
    return @(LP_MIN_FLOAT);
  } else {
    LPDecimalRounder *rounder = [LPDecimalRounder new];
    CGFloat rounded = [rounder round:x];
    return @(rounded);
  }
}

+(NSMutableDictionary*)jsonifyAccessibilityElement:(id)object {
  NSMutableDictionary *result = [NSMutableDictionary dictionary];

  result[@"class"] = NSStringFromClass([object class]);
  result[@"visible"] = @(1);
  result[@"accessibilityElement"] = @(1);

  // Be defensive: user *might* have a view with a 'nil' description.
  [LPJSONUtils dictionary:result
       ensureObjectForKey:@"description"
               withTarget:object
                 selector:@selector(description)];

  [LPJSONUtils dictionary:result
       ensureObjectForKey:@"label"
               withTarget:object
                 selector:@selector(accessibilityLabel)];

  [LPJSONUtils dictionary:result
       ensureObjectForKey:@"id"
               withTarget:object
                 selector:@selector(accessibilityIdentifier)];

  [LPJSONUtils dictionary:result
       ensureObjectForKey:@"hint"
               withTarget:object
               selector:@selector(accessibilityHint)];

  [LPJSONUtils dictionary:result
       ensureObjectForKey:@"value"
               withTarget:object
                 selector:@selector(accessibilityValue)];

  [LPJSONUtils dictionary:result
       ensureObjectForKey:@"text"
               withTarget:object
                 selector:@selector(text)];

  [LPJSONUtils dictionary:result
          setObjectforKey:@"selected"
               whenTarget:object
               respondsTo:@selector(isSelected)];

  [LPJSONUtils dictionary:result
          setObjectforKey:@"enabled"
               whenTarget:object
               respondsTo:@selector(isEnabled)];

  [LPJSONUtils dictionary:result
          setObjectforKey:@"alpha"
               whenTarget:object
               respondsTo:@selector(alpha)];

  NSDictionary *frameDictionary = nil;

  SEL frameSelector = @selector(accessibilityFrame);
  if ([object respondsToSelector:frameSelector]) {
    @try {
      CGRect frame = [object accessibilityFrame];
      CGPoint center = [LPTouchUtils centerOfFrame:frame shouldTranslate:YES];
      NSMutableDictionary *tmp = [self serializeRect:frame];
      tmp[@"center_x"] = [self normalizeFloat:center.x];
      tmp[@"center_y"] = [self normalizeFloat:center.y];
      frameDictionary = [NSDictionary dictionaryWithDictionary:tmp];
    } @catch (NSException *exception) {
      LPLogError(@"LPJSONUtils caught an exception in jsonifyAccessibilityElement:");
      LPLogError(@"%@", exception);
      LPLogError(@"while trying to find the accessibilityFrame of this object:");
      LPLogError(@"%@", object);
    }
  }

  if (frameDictionary) {
    result[@"rect"] = frameDictionary;
  } else {
    result[@"rect"] = [NSNull null];
  }

  return result;
}


+ (void) insertHitPointIntoMutableDictionary:(NSMutableDictionary *) dictionary {
  SEL selector = @selector(setObject:forKey:);
  if (![dictionary respondsToSelector:selector]) { return ; }

  id centerX = [NSNull null];
  id centerY = [NSNull null];

  NSDictionary *rect = dictionary[@"rect"];
  if (rect) {
    id tmpX = rect[@"center_x"];
    if (tmpX) { centerX = tmpX; }

    id tmpY = rect[@"center_y"];
    if (tmpY) { centerY = tmpY; }
  }

  dictionary[@"hit-point"] = @{@"x" : centerX, @"y" : centerY};
}

+(void)dumpAccessibilityElement:(id)object toDictionary:(NSMutableDictionary*)viewJson {
  NSDictionary *rect = viewJson[@"rect"];

  viewJson[@"hit-point"] = @{@"x": rect[@"center_x"], @"y": rect[@"center_y"]};

  viewJson[@"accessibilityTraits"] = [self accessibilityTraits:object];
}

+(NSArray*)accessibilityTraits:(id)view {
  if (![view respondsToSelector:@selector(accessibilityTraits)]) {
    return @[];
  }
  NSMutableArray *traitStrings = [[NSMutableArray alloc]initWithCapacity:8];
  UIAccessibilityTraits traits = [view accessibilityTraits];
  if ((traits & UIAccessibilityTraitButton)) {
    [traitStrings addObject:@"button"];
  }
  if ((traits & UIAccessibilityTraitLink)) {
    [traitStrings addObject:@"link"];
  }
  if ((traits & UIAccessibilityTraitSearchField)) {
    [traitStrings addObject:@"searchField"];
  }
  if ((traits & UIAccessibilityTraitImage)) {
    [traitStrings addObject:@"image"];
  }
  if ((traits & UIAccessibilityTraitSelected)) {
    [traitStrings addObject:@"selected"];
  }
  if ((traits & UIAccessibilityTraitPlaysSound)) {
    [traitStrings addObject:@"playsSound"];
  }
  if ((traits & UIAccessibilityTraitKeyboardKey)) {
    [traitStrings addObject:@"keyboardKey"];
  }
  if ((traits & UIAccessibilityTraitStaticText)) {
    [traitStrings addObject:@"staticText"];
  }
  if ((traits & UIAccessibilityTraitSummaryElement)) {
    [traitStrings addObject:@"summaryElement"];
  }
  if ((traits & UIAccessibilityTraitNotEnabled)) {
    [traitStrings addObject:@"notEnabled"];
  }
  if ((traits & UIAccessibilityTraitUpdatesFrequently)) {
    [traitStrings addObject:@"updatesFrequently"];
  }
  if ((traits & UIAccessibilityTraitStartsMediaSession)) {
    [traitStrings addObject:@"mediaSession"];
  }
  if ((traits & UIAccessibilityTraitAdjustable)) {
    [traitStrings addObject:@"adjustable"];
  }
  if ((traits & UIAccessibilityTraitAllowsDirectInteraction)) {
    [traitStrings addObject:@"allowsDirectInteraction"];
  }
  if ((traits & UIAccessibilityTraitCausesPageTurn)) {
    [traitStrings addObject:@"causesPageTurn"];
  }
  if ((traits & UIAccessibilityTraitHeader)) {
    [traitStrings addObject:@"header"];
  }
  return traitStrings;
}

@end
