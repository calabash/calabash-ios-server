//
//  LPPanningRoute.h
//  LPSimpleExample
//
//  Created by Karl Krukow on 14/03/12.
//  Copyright (c) 2012 LessPainful. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LPRoute.h"
#import "LPHTTPResponse.h"
#import "LPGenericAsyncRoute.h"

@interface LPInterpolateRoute : LPGenericAsyncRoute {
  NSArray *_events;
}

@property(nonatomic, retain) NSArray *events;
@property(nonatomic, retain) UIScriptParser *parser1;
@property(nonatomic, retain) UIScriptParser *parser2;

@end
