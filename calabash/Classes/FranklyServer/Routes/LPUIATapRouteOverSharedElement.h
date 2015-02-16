//  Created by Karl Krukow on 11/23/14.
//  Copyright (c) 2014 Xamarin. All rights reserved.

#import <Foundation/Foundation.h>
#import "LPGenericAsyncRoute.h"

@interface LPUIATapOverSharedElementRoute : LPGenericAsyncRoute {
  NSTimer *_timer;
}

@property(nonatomic, retain) NSTimer *timer;
@property(nonatomic, assign) NSUInteger maxCount;
@property(nonatomic, assign) NSUInteger curCount;


@end
