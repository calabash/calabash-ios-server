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
    
}


@property (strong, nonatomic) NSArray *events;
@property (nonatomic, assign) BOOL done;
@property (nonatomic, strong) LPHTTPConnection *conn;
@property (strong, nonatomic) NSDictionary *data;
@property (strong, nonatomic) NSDictionary *jsonResponse;
@property (strong, nonatomic) NSData *bytes;

- (void) play:(NSArray *)events;

@end
