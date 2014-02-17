//
//  NoContentResponse.m
//  Created by Karl Krukow on 15/08/11.
//  Copyright 2011 LessPainful. All rights reserved.
//

#import "LPNoContentResponse.h"

@implementation LPNoContentResponse


- (UInt64) contentLength {return 0;}


- (UInt64) offset {return 0;}


- (void) setOffset:(UInt64) offset {}


- (NSData *) readDataOfLength:(NSUInteger) length {return nil;}


- (BOOL) isDone {return YES;}


- (NSInteger) status {return 203;}
@end
