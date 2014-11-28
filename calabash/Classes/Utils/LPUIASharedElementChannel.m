//
//  LPUIASharedElementChannel.m
//
//  Created by Karl Krukow on 11/23/14.
//  Copyright (c) 2014 Xamarin. All rights reserved.
//

#import "LPUIASharedElementChannel.h"
#import "LPLog.h"
#import "LPJSONUtils.h"

@implementation LPUIASharedElementChannel {
  dispatch_queue_t _uiaQueue;
  NSUInteger _scriptIndex;
}

+ (LPUIASharedElementChannel *) sharedChannel {
  static LPUIASharedElementChannel *sharedChannel = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedChannel = [[LPUIASharedElementChannel alloc] init];
  });
  return sharedChannel;
}


- (id) init {
  self = [super init];
  if (self) {
    _uiaQueue = dispatch_queue_create("calabash.uia_shared_element_queue", DISPATCH_QUEUE_SERIAL);
  }
  return self;
}

- (void) dealloc {
  dispatch_release(_uiaQueue);
  [super dealloc];
}

+ (void) runAutomationCommand:(NSString *) command then:(void (^)(NSDictionary *result)) resultHandler {
  [[LPUIASharedElementChannel sharedChannel] runAutomationCommand:command then:resultHandler];
}

- (void) runAutomationCommand:(NSString *) command then:(UIACommandHandler) resultHandler {
  if ([self initializeSharedTextField]) {
    dispatch_async(_uiaQueue, ^{
      [LPLog debug: @"Waiting for synchronization with UIAutomation..."];
      LPSharedUIATextField *sharedElement = [LPSharedUIATextField sharedTextField];
      while (!sharedElement.isSynchronized) {
        [NSThread sleepForTimeInterval:0.1];
      }
      [LPLog debug:@"LPUIASharedElementChannel synchronized..."];
      dispatch_async(dispatch_get_main_queue(), ^{
        [self doRunAutomationCommand:command then:resultHandler];
      });
    });
  }
  else {
    [self doRunAutomationCommand:command then:resultHandler];
  }
}

-(void)doRunAutomationCommand:(NSString*)command then:(UIACommandHandler) resultHandler {
  self.currentHandler = resultHandler;
  dispatch_async(_uiaQueue, ^{
    [LPLog debug: @"LPUIASharedElementChannel request execution of command: %@", command];
    [self requestExecutionOf:command];
    [LPLog debug: @"LPUIASharedElementChannel requested execution of command: %@... Awaiting response", command];
  });
}

-(BOOL)initializeSharedTextField {
  static dispatch_once_t onceToken;
  __block BOOL shouldWait = NO;
  dispatch_once(&onceToken, ^{
    LPSharedUIATextField* sharedTextField = [LPSharedUIATextField sharedTextField];
    [sharedTextField setUIADelegate:self];
    [sharedTextField synchronizeWithUIAutomation];    
    shouldWait = YES;
  });
  return shouldWait;
}

-(void)sharedUIATextField:(LPSharedUIATextField*) uiaTextField
    didReceiveUIAResponse:(NSDictionary*)uiaResponse {
  dispatch_async(_uiaQueue, ^{
    [LPLog debug: @"LPUIASharedElementChannel sharedUIATextField:didReceiveUIAResponse: %@", uiaResponse];
    if (uiaResponse) {
      _scriptIndex++;
    }
    else {
      [LPLog error: @"Error did not get a response at index %@", @(_scriptIndex)];
      [LPLog error: @"Server current index: %lu",(unsigned long) _scriptIndex];
      [LPLog error: @"Current shared element data: %@", [self rawSharedElementData]];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
      self.currentHandler(uiaResponse);
      self.currentHandler = nil;
    });
  });
}

- (void) requestExecutionOf:(NSString *) command {
  NSString *requestJSON = [LPJSONUtils serializeDictionary: @{@"command": command, @"index":@(_scriptIndex)}];
  [[LPSharedUIATextField sharedTextField] setText:requestJSON];
}


-(NSString*)rawSharedElementData {
  return [[LPSharedUIATextField sharedTextField] text];
}

@end
