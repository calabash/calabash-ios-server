//
//  LessPainfulServer.h
//  iLessPainfulServer
//
//  Created by Karl Krukow on 11/08/11.
//  Copyright 2011 Trifork. All rights reserved.
//


@class HTTPServer;

@interface LessPainfulServer : NSObject {
	HTTPServer *_httpServer;
}

+ (void) start;

@end
