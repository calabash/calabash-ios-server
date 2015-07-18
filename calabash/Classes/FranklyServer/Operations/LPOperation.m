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
#import "LPInvoker.h"
#import "LPInvocationResult.h"
#import "LPInvocationError.h"
#import "LPCocoaLumberjack.h"
#import "LPJSONUtils.h"

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

/*
 Examples:

 # Calls this method, because :text is not a defined operation.
 > map("textField", :text)
 => [ "old text" ]

 # Does not call this method, because :setText is a defined operation -
 # see operationFromDictionary:
 > map("textField", :setText, 'new text')
 => [ <UITextField ... > ]

 # Calls this method, because 'setText:' is not a defined operation.
 > map("textField", 'setText:', 'newer text')
 => [ "<VOID>" ]

 The map function is the only caller I have found.  My guess is that this is
 legacy code that is not expected to be hit by casual users.  Most arbritary
 invocations pass through `query` and not map.
 */
- (id) performWithTarget:(id) target error:(NSError *__autoreleasing*) error {
  LPInvocationResult *invocationResult;
  invocationResult = [LPInvoker invokeOnMainThreadSelector:self.selector
                                                withTarget:target
                                                 arguments:self.arguments];
  id returnValue = nil;

  if ([invocationResult isError]) {
    NSString *description = [invocationResult description];
    if (error) {
      NSDictionary *userInfo =
      @{
        NSLocalizedDescriptionKey : description
        };
      *error = [NSError errorWithDomain:@"CalabashServer"
                                   code:1
                               userInfo:userInfo];
    }
    LPLogError(@"Could not call selector '%@' on target '%@' - %@",
               NSStringFromSelector(self.selector), target, description);
    returnValue = description;
  } else {
    if ([invocationResult isNSNull]) {
      returnValue = nil;
    } else {
      returnValue = invocationResult.value;
    }
  }

  return returnValue;
}

@end
