//
//  LPJSONUtils.m
//  Created by Karl Krukow on 11/08/11.
//  Copyright 2011 LessPainful. All rights reserved.
//

#import "LPJSONUtils.h"
#import "LPCJSONSerializer.h"
#import "LPCJSONDeserializer.h"
#import "LPTouchUtils.h"

@implementation LPJSONUtils

+ (NSString *) serializeDictionary:(NSDictionary *) dictionary {
  LPCJSONSerializer *s = [LPCJSONSerializer serializer];
  NSError *error = nil;
  NSData *d = [s serializeDictionary:dictionary error:&error];
  if (error) {
    NSLog(@"Unable to serialize dictionary (%@), %@", error, dictionary);
  }
  NSString *res = [[NSString alloc] initWithBytes:[d bytes] length:[d length]
                                         encoding:NSUTF8StringEncoding];
  return [res autorelease];
}


+ (NSDictionary *) deserializeDictionary:(NSString *) string {
  LPCJSONDeserializer *ds = [LPCJSONDeserializer deserializer];
  NSError *error = nil;
  NSDictionary *res = [ds deserializeAsDictionary:[string dataUsingEncoding:NSUTF8StringEncoding]
                                            error:&error];
  if (error) {
    NSLog(@"Unable to deserialize  %@", string);
  }
  return res;
}


+ (NSString *) serializeArray:(NSArray *) array {
  LPCJSONSerializer *s = [LPCJSONSerializer serializer];
  NSError *error = nil;
  NSData *d = [s serializeArray:array error:&error];
  if (error) {
    NSLog(@"Unable to serialize arrayy (%@), %@", error, array);
  }
  NSString *res = [[NSString alloc] initWithBytes:[d bytes] length:[d length]
                                         encoding:NSUTF8StringEncoding];
  return [res autorelease];
}


+ (NSArray *) deserializeArray:(NSString *) string {
  LPCJSONDeserializer *ds = [LPCJSONDeserializer deserializer];
  NSError *error = nil;
  NSArray *res = [ds deserializeAsArray:[string dataUsingEncoding:NSUTF8StringEncoding]
                                  error:&error];
  if (error) {
    NSLog(@"Unable to deserialize  %@", string);
  }
  return res;
}


+ (NSString *) serializeObject:(id) obj {
  LPCJSONSerializer *s = [LPCJSONSerializer serializer];
  NSError *error = nil;
  NSData *d = [s serializeObject:obj error:&error];
  if (error) {
    NSLog(@"Unable to serialize object (%@), %@", error, [obj description]);
  }
  NSString *res = [[NSString alloc] initWithBytes:[d bytes] length:[d length]
                                         encoding:NSUTF8StringEncoding];
  return [res autorelease];
}


+ (id) jsonifyObject:(id) object {
  if (!object) {return nil;}
  if ([object isKindOfClass:[UIColor class]]) {
    //todo special handling
    return [object description];
  }
  if ([object isKindOfClass:[UIView class]]) {
    UIView *v = (UIView *) object;
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithObjectsAndKeys:NSStringFromClass(
            [object class]), @"class", nil];

    NSString *lbl = [object accessibilityLabel];
    if (lbl) {
      [result setObject:lbl forKey:@"label"];
    } else {
      [result setObject:[NSNull null] forKey:@"label"];
    }

    // TODO LPJSONUtils.h has bug around accessibilityIdentifier
    if ([object respondsToSelector:@selector(accessibilityIdentifier)]) {

      NSString *aid = [object accessibilityIdentifier];
      if (aid) {
        [result setObject:aid forKey:@"id"];
      } else {
        [result setObject:[NSNull null] forKey:@"id"];
      }
    }
    if ([object respondsToSelector:@selector(text)]) {

      NSString *text = [object text];
      if (text) {
        [result setObject:text forKey:@"text"];
      } else {
        [result setObject:[NSNull null] forKey:@"text"];
      }
    }



    CGRect frame = [object frame];

    UIWindow *frontWindow = [[UIApplication sharedApplication] keyWindow];
    UIWindow *window = [LPTouchUtils windowForView:v];
    if (window) {
      CGRect rect = [window convertRect:v.bounds fromView:v];
      rect = [frontWindow convertRect:rect fromWindow:window];
      CGPoint center = [LPTouchUtils centerOfFrame:rect shouldTranslate:YES];
      NSDictionary *rectDic = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:center.x], @"center_x",
                                                                         [NSNumber numberWithFloat:center.y], @"center_y",
                                                                         [NSNumber numberWithFloat:rect.origin.x], @"x",
                                                                         [NSNumber numberWithFloat:rect.origin.y], @"y",
                                                                         [NSNumber numberWithFloat:rect.size.width], @"width",
                                                                         [NSNumber numberWithFloat:rect.size.height], @"height",
                                                                         nil];

      [result setObject:rectDic forKey:@"rect"];
    }

    NSDictionary *frameDic = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:frame.origin.x], @"x",
                                                                        [NSNumber numberWithFloat:frame.origin.y], @"y",
                                                                        [NSNumber numberWithFloat:frame.size.width], @"width",
                                                                        [NSNumber numberWithFloat:frame.size.height], @"height",
                                                                        nil];

    [result setObject:frameDic forKey:@"frame"];

    [result setObject:[object description] forKey:@"description"];

    return result;
  }
  if ([object respondsToSelector:@selector(isAccessibilityElement)] && [object isAccessibilityElement]) {
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithObjectsAndKeys:NSStringFromClass([object class]), @"class", nil];
    
    NSString *lbl = [object accessibilityLabel];
    if (lbl) {
      [result setObject:lbl forKey:@"label"];
    } else {
      [result setObject:[NSNull null] forKey:@"label"];
    }
    
    if ([object respondsToSelector:@selector(accessibilityIdentifier)]) {
      
      NSString *aid = [object accessibilityIdentifier];
      if (aid) {
        [result setObject:aid forKey:@"id"];
      } else {
        [result setObject:[NSNull null] forKey:@"id"];
      }
    }

    if ([object respondsToSelector:@selector(accessibilityHint)]) {
      
      NSString *accHint = [object accessibilityHint];
      if (accHint) {
        [result setObject:accHint forKey:@"hint"];
      } else {
        [result setObject:[NSNull null] forKey:@"hint"];
      }
    }
    if ([object respondsToSelector:@selector(accessibilityValue)]) {
      
      NSString *accVal = [object accessibilityValue];
      if (accVal) {
        [result setObject:accVal forKey:@"value"];
      } else {
        [result setObject:[NSNull null] forKey:@"value"];
      }
    }
    if ([object respondsToSelector:@selector(text)]) {

      NSString *text = [object text];
      if (text) {
        [result setObject:text forKey:@"text"];
      } else {
        [result setObject:[NSNull null] forKey:@"text"];
      }
    }

    CGRect frame = [object accessibilityFrame];
    CGPoint center = [LPTouchUtils centerOfFrame:frame shouldTranslate:YES];
    NSDictionary *frameDic = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:frame.origin.x], @"x",
                              [NSNumber numberWithFloat:frame.origin.y], @"y",
                              [NSNumber numberWithFloat:frame.size.width], @"width",
                              [NSNumber numberWithFloat:frame.size.height], @"height",
                              [NSNumber numberWithFloat:center.x], @"center_x",
                              [NSNumber numberWithFloat:center.y], @"center_y",
                              nil];
    
    [result setObject:frameDic forKey:@"rect"];
    
    [result setObject:[object description] forKey:@"description"];


    return result;


    
  }


  LPCJSONSerializer *s = [LPCJSONSerializer serializer];
  NSError *error = nil;
  if (![s serializeObject:object error:&error] || error) {
    return [object description];
  }
  return object;
}
@end
