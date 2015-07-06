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

  self.eventList = [[NSMutableArray alloc] init];

  return self;
}


// todo dealloc does not playbackDelegate but it retains it
- (void) dealloc {
  [_eventList release];
  [super dealloc];
}


- (void) record {
  [_eventList removeAllObjects];

  NSLog(@"Starting recording");
  _isRecording = YES;
  [[UIApplication sharedApplication] _addRecorder:self];
}


- (NSArray *) events {
  return _eventList;
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


- (void) playbackWithDelegate:(id) delegate doneSelector:(SEL) doneSelector {
  _playbackDelegate = [delegate retain];
  _playbackDoneSelector = doneSelector;

  LPLogDebug(@"Calling application _playback with [self playbackDone:]");

  if ([[NSThread currentThread] isMainThread]) {
    LPLogDebug(@"Is main thread. :)");
    [[UIApplication sharedApplication] _playbackEvents:_eventList
                                        atPlaybackRate:1.0f
                                       messageWhenDone:self
                                          withSelector:@selector(playbackDone:)];
  } else {
    dispatch_sync(dispatch_get_main_queue(), ^{
      LPLogDebug(@"Is not main thread. :(");
      [[UIApplication sharedApplication] _playbackEvents:_eventList
                                          atPlaybackRate:1.0f
                                         messageWhenDone:self
                                            withSelector:@selector(playbackDone:)];

    });
  }
}


- (void) playbackDone:(NSDictionary *) details {
  LPLogDebug(@"calling %@ on %@",
             NSStringFromSelector(_playbackDoneSelector),
             _playbackDelegate);
  [_playbackDelegate performSelector:_playbackDoneSelector];
  [_playbackDelegate release];
  _playbackDelegate = nil;
}

@end
