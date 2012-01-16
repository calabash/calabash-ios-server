//
//  PlaybackRoute.h
//  Created by Karl Krukow on 18/08/11.
//  Copyright (c) 2011 LessPainful. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LPRoute.h"
@interface LPPlaybackRoute : NSObject<LPRoute> {
    BOOL _done;
    NSArray *_events;
}

@property (nonatomic, retain) NSArray *events;
@property (nonatomic, assign) BOOL done;

-(void) play:(NSArray *)events;
//-(void) waitUntilPlaybackDone;
    
@end
