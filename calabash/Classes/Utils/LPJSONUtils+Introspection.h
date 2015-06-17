//
//  LPJSONUtils+Accessors.h
//  calabash
//
//  Created by Chris Fuentes on 6/5/15.
//  Copyright (c) 2015 Xamarin. All rights reserved.
//

#import "LPJSONUtils.h"

@interface LPJSONUtils (Introspection)

/*
  properties &
  selectors
 */
+ (NSDictionary *)objectIntrospection:(id)object;

@end