#import "LPRecorder.h"
#import "LPCocoaLumberjack.h"

#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

@interface UIApplication (Recording)

- (void) _addRecorder:(id) recorder;
- (void) _removeRecorder:(id) recorder;
- (void) _playbackEvents:(NSArray *) events
          atPlaybackRate:(float) playbackRate
         messageWhenDone:(id) target
            withSelector:(SEL) selector;

@end

@interface LPRecorder ()

@property(strong) NSMutableArray *eventList;
@property(strong) id playbackDelegate;
@property(assign) SEL playbackDoneSelector;

// Passed to private _playbackEvents: method
// Responsible for calling back to the route that called
// playbackWithDelegate:doneSelector.
- (void) finishPlaybackWithDetails:(NSDictionary *) details;

- (instancetype) init_private;
@end

static LPRecorder *sharedRecorder = nil;

@implementation LPRecorder

#pragma mark - Memory Management

@synthesize eventList = _eventList;
@synthesize playbackDelegate = _playbackDelegate;
@synthesize playbackDoneSelector = _playbackDoneSelector;
@synthesize isRecording = _isRecording;

- (instancetype) init {
  @throw [NSException exceptionWithName:@"Cannot call init"
                                 reason:@"This is a singleton class"
                               userInfo:nil];
}

- (instancetype) init_private {
  self = [super init];
  if (self) {
    _eventList = [[NSMutableArray alloc] init];
  }
  return self;
}

+ (LPRecorder *) sharedRecorder {
  static LPRecorder *shared = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    shared = [[LPRecorder alloc] init_private];
  });
  return shared;
}

- (void) record {
  [_eventList removeAllObjects];

  NSLog(@"Starting recording");
  _isRecording = YES;
  [[UIApplication sharedApplication] _addRecorder:self];
}


- (NSArray *) events {
  return [NSArray arrayWithArray:_eventList];
}


- (void) saveToFile:(NSString *) path {
  NSLog(@"Saving events to file: %@", path);

  if ([_eventList writeToFile:path atomically:YES]) {
    NSLog(@"succeeded");
  }
}


- (void) stop {
  NSLog(@"Stopping recording");
  _isRecording = NO;
  [[UIApplication sharedApplication] _removeRecorder:self];
}


- (void) recordApplicationEvent:(NSDictionary *) event {
  NSLog(@"Recorded event: %@", event);
  [_eventList addObject:event];
}


- (void) load:(NSArray *) events {
  [_eventList setArray:events];
}


- (void) loadFromFile:(NSString *) path {
  [_eventList setArray:[NSMutableArray arrayWithContentsOfFile:path]];
}

// It is tempting to replace this delegate dance with a block.
// The private call to _playbackEvents does pass an dictionary of 'details'.
// However, none of the 'delegates' consumes those details.
- (void) playbackWithCallbackDelegate:(id) callbackDelegate
                         doneSelector:(SEL) doneSelector {
  self.playbackDelegate = callbackDelegate;
  self.playbackDoneSelector = doneSelector;
  NSArray *events = [self events];

  // It is tempting to remove this check and just call the block.
  // For some reason, however, it does not work with the pre Jun 2015
  // CocoaHTTPServer sources.
  //
  // It may be safe to remove this branch _after_ the new CocoaHTTPServer
  // sources are incorporated.
  if ([[NSThread currentThread] isMainThread]) {
    [[UIApplication sharedApplication] _playbackEvents:events
                                        atPlaybackRate:1.0f
                                       messageWhenDone:self
                                          withSelector:@selector(finishPlaybackWithDetails:)];
  } else {
    dispatch_sync(dispatch_get_main_queue(), ^{
      [[UIApplication sharedApplication] _playbackEvents:events
                                          atPlaybackRate:1.0f
                                         messageWhenDone:self
                                            withSelector:@selector(finishPlaybackWithDetails:)];

    });
  }
}

- (void) finishPlaybackWithDetails:(NSDictionary *)details {
  id delegate = self.playbackDelegate;
  SEL selector = self.playbackDoneSelector;

  NSInvocation *invocation;

  NSMethodSignature *signature;
  signature = [[delegate class] instanceMethodSignatureForSelector:selector];

  invocation = [NSInvocation invocationWithMethodSignature:signature];

  [invocation setTarget:delegate];
  [invocation setSelector:selector];
  [invocation setArgument:&details atIndex:2];
  [invocation retainArguments];

  // Has void type.
  [invocation invoke];

  self.playbackDoneSelector = nil;
  self.playbackDelegate = nil;
}

@end
