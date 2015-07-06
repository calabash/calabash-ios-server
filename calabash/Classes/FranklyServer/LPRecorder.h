#import <Foundation/Foundation.h>

@interface LPRecorder : NSObject

@property(nonatomic, readonly) BOOL isRecording;

+ (LPRecorder *) sharedRecorder;

- (void) record;
- (void) saveToFile:(NSString *) path;
- (NSArray *) events;
- (void) load:(NSArray *) events;
- (void) loadFromFile:(NSString *) path;
- (void) playbackWithCallbackDelegate:(id) callbackDelegate
                         doneSelector:(SEL) selector;
- (void) stop;

@end
