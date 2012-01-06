//
//  LPJSONUtils.h
//  iLessPainfulServer
//
//  Created by Karl Krukow on 11/08/11.
//  Copyright 2011 Trifork. All rights reserved.
//



@interface LPJSONUtils : NSObject

+ (NSString*) serializeDictionary:(NSDictionary*) dictionary;
+ (NSDictionary*) deserializeDictionary:(NSString*) string;
+ (NSString*) serializeArray:(NSArray*) array;
+ (NSArray*) deserializeArray:(NSString*) string;
@end
