#import <UIKit/UIKit.h>

#import "LPRecorder.h"


@interface UIApplication (Recording)

-(void)_addRecorder:(id)recorder;
-(void)_removeRecorder:(id)recorder;
-(void)_playbackEvents:(NSArray*)events atPlaybackRate:(float)playbackRate messageWhenDone:(id)target withSelector:(SEL)selector;

@end

static LPRecorder *sharedRecorder = nil;

@implementation LPRecorder
@synthesize isRecording=_isRecording;
+(LPRecorder *)sharedRecorder {
	if (sharedRecorder == nil) {
		sharedRecorder = [[super allocWithZone:NULL] init];
	}
	return sharedRecorder;
}

-(id)init {
	self = [super init];

	eventList = [[NSMutableArray alloc] init];

	return self;
}


-(void)record {
	[eventList removeAllObjects];

	NSLog(@"Starting recording");
    _isRecording = YES;
	[[UIApplication sharedApplication] _addRecorder: self];
}
-(NSArray*)events {
    return eventList;
}
-(void)saveToFile:(NSString*)path {
	NSLog(@"Saving events to file: %@", path);
    
	if ([eventList writeToFile: path atomically: YES]) {
        NSLog(@"succeeded");
    }
}

-(void)stop {
	NSLog(@"Stopping recording");
    _isRecording = NO;
	[[UIApplication sharedApplication] _removeRecorder: self];
}

-(void)recordApplicationEvent:(NSDictionary*)event {
	NSLog(@"Recorded event: %@", event);

	[eventList addObject:event];
}

-(void)load:(NSArray*)events {
	NSLog(@"Loading events");

	[eventList setArray: events];
}

-(void)loadFromFile:(NSString*)path {
	NSLog(@"Loading events from file: %@", path);

	[eventList setArray: [NSMutableArray arrayWithContentsOfFile: path]];
}

-(void)playbackWithDelegate: (id)delegate doneSelector:(SEL)doneSelector {
	NSLog(@"Playback");

	playbackDelegate = delegate;
    
	playbackDoneSelector = doneSelector;

	[[UIApplication sharedApplication] _playbackEvents: eventList atPlaybackRate: 1.0f messageWhenDone: self withSelector: @selector(playbackDone:)];
}

-(void)playbackDone:(NSDictionary *)details {
	NSLog(@"Playback complete");
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [playbackDelegate performSelector: playbackDoneSelector];
#pragma clang diagnostic pop
    playbackDelegate = nil;
}

@end
