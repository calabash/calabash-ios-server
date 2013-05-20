//
//  LPConditionRoute.h
//  calabash
//
//  Created by Karl Krukow on 29/01/12.
//  Copyright (c) 2012 LessPainful. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "RequestRouter.h"
#import "HTTPResponse.h"
#import "LPGenericAsyncRoute.h"
#import "UIScriptParser.h"
@interface LPConditionRoute : LPGenericAsyncRoute
{    
    NSTimer *_timer;    
}

@property (nonatomic, retain) NSString *query;
@property (nonatomic, retain) NSTimer *timer;
@property (nonatomic, assign) NSInteger maxCount;
@property (nonatomic, assign) NSInteger curCount;



@end
