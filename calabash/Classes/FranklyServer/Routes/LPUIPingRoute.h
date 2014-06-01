//
//  LPUIPingRoute.h
//  calabash
//
//  Created by Karl Krukow on 6/1/14.
//  Copyright (c) 2014 Xamarin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LPRoute.h"

@interface LPUIPingRoute : NSObject <LPRoute>

-(BOOL)inNetworkThread;
@end
