//
//  LPAsyncPlaybackRoute.h
//  calabash
//
//  Created by Karl Krukow on 29/01/12.
//  Copyright (c) 2012 Trifork. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "LPRoute.h"
#import "HTTPResponse.h"
@interface LPAsyncPlaybackRoute : NSObject<LPRoute,HTTPResponse> 
{    
    BOOL _done;
    NSArray *_events;
    HTTPConnection *_conn;
    NSDictionary *_data;
    NSDictionary *_jsonResponse;
    
    NSData *_bytes;
    
}

@property (nonatomic, retain) NSArray *events;
@property (nonatomic, assign) BOOL done;
@property (nonatomic, assign) HTTPConnection *conn;
@property (nonatomic, retain) NSDictionary *data;
@property (nonatomic, retain) NSDictionary *jsonResponse;

- (void) play:(NSArray *)events;

@end
