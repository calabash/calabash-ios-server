#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

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

@interface LPOperation ()

@end

@implementation LPOperation

#pragma mark - Memory Management

@synthesize selector = _selector;
@synthesize arguments = _arguments;
@synthesize done = _done;

- (id) initWithOperation:(NSDictionary *) operation {
  self = [super init];
  if (self != nil) {
    _selector = NSSelectorFromString([operation objectForKey:@"method_name"]);
    _arguments = [operation objectForKey:@"arguments"];
    _done = NO;
  }
  return self;
}

+ (id) operationFromDictionary:(NSDictionary *) dictionary {
  NSString *opName = [dictionary valueForKey:@"method_name"];
  LPOperation *operation = nil;
  if ([opName isEqualToString:@"scrollToRow"]) {
    operation = [[LPScrollToRowOperation alloc] initWithOperation:dictionary];
  } else if ([opName isEqualToString:@"collectionViewScrollToItemWithMark"]) {
    operation = [[LPCollectionViewScrollToItemWithMarkOperation alloc] initWithOperation:dictionary];
  } else if ([opName isEqualToString:@"scrollToRowWithMark"]) {
    operation = [[LPScrollToRowWithMarkOperation alloc] initWithOperation:dictionary];
  } else if ([opName isEqualToString:@"scroll"]) {
    operation = [[LPScrollOperation alloc] initWithOperation:dictionary];
  } else if ([opName isEqualToString:@"query"]) {
    operation = [[LPQueryOperation alloc] initWithOperation:dictionary];
  } else if ([opName isEqualToString:@"query_all"]) {
    operation = [[LPQueryAllOperation alloc] initWithOperation:dictionary];
  } else if ([opName isEqualToString:@"setText"]) {
    operation = [[LPSetTextOperation alloc] initWithOperation:dictionary];
  } else if ([opName isEqualToString:@"flash"]) {
    operation = [[LPFlashOperation alloc] initWithOperation:dictionary];
  } else if ([opName isEqualToString:@"orientation"]) {
    operation = [[LPOrientationOperation alloc] initWithOperation:dictionary];
  } else if ([opName isEqualToString:@"changeDatePickerDate"]) {
    operation = [[LPDatePickerOperation alloc] initWithOperation:dictionary];
  } else if ([opName isEqualToString:@"changeSlider"]) {
    operation = [[LPSliderOperation alloc] initWithOperation:dictionary];
  } else if ([opName isEqualToString:@"collectionViewScroll"]) {
    operation = [[LPCollectionViewScrollToItemOperation alloc]
            initWithOperation:dictionary];
  } else {
    operation = [[LPOperation alloc] initWithOperation:dictionary];
  }
  return operation;
}

- (NSString *) description {
  NSString *className = NSStringFromClass([self class]);
  return [NSString stringWithFormat:@"<%@ '%@' with arguments '%@'>",
          className, NSStringFromSelector(_selector),
          [_arguments componentsJoinedByString:@", "]];
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

  NSArray *allWindows = [LPTouchUtils applicationWindows];
  
  NSArray *result = [parser evalWith:allWindows];

  return result;
}

// map("textField", :delegate) will call this method because the :delegate
// key does not map to a known operation (see operationFromDictionary:).
// This method has problems. :(
- (id) performWithTarget:(id) target error:(NSError **) error {
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
