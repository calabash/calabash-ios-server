//
//  LPSharedUIATextField.m
//  LPSimpleExample
//
//  Created by Karl Krukow on 23/11/14.
//  Copyright (c) 2014 Xamarin. All rights reserved.
//

#import "LPSharedUIATextField.h"
#import "LPJSONUtils.h"
#import "LPLog.h"

const NSString *LPSharedUIATextFieldId = @"__calabash_uia_channel";
const NSString *LPSharedUIATextFieldSyncRequest =  @"{\"type\":\"syncRequest\"}";

@interface LPSharedUIATextField ()
@property(atomic, assign) BOOL isSynchronizing;
@property(atomic, assign) id<LPUIAResponseReceiver> uiaDelegate;
@end


@implementation LPSharedUIATextField

+ (LPSharedUIATextField *) sharedTextField {
  static LPSharedUIATextField *sharedTextField = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedTextField = [[LPSharedUIATextField alloc] init];
  });
  return sharedTextField;
}

-(void)setUIADelegate:(id<LPUIAResponseReceiver>)delegate {
  self.uiaDelegate = delegate;
}


- (id) init {
  self = [super init];
  if (self) {
    self.isSynchronized = NO;
    self.isSynchronizing = NO;
    self.currentMessage = nil;
    self.hidden = NO;
    self.accessibilityIdentifier = (NSString*)LPSharedUIATextFieldId;
    self.alpha = 0;
    self.enabled = NO;
    self.frame = CGRectMake(0,0,1,1);
    self.userInteractionEnabled = YES;
    self.clearsContextBeforeDrawing = NO;
  }
  return self;
}

- (void) dealloc {
  self.currentMessage = nil;
  self.uiaDelegate = nil;
  [super dealloc];
}

-(NSString*)text {
  @synchronized(self) {
    return [super text];
  }
}

-(void)setText:(NSString *)newText {
  [LPLog debug:@"LPSharedUIATextField set value called: %@",newText];
  NSString *oldText = self.text;
  if (oldText == newText || [newText isEqualToString:self.text]) {
    return;
  }
  NSDictionary *message = newText ? [LPJSONUtils deserializeDictionary:newText] : nil;
  @synchronized(self) {
    self.currentMessage = message;
    [super setText:newText];
  }
  if (self.currentMessage) {
    [LPLog debug:@"LPSharedUIATextField handle event %@", self.currentMessage];
    [self handleUIACommandEvent];
  }

}

- (void)handleUIACommandEvent
{
  if (self.isSynchronizing) {
    if ([self currentMessageIsSynchronizationDone]) {
      [LPSharedUIATextField cancelPreviousPerformRequestsWithTarget:self];
      [self detachFromKeyWindow];
      [LPLog debug:@"LPSharedUIATextField Synchronization with UIAutomation done"];
      self.currentMessage = nil;
      [self setText:nil];
      self.isSynchronizing = NO;
      self.isSynchronized = YES;
      return;
    }
  }
  else if ([self currentMessageIsResponse]) {
    NSDictionary *message = [self.currentMessage retain];
    [self setText:nil];
    [LPLog debug:@"LPSharedUIATextField sending response to delegate %@", message];
    [self.uiaDelegate sharedUIATextField:self didReceiveUIAResponse:message];
    [message release];
  }
}



-(BOOL)currentMessageIsResponse {
  return [[self currentMessageType] isEqualToString:@"response"];
}
-(BOOL)currentMessageIsSynchronizationDone {
  return [[self currentMessageType] isEqualToString:@"syncDone"];
}
-(NSString*)currentMessageType {
  return [self.currentMessage objectForKey:@"type"];
}

-(void)synchronizeWithUIAutomation {
  [LPLog debug:@"LPSharedUIATextField synchronizing with UIAutomation..."];
  self.isSynchronizing = YES;
  [self setText:(NSString*)LPSharedUIATextFieldSyncRequest];
  [self attachToKeyWindow];
  [self performSelector:@selector(synchronizeWithUIAutomationTimedOut) withObject:nil afterDelay:20];
}
-(void)synchronizeWithUIAutomationTimedOut {
  [LPLog debug:@"LPSharedUIATextField synchronizing with UIAutomation timed out... Aborting..."];
  self.isSynchronized = NO;
  self.isSynchronizing = NO;
  [self detachFromKeyWindow];
}

-(void)attachToKeyWindow {
  UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
  [keyWindow insertSubview:self atIndex:0];

}
-(void)detachFromKeyWindow {
  [self removeFromSuperview];
}

@end
