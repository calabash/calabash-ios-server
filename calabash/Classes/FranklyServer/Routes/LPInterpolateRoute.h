//
//  LPPanningRoute.h
//  LPSimpleExample
//
//  Created by Karl Krukow on 14/03/12.
//  Copyright (c) 2012 Trifork. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LPRoute.h"
#import "LPHTTPResponse.h"

@interface LPInterpolateRoute : NSObject<LPRoute,LPHTTPResponse> 
{    
    BOOL _done;
    NSArray *_events;
    LPHTTPConnection *_conn;
    NSDictionary *_data;
    NSDictionary *_jsonResponse;
    
    NSData *_bytes;
    
}

@property (nonatomic, retain) NSArray *events;
@property (nonatomic, assign) BOOL done;
@property (nonatomic, assign) LPHTTPConnection *conn;
@property (nonatomic, retain) NSDictionary *data;
@property (nonatomic, retain) NSDictionary *jsonResponse;

- (void) play:(NSArray *)events;

@end
