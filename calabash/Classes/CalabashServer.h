//  Created by Karl Krukow on 11/08/11.
//  Copyright 2011 LessPainful. All rights reserved.


@class HTTPServer;

@interface CalabashServer : NSObject {
	HTTPServer *_httpServer;
}

+ (void) start;

@end
