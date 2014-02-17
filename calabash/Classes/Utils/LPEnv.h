//
//  LPEnv.h
//  calabash
//
//  Created by Karl Krukow on 1/30/14.
//  Copyright (c) 2014 Xamarin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LPEnv : NSObject
+ (LPEnv *) sharedEnv;

- (BOOL) isSet:(NSString *) key;

+ (BOOL) calabashDebugEnabled;
@end
