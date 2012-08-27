//
//  Operation.h
//  Created by Karl Krukow on 14/08/11.
//  Copyright 2011 LessPainful. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UIScriptParser.h"

@interface LPOperation : NSObject {
    SEL _selector;
	NSArray *_arguments;
    BOOL _done;
    NSArray *_events;
}
+ (id) operationFromDictionary:(NSDictionary*) dictionary;

+(NSArray*)performQuery:(id)query;
+(NSArray*)performQueryAll:(id)query;


- (id) initWithOperation:(NSDictionary *)operation;

- (id) performWithTarget:(UIView*) view error:(NSError **)error;
-(void) wait:(CFTimeInterval)seconds;
//-(void) waitUntilPlaybackDone;
-(void) play:(NSArray *)events;
@end
