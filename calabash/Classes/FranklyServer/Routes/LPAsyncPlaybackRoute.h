//
//  LPAsyncPlaybackRoute.h
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

@interface LPAsyncPlaybackRoute : LPGenericAsyncRoute
{    
    NSArray *_events;    
}

@property (nonatomic, retain) NSArray *events;
@property (nonatomic, retain) UIScriptParser *parser;

@end
