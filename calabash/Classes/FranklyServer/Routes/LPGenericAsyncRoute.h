//
//  LPGenericAsyncRoute.h
//  calabash
//
//  Created by Karl Krukow on 29/01/12.
//  Copyright (c) 2012 LessPainful. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "RequestRouter.h"
#import "HTTPResponse.h"
#import "HTTPConnection.h"
#import "LPRoute.h"
@interface LPGenericAsyncRoute : NSObject<Route,HTTPResponse>
{    
    BOOL _done;
    HTTPConnection *_conn;
    NSDictionary *_data;
    NSDictionary *_jsonResponse;
    NSData *_bytes;
    
}

@property (nonatomic, assign) BOOL done;
@property (nonatomic, assign) HTTPConnection *conn;
@property (nonatomic, retain) NSDictionary *data;
@property (nonatomic, retain) NSDictionary *jsonResponse;

-(void)beginOperation;
- (BOOL)isDone;
-(void)failWithMessageFormat:(NSString *)messageFmt message:(NSString *)message;
-(void)succeedWithResult:(NSArray *)result;


@end
