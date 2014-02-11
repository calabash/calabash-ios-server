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
#import "LPGenericAsyncRoute.h"

@interface LPAsyncPlaybackRoute : LPGenericAsyncRoute {
  NSArray *_events;
}

@property(nonatomic, retain) NSArray *events;

@end
