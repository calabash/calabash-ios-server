//  Created by Karl Krukow on 11/08/11.
//  Copyright 2011 LessPainful. All rights reserved.


@class LPHTTPServer;

@interface CalabashServer : NSObject {
	LPHTTPServer *_httpServer;
}

+ (void) start;

@end
