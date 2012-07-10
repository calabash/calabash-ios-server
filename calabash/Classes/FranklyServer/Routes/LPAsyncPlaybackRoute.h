//
//  LPAsyncPlaybackRoute.h
//  calabash
//
//  Created by Karl Krukow on 29/01/12.
//  Copyright (c) 2012 LessPainful. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "LPRoute.h"
#import "LPHTTPResponse.h"
@interface LPAsyncPlaybackRoute : NSObject<LPRoute,LPHTTPResponse> 
{    
  

}

@property (strong, nonatomic) NSData *bytes;
@property (strong, nonatomic) NSArray *events;
@property (assign, nonatomic) BOOL done;
@property (strong, nonatomic) LPHTTPConnection *conn;
@property (strong, nonatomic) NSDictionary *data;
@property (strong, nonatomic) NSDictionary *jsonResponse;

- (void) play:(NSArray *)events;

@end
