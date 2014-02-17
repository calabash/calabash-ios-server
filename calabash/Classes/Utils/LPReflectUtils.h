//
//  LPReflectUtils.h
//  Created by Karl Krukow on 08/15/12.
//  Copyright 2012 LessPainful. All rights reserved.
//



@interface LPReflectUtils : NSObject

+ (id) invokeSpec:(id) object onTarget:(id) target withError:(NSError **) error;

@end
