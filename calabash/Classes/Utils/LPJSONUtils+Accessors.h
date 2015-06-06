//
//  LPJSONUtils+Accessors.h
//  calabash
//
//  Created by Chris Fuentes on 6/5/15.
//  Copyright (c) 2015 Xamarin. All rights reserved.
//

#import "LPJSONUtils.h"

typedef NS_ENUM(unsigned short, LPAccessorOptions) {
  kLPAccessorOptionsOnlyExcludeSuperclasses   = 1 << 0,
  kLPAccessorOptionsIncludePrivateMethods     = 1 << 1, /* methods that start with '_' */
  kLPAccessorOptionsVerbose                   = 1 << 2
};

@interface LPJSONUtils (Accessors)

+ (NSDictionary *)accessorsForObject:(id)object options:(unsigned short)options;

@end
