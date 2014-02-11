//
//  LPRouter.h
//  Created by Karl Krukow on 13/08/11.
//  Copyright 2011 LessPainful. All rights reserved.

#import "LPHTTPConnection.h"
#import "LPRoute.h"

@interface LPRouter : LPHTTPConnection {
  NSMutableData *_postData;
}
@property(nonatomic, retain, readonly) NSData *postData;

+ (void) addRoute:(id <LPRoute>) route forPath:(NSString *) path;

@end
