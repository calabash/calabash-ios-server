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
    NSArray *__unsafe_unretained _events;
    LPHTTPConnection *__unsafe_unretained _conn;
    NSDictionary *__unsafe_unretained _data;
    NSDictionary *__unsafe_unretained _jsonResponse;
    
    NSData *_bytes;
    
}

@property (unsafe_unretained, nonatomic) NSArray *events;
@property (nonatomic, assign) BOOL done;
@property (nonatomic, unsafe_unretained) LPHTTPConnection *conn;
@property (unsafe_unretained, nonatomic) NSDictionary *data;
@property (unsafe_unretained, nonatomic) NSDictionary *jsonResponse;

- (void) play:(NSArray *)events;

@end
