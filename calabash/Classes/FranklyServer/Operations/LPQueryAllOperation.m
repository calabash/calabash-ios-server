//
//  LPQueryAllOperation.m
//  Created by Karl Krukow on 29/07/12.
//  Copyright (c) 2012 LessPainful. All rights reserved.
//

#import "LPQueryAllOperation.h"
#import "LPJSONUtils.h"


@implementation LPQueryAllOperation
- (NSString *) description {
  return [NSString stringWithFormat:@"Query All: %@", _arguments];
}


- (SEL) parseValuesFromArray:(NSArray *) arr withArgs:(NSMutableArray *) args {
  NSMutableString *selStr = [NSMutableString stringWithCapacity:32];
  for (NSDictionary *selPart in arr) {
    NSString *as = [selPart objectForKey:@"as"];
    if (as) {
      NSMutableDictionary *mdict = [[selPart mutableCopy] autorelease];
      [mdict removeObjectForKey:@"as"];
      selPart = mdict;
    }

    NSString *key = [[selPart keyEnumerator] nextObject];

    [selStr appendFormat:@"%@:", key];
    id tgt = [selPart objectForKey:key];
    if (as) {
      Class asClass = NSClassFromString(as);
      if (asClass) {
        if ([tgt isKindOfClass:[NSArray class]]) {
          NSMutableArray *subArgs = [NSMutableArray array];
          SEL sel = [self parseValuesFromArray:tgt withArgs:subArgs];

          NSMethodSignature *sig = [asClass methodSignatureForSelector:sel];
          if (!sig || ![asClass respondsToSelector:sel]) {
            NSLog(@"*****");
            return nil;
          }
          NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sig];

          [self invoke:invocation withTarget:asClass args:subArgs selector:sel
             signature:sig];

          id objValue;
          [invocation getReturnValue:(void **) &objValue];
          tgt = objValue ? objValue : [NSNull null];
        } else {
          tgt = [asClass performSelector:NSSelectorFromString(tgt)];
        }
      }
    }
    [args addObject:tgt];
  }
  return NSSelectorFromString(selStr);
}


- (id) performWithTarget:(UIView *) _view error:(NSError **) error {
  id target = _view;

  if ([_arguments count] <= 0) {
    return [LPJSONUtils jsonifyObject:_view];
  }
  for (NSInteger i = 0; i < [_arguments count]; i++) {
    id selObj = [_arguments objectAtIndex:i];
    id objValue;
    int intValue;
    unsigned int uintValue;
    long longValue;
    char *charPtrValue;
    char charValue;
    short shortValue;
    float floatValue;
    double doubleValue;
    SEL sel = nil;

    NSMutableArray *args = [NSMutableArray array];

    if ([selObj isKindOfClass:[NSString class]]) {
      sel = NSSelectorFromString(selObj);
    } else if ([selObj isKindOfClass:[NSDictionary class]]) {
      sel = [self parseValuesFromArray:[NSArray arrayWithObject:selObj]
                              withArgs:args];
    } else if ([selObj isKindOfClass:[NSArray class]]) {
      sel = [self parseValuesFromArray:selObj withArgs:args];
    }

    NSMethodSignature *sig = [target methodSignatureForSelector:sel];
    if (!sig || ![target respondsToSelector:sel]) {
      return @"*****";
    }
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sig];

    if (![self invoke:invocation withTarget:target args:args selector:sel
            signature:sig]) {
      return nil;
    }


    const char *type = [[invocation methodSignature] methodReturnType];
    NSString *returnType = [NSString stringWithFormat:@"%s", type];
    const char *trimmedType = [[returnType substringToIndex:1]
            cStringUsingEncoding:NSASCIIStringEncoding];
    switch (*trimmedType) {
      case '@':[invocation getReturnValue:(void **) &objValue];
        if (objValue == nil) {
          return nil;
        } else {
          if (i == [_arguments count] - 1) {
            return [LPJSONUtils jsonifyObject:objValue];
          } else {
            target = objValue;
            continue;
          }
        }
      case 'i':[invocation getReturnValue:(void **) &intValue];
        return [NSNumber numberWithInt:intValue];
      case 'I':[invocation getReturnValue:(void **) &uintValue];
        return [NSNumber numberWithUnsignedInteger:uintValue];
      case 's':[invocation getReturnValue:(void **) &shortValue];
        return [NSNumber numberWithShort:shortValue];
      case 'd':[invocation getReturnValue:(void **) &doubleValue];
        return [NSNumber numberWithDouble:doubleValue];
      case 'f':[invocation getReturnValue:(void **) &floatValue];
        return [NSNumber numberWithFloat:floatValue];
      case 'l':[invocation getReturnValue:(void **) &longValue];
        return [NSNumber numberWithLong:longValue];
      case '*':[invocation getReturnValue:(void **) &charPtrValue];
        return [NSString stringWithFormat:@"%s", charPtrValue];
      case 'c':[invocation getReturnValue:(void **) &charValue];
        return [NSString stringWithFormat:@"%d", charValue];
      case '{': {
        NSUInteger length = [[invocation methodSignature] methodReturnLength];
        void *buffer = (void *) malloc(length);
        [invocation getReturnValue:buffer];
        NSValue *value = [[[NSValue alloc] initWithBytes:buffer objCType:type]
                autorelease];

        if ([returnType rangeOfString:@"{CGRect"].location == 0) {
          CGRect *rec = (CGRect *) buffer;
          return [NSDictionary dictionaryWithObjectsAndKeys:[value description], @"description",
                                                            [NSNumber numberWithFloat:rec->origin.x], @"X",
                                                            [NSNumber numberWithFloat:rec->origin.y], @"Y",
                                                            [NSNumber numberWithFloat:rec->size.width], @"Width",
                                                            [NSNumber numberWithFloat:rec->size.height], @"Height",
                                                            nil];
        } else if ([returnType rangeOfString:@"{CGPoint="].location == 0) {
          CGPoint *point = (CGPoint *) buffer;
          return [NSDictionary dictionaryWithObjectsAndKeys:[value description], @"description",
                                                            [NSNumber numberWithFloat:point->x], @"X",
                                                            [NSNumber numberWithFloat:point->y], @"Y",
                                                            nil];
        } else if ([returnType isEqualToString:@"{?=dd}"]) {
          double *doubles = (double *) buffer;
          double d1 = *doubles;
          doubles++;
          double d2 = *doubles;
          return [NSArray arrayWithObjects:[NSNumber numberWithDouble:d1],
                                           [NSNumber numberWithDouble:d2], nil];
        } else {
          return [value description];
        }
      }
    }
  }

  return nil;
}


- (BOOL) invoke:(NSInvocation *) invocation withTarget:(id) target args:(NSMutableArray *) args selector:(SEL) sel signature:(NSMethodSignature *) sig {
  [invocation setSelector:sel];
  for (NSInteger i = 0, N = [args count]; i < N; i++) {
    id arg = [args objectAtIndex:i];
    const char *cType = [sig getArgumentTypeAtIndex:i + 2];
    switch (*cType) {
      case '@': {
        if ([arg isEqual:@"__self__"]) {
          arg = target;
        }
        [invocation setArgument:&arg atIndex:i + 2];
        break;
      }
      case 'i': {
        NSInteger intVal = [arg integerValue];
        [invocation setArgument:&intVal atIndex:i + 2];
        break;
      }
      case 'I': {
        NSInteger uIntVal = [arg unsignedIntegerValue];
        [invocation setArgument:&uIntVal atIndex:i + 2];
        break;
      }
      case 's': {
        short shVal = [arg shortValue];
        [invocation setArgument:&shVal atIndex:i + 2];
        break;
      }
      case 'd': {
        double dbVal = [arg doubleValue];
        [invocation setArgument:&dbVal atIndex:i + 2];
        break;
      }
      case 'f': {
        float fltVal = [arg floatValue];
        [invocation setArgument:&fltVal atIndex:i + 2];
        break;
      }
      case 'l': {
        long lngVal = [arg longValue];
        [invocation setArgument:&lngVal atIndex:i + 2];
        break;
      }
      case '*': {
        const char *cstringValue = [arg cStringUsingEncoding:NSUTF8StringEncoding];
        [invocation setArgument:&cstringValue atIndex:i + 2];
        break;
      }
      case 'c': {
        char chVal = [arg charValue];
        [invocation setArgument:&chVal atIndex:i + 2];
        break;
      }
      case '{': {
        //not supported yet
        if (strcmp(cType, "{CGPoint=ff}") == 0) {
          CGPoint point;
          CGPointMakeWithDictionaryRepresentation((CFDictionaryRef) arg,
                  &point);
          [invocation setArgument:&point atIndex:i + 2];
          break;
        } else if (strcmp(cType, "{CGRect={CGPoint=ff}{CGSize=ff}}") == 0) {
          CGRect rect;
          CGRectMakeWithDictionaryRepresentation((CFDictionaryRef) arg, &rect);
          [invocation setArgument:&rect atIndex:i + 2];
          break;
        }
        @throw [NSString stringWithFormat:@"not yet support struct args: %@",
                                          sig];
      }
    }
  }
  [invocation setTarget:target];
  @try {
    [invocation invoke];
  }
  @catch (NSException *exception) {
    NSLog(@"Perform %@ with target %@ caught %@: %@", NSStringFromSelector(sel),
            target, [exception name], [exception reason]);
    return NO;
  }
  return YES;
}


@end
