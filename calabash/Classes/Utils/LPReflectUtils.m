//
//  LPReflectUtils.m
//  Created by Karl Krukow on 08/15/12.
//  Copyright 2012 LessPainful. All rights reserved.
//

#import "LPReflectUtils.h"

@implementation LPReflectUtils

+ (SEL) parseSpecFromArray:(NSArray *) arr withArgs:(NSMutableArray *) args {
  NSMutableString *selStr = [NSMutableString stringWithCapacity:32];
  for (id spec in arr) {
    NSString *key = nil;
    id val = nil;
    if ([spec isKindOfClass:[NSDictionary class]]) {
      NSDictionary *specDict = (NSDictionary *) spec;
      key = [[specDict keyEnumerator] nextObject];
      val = [specDict objectForKey:key];
    } else if ([spec isKindOfClass:[NSArray class]]) {
      NSArray *specArr = (NSArray *) spec;
      key = (NSString *) [specArr objectAtIndex:0];
      val = [specArr objectAtIndex:1];
    }
    [selStr appendFormat:@"%@:", key];
    [args addObject:val];
  }
  return NSSelectorFromString(selStr);
}


+ (id) invokeSpec:(id) object onTarget:(id) target withError:(NSError **) error {
  id selObj = object;
  id objValue;
  int intValue;
  long longValue;
  char *charPtrValue;
  char charValue;
  short shortValue;
  float floatValue;
  double doubleValue;
  SEL sel;

  NSMutableArray *args = [NSMutableArray array];

  if ([selObj isKindOfClass:[NSString class]]) {
    sel = NSSelectorFromString(selObj);
  } else if ([selObj isKindOfClass:[NSDictionary class]]) {
    sel = [self parseSpecFromArray:[NSArray arrayWithObject:selObj]
                          withArgs:args];
  } else if ([selObj isKindOfClass:[NSArray class]]) {
    sel = [self parseSpecFromArray:selObj withArgs:args];
  }

  NSMethodSignature *sig = [target methodSignatureForSelector:sel];
  if (!sig || ![target respondsToSelector:sel]) {
    *error = [NSError errorWithDomain:@"Calabash" code:2
                             userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"target does not respond to selector", @"reason",
                                                                                 [NSString stringWithFormat:@"applied to selector %@",
                                                                                                            NSStringFromSelector(
                                                                                                                    sel)], @"details",
                                                                                 nil]];
    return nil;
  }
  NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sig];

  [invocation setSelector:sel];
  for (NSInteger i = 0, N = [args count]; i < N; i++) {
    id arg = [args objectAtIndex:i];
    const char *cType = [sig getArgumentTypeAtIndex:i + 2];
    switch (*cType) {
      case '@':[invocation setArgument:&arg atIndex:i + 2];
        break;
      case 'i': {
        NSInteger intVal = [arg integerValue];
        [invocation setArgument:&intVal atIndex:i + 2];
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
      case '#': {
        Class cVal = NSClassFromString(arg);
        [invocation setArgument:&cVal atIndex:i + 2];
        break;
      }
      case '*':
        //not supported yet
        @throw [NSString stringWithFormat:@"not yet support struct pointers: %@",
                                          sig];
      case 'c': {
        char chVal = [arg charValue];
        [invocation setArgument:&chVal atIndex:i + 2];
        break;
      }
      case '{': {
        //not supported yet
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
    NSLog(@"Perform %@ with target %@ caught %@: %@", selObj, target,
            [exception name], [exception reason]);
    NSLog(@"not supported");
    return nil;
  }

  const char *type = [[invocation methodSignature] methodReturnType];
  NSString *returnType = [NSString stringWithFormat:@"%s", type];
  const char *trimmedType = [[returnType substringToIndex:1]
          cStringUsingEncoding:NSASCIIStringEncoding];
  // TODO default switch statement is not handled in LPReflectUtils.m
  switch (*trimmedType) {
    case '@':[invocation getReturnValue:(void **) &objValue];
      if (objValue == nil) {
        return nil;
      } else {
        return objValue;
      }
    case 'i':[invocation getReturnValue:(void **) &intValue];
      return [NSNumber numberWithInt:intValue];
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
      return [NSNumber numberWithChar:charValue];
    case '{': {
      NSUInteger length = [[invocation methodSignature] methodReturnLength];
      void *buffer = (void *) malloc(length);
      [invocation getReturnValue:buffer];
      NSValue *value = [[[NSValue alloc] initWithBytes:buffer objCType:type]
              autorelease];

      if ([returnType rangeOfString:@"{CGRect"].location == 0) {
        CGRect *rec = (CGRect *) buffer;
        return [NSDictionary dictionaryWithObjectsAndKeys:[value description], @"description",
                                                          [NSNumber numberWithFloat:rec->origin.x], @"x",
                                                          [NSNumber numberWithFloat:rec->origin.y], @"y",
                                                          [NSNumber numberWithFloat:rec->size.width], @"width",
                                                          [NSNumber numberWithFloat:rec->size.height], @"height",
                                                          nil];
      } else if ([returnType rangeOfString:@"{CGPoint="].location == 0) {
        CGPoint *point = (CGPoint *) buffer;
        return [NSDictionary dictionaryWithObjectsAndKeys:[value description], @"description",
                                                          [NSNumber numberWithFloat:point->x], @"x",
                                                          [NSNumber numberWithFloat:point->y], @"y",
                                                          nil];
      } else {
        return [value description];
      }
    }
  }
  // TODO no return in LPReflectUtils.m invokeSpec:
}

@end
