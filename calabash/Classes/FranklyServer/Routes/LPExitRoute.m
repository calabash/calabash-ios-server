//
//  LPExitRoute.m
//  calabash
//
//  Created by Trevor Harmon on 11/15/12.
//  Copyright (c) 2012 Xamarin. All rights reserved.
//

#import "LPExitRoute.h"

@implementation LPExitRoute

- (BOOL) supportsMethod:(NSString *) method atPath:(NSString *) path {
  return [method isEqualToString:@"GET"] || [method isEqualToString:@"POST"];
}


- (NSDictionary *) JSONResponseForMethod:(NSString *) method URI:(NSString *) path data:(NSDictionary *) data {
  // Exiting the app causes the HTTP connection to shutdown immediately.
  // Clients will get an empty response and need to handle the error
  // condition accordingly.
  exit(0);
}

@end
