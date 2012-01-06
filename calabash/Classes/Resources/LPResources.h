//
//  Resources.h
//  iLessPainfulServer
//
//  Created by Karl Krukow on 14/08/11.
//  Copyright 2011 Trifork. All rights reserved.
//

#import <Foundation/Foundation.h>
@interface LPResources : NSObject


+ (NSArray*) eventsFromEncoding:(NSString *) encoded;
+ (NSArray *) transformEvents:(NSArray*) eventsRecord toPoint:(CGPoint) viewCenter;

@end
