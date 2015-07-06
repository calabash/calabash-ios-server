#import "LPRecorder.h"
#import "LPCocoaLumberjack.h"

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

@end

static LPRecorder *sharedRecorder = nil;

@implementation LPRecorder

@synthesize eventList = _eventList;
@synthesize playbackDelegate = _playbackDelegate;
@synthesize playbackDoneSelector = _playbackDoneSelector;
@synthesize isRecording = _isRecording;


+ (LPRecorder *) sharedRecorder {
  if (sharedRecorder == nil) {
    sharedRecorder = [[super allocWithZone:NULL] init];
  }
  return sharedRecorder;
}


- (id) init {
  self = [super init];
  if (self) {
    _eventList = [[NSMutableArray alloc] init];
  }
  return self;
}


// todo dealloc does not playbackDelegate but it retains it
- (void) dealloc {
  [_eventList release];
  if (_playbackDelegate) {
    [_playbackDelegate release];
    _playbackDelegate = nil;
  }
  [super dealloc];
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


- (void) playbackWithCallbackDelegate:(id) callbackDelegate
                         doneSelector:(SEL) doneSelector {
  self.playbackDelegate = callbackDelegate;
  self.playbackDoneSelector = doneSelector;

  LPLogDebug(@"Calling application _playback with [self playbackDone:]");

  if ([[NSThread currentThread] isMainThread]) {
    LPLogDebug(@"Is main thread. :)");
    [[UIApplication sharedApplication] _playbackEvents:_eventList
                                        atPlaybackRate:1.0f
                                       messageWhenDone:self
                                          withSelector:@selector(finishPlaybackWithDetails:)];
  } else {
    dispatch_sync(dispatch_get_main_queue(), ^{
      LPLogDebug(@"Is not main thread. :(");
      [[UIApplication sharedApplication] _playbackEvents:_eventList
                                          atPlaybackRate:1.0f
                                         messageWhenDone:self
                                            withSelector:@selector(finishPlaybackWithDetails:)];

    });
  }
}

- (void) finishPlaybackWithDetails:(NSDictionary *)details {
  LPLogDebug(@"calling %@ on %@",
             NSStringFromSelector(_playbackDoneSelector),
             _playbackDelegate);

  [self.playbackDelegate performSelector:self.playbackDoneSelector];
}

@end
