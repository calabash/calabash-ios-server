//
//  LPConditionRoute.h
//  calabash
//
//  Created by Karl Krukow on 29/01/12.
//  Copyright (c) 2012 LessPainful. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "LPRoute.h"
#import "LPHTTPResponse.h"
@interface LPConditionRoute : NSObject<LPRoute,LPHTTPResponse> 
{    
    BOOL _done;
    LPHTTPConnection *_conn;
    NSDictionary *_data;
    NSDictionary *_jsonResponse;
    NSTimer *_timer;
    NSData *_bytes;
    
}

@property (nonatomic, assign) BOOL done;
@property (nonatomic, assign) LPHTTPConnection *conn;
@property (nonatomic, retain) NSDictionary *data;
@property (nonatomic, retain) NSDictionary *jsonResponse;
@property (nonatomic, retain) NSTimer *timer;
@property (nonatomic, assign) NSInteger maxCount;
@property (nonatomic, assign) NSInteger curCount;


@end
