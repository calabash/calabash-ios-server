//  Created by Karl Krukow on 15/04/14.
//  Copyright (c) 2014 Xamarin. All rights reserved.

#import <Foundation/Foundation.h>
#import "LPGenericAsyncRoute.h"

@interface LPUIATapRoute : LPGenericAsyncRoute {
  NSTimer *_timer;
}

@property(nonatomic, retain) NSTimer *timer;
@property(nonatomic, assign) NSInteger maxCount;
@property(nonatomic, assign) NSInteger curCount;


@end
