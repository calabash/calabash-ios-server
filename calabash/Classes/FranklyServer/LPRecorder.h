#import <Foundation/Foundation.h>

@interface LPRecorder : NSObject {

}


@property (nonatomic, strong) id playbackDelegate;
@property (nonatomic, strong) NSMutableArray *eventList;
@property (nonatomic, copy) NSString *playbackDoneSelectorName;
@property (nonatomic, assign) BOOL isRecording;

+(LPRecorder *)sharedRecorder;
-(void)record;
-(void)saveToFile:(NSString*)path;
-(NSArray*)events;
-(void)load:(NSArray*)events;
-(void)loadFromFile:(NSString*)path;
-(void)playbackWithDelegate:(id)delegate doneSelector:(SEL)selector;
-(void)stop;

@end
