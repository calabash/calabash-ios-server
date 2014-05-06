//
//  Operation.m
//  Created by Karl Krukow on 14/08/11.
//  Copyright 2011 LessPainful. All rights reserved.
//

#import "LPOperation.h"
#import "LPScrollToRowOperation.h"
#import "LPScrollToRowWithMarkOperation.h"
#import "LPCollectionViewScrollToItemWithMarkOperation.h"
#import "LPScrollOperation.h"
#import "LPQueryOperation.h"
#import "LPFlashOperation.h"
#import "LPSetTextOperation.h"
#import "LPDatePickerOperation.h"
#import "LPOrientationOperation.h"
#import "LPTouchUtils.h"
#import "LPSliderOperation.h"
#import "LPCollectionViewScrollToItemOperation.h"

@implementation LPOperation

+ (id) operationFromDictionary:(NSDictionary *) dictionary {
  NSString *opName = [dictionary valueForKey:@"method_name"];
  LPOperation *op = nil;
  if ([opName isEqualToString:@"scrollToRow"]) {
    op = [[LPScrollToRowOperation alloc] initWithOperation:dictionary];
  } else if ([opName isEqualToString:@"collectionViewScrollToItemWithMark"]) {
    op = [[LPCollectionViewScrollToItemWithMarkOperation alloc] initWithOperation:dictionary];
  } else if ([opName isEqualToString:@"scrollToRowWithMark"]) {
    op = [[LPScrollToRowWithMarkOperation alloc] initWithOperation:dictionary];
  } else if ([opName isEqualToString:@"scroll"]) {
    op = [[LPScrollOperation alloc] initWithOperation:dictionary];
  } else if ([opName isEqualToString:@"query"]) {
    op = [[LPQueryOperation alloc] initWithOperation:dictionary];
  } else if ([opName isEqualToString:@"query_all"]) {
    op = [[LPQueryAllOperation alloc] initWithOperation:dictionary];
  } else if ([opName isEqualToString:@"setText"]) {
    op = [[LPSetTextOperation alloc] initWithOperation:dictionary];
  } else if ([opName isEqualToString:@"flash"]) {
    op = [[LPFlashOperation alloc] initWithOperation:dictionary];
  } else if ([opName isEqualToString:@"orientation"]) {
    op = [[LPOrientationOperation alloc] initWithOperation:dictionary];
  } else if ([opName isEqualToString:@"changeDatePickerDate"]) {
    op = [[LPDatePickerOperation alloc] initWithOperation:dictionary];
  } else if ([opName isEqualToString:@"changeSlider"]) {
    op = [[LPSliderOperation alloc] initWithOperation:dictionary];
  } else if ([opName isEqualToString:@"collectionViewScroll"]) {
    op = [[LPCollectionViewScrollToItemOperation alloc]
            initWithOperation:dictionary];
  } else {
    op = [[LPOperation alloc] initWithOperation:dictionary];
  }
  return [op autorelease];
}


+ (NSArray *) performQuery:(id) query {
  UIScriptParser *parser = nil;
  if ([query isKindOfClass:[NSString class]]) {
    parser = [[UIScriptParser alloc] initWithUIScript:(NSString *) query];
  } else if ([query isKindOfClass:[NSArray class]]) {
    parser = [[UIScriptParser alloc] initWithQuery:(NSArray *) query];
  } else {
    return nil;
  }
  [parser parse];

  NSMutableArray *views = [NSMutableArray arrayWithCapacity:32];

  NSArray *allWindows = [LPTouchUtils applicationWindows];
  
  NSArray *result = [parser evalWith:allWindows];
  [parser release];

  return result;
}


- (id) initWithOperation:(NSDictionary *) operation {
  self = [super init];
  if (self != nil) {
    _selector = NSSelectorFromString([operation objectForKey:@"method_name"]);
    _arguments = [[operation objectForKey:@"arguments"] retain];
  }
  return self;
}


- (void) dealloc {
  [_arguments release];
  _arguments = nil;
  [super dealloc];
}


- (NSString *) description {
  return [NSString stringWithFormat:@"Operation<SEL=%@,Args=%@>",
                                    NSStringFromSelector(_selector),
                                    _arguments];
}


- (id) performWithTarget:(UIView *) target error:(NSError **) error {
  NSMethodSignature *tSig = [target methodSignatureForSelector:_selector];
  NSUInteger argc = tSig.numberOfArguments - 2;
  if (argc != [_arguments count] && *error != NULL) {
    *error = [NSError errorWithDomain:@"CalabashServer" code:1
                             userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Arity mismatch", @"reason",
                                       [NSString stringWithFormat:@"%@ applied to selector %@ with %@ args",
                                        self,
                                        NSStringFromSelector(
                                                             _selector),
                                        @(argc)], @"details",
                                                                                 nil]];
    return nil;
  }

  NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:tSig];
  [invocation setSelector:_selector];

  NSInteger index = 2;
  for (NSObject *arg in _arguments) {
    [invocation setArgument:&arg atIndex:index++];
  }

  [invocation invokeWithTarget:target];


  const char *returnType = tSig.methodReturnType;

  id returnValue;
  if (!strcmp(returnType, @encode(void))) {
    returnValue = nil;
  } else if (!strcmp(returnType,
          @encode(id))) // retval is an objective c object
  {
    [invocation getReturnValue:&returnValue];
  } else {
    // handle primitive c types by wrapping them in an NSValue

    NSUInteger length = [tSig methodReturnLength];
    void *buffer = (void *) malloc(length);
    [invocation getReturnValue:buffer];

    // for some reason using [NSValue valueWithBytes:returnType] is creating instances of NSConcreteValue rather than NSValue, so
    //I'm fudging it here with case-by-case logic
    if (!strcmp(returnType, @encode(BOOL))) {
      returnValue = [NSNumber numberWithBool:*((BOOL *) buffer)];
    } else if (!strcmp(returnType, @encode(NSInteger))) {
      returnValue = [NSNumber numberWithInteger:*((NSInteger *) buffer)];
    } else if (!strcmp(returnType, @encode(float))) {
      returnValue = [NSNumber numberWithFloat:*((float *) buffer)];
    } else {
      returnValue = [[[NSValue valueWithBytes:buffer objCType:returnType] copy]
              autorelease];
    }
    free(buffer);//memory leak here, but apparently NSValue doesn't copy the passed buffer, it just stores the pointer
  }
  return returnValue;
}

@end
