#import <UIKit/UIKit.h>

#import "LPRecorder.h"


@interface UIApplication (Recording)

-(void)_addRecorder:(id)recorder;
-(void)_removeRecorder:(id)recorder;
-(void)_playbackEvents:(NSArray*)events atPlaybackRate:(float)playbackRate messageWhenDone:(id)target withSelector:(SEL)selector;

@end



@implementation LPRecorder
@synthesize isRecording;
@synthesize playbackDelegate;
@synthesize playbackDoneSelectorName;
@synthesize eventList;

+(LPRecorder *)sharedRecorder {
    
    static dispatch_once_t pred = 0;
    __strong static id _sharedRecorder = nil;
    dispatch_once(&pred, ^{
        _sharedRecorder = [[self alloc] init]; 
    });
    return _sharedRecorder;
}

-(id)init {
	self = [super init];

	self.eventList = [[NSMutableArray alloc] init];

	return self;
}


-(void)record {
	[self.eventList removeAllObjects];

	NSLog(@"Starting recording");
    self.isRecording = YES;
	[[UIApplication sharedApplication] _addRecorder: self];
}
-(NSArray*)events {
    return self.eventList;
}
-(void)saveToFile:(NSString*)path {
	NSLog(@"Saving events to file: %@", path);
    
	if ([self.eventList writeToFile: path atomically: YES]) {
        NSLog(@"succeeded");
    }
}

-(void)stop {
	NSLog(@"Stopping recording");
    self.isRecording = NO;
	[[UIApplication sharedApplication] _removeRecorder: self];
}

-(void)recordApplicationEvent:(NSDictionary*)event {
	NSLog(@"Recorded event: %@", event);

	[self.eventList addObject:event];
}

-(void)load:(NSArray*)events {
	NSLog(@"Loading events");

	[self.eventList setArray: events];
}

-(void)loadFromFile:(NSString*)path {
	NSLog(@"Loading events from file: %@", path);

	[self.eventList setArray: [NSMutableArray arrayWithContentsOfFile: path]];
}

-(void)playbackWithDelegate: (id)delegate doneSelector:(SEL)doneSelector {
	NSLog(@"Playback");

	self.playbackDelegate = delegate;
    
    self.playbackDoneSelectorName = NSStringFromSelector(doneSelector);
	[[UIApplication sharedApplication] _playbackEvents: self.eventList atPlaybackRate: 1.0f messageWhenDone: self withSelector: @selector(playbackDone:)];
}

-(void)playbackDone:(NSDictionary *)details {
	NSLog(@"Playback complete");
    SEL doneSelector = NSSelectorFromString(self.playbackDoneSelectorName);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [self.playbackDelegate performSelector:doneSelector];
#pragma clang diagnostic pop
}

- (void) dealloc {
  self.playbackDelegate = nil;
}



@end
