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
#import "LPGenericAsyncRoute.h"

@interface LPConditionRoute : LPGenericAsyncRoute {
  NSTimer *_timer;
}

@property(nonatomic, retain) NSTimer *timer;
@property(nonatomic, assign) NSInteger maxCount;
@property(nonatomic, assign) NSInteger curCount;


@end
