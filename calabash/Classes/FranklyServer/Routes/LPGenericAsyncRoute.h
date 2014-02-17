//
//  LPGenericAsyncRoute.h
//  calabash
//
//  Created by Karl Krukow on 29/01/12.
//  Copyright (c) 2012 LessPainful. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "LPRoute.h"
#import "LPHTTPResponse.h"

@interface LPGenericAsyncRoute : NSObject <LPRoute, LPHTTPResponse> {
  BOOL _done;
  LPHTTPConnection *_conn;
  NSDictionary *_data;
  NSDictionary *_jsonResponse;
  NSData *_bytes;
}

@property(nonatomic, assign) BOOL done;
@property(nonatomic, assign) LPHTTPConnection *conn;
@property(nonatomic, retain) NSDictionary *data;
@property(nonatomic, retain) NSDictionary *jsonResponse;

- (void) beginOperation;

- (BOOL) isDone;

- (void) failWithMessageFormat:(NSString *) messageFmt message:(NSString *) message;

- (void) succeedWithResult:(NSArray *) result;


@end
