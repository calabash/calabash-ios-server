//
//  LPJSONUtils.h
//  Created by Karl Krukow on 11/08/11.
//  Copyright 2011 LessPainful. All rights reserved.
//

@interface LPJSONUtils : NSObject

+ (NSString *) serializeDictionary:(NSDictionary *) dictionary;

+ (NSDictionary *) deserializeDictionary:(NSString *) string;

+ (NSString *) serializeArray:(NSArray *) array;

+ (NSArray *) deserializeArray:(NSString *) string;

+ (NSString *) serializeObject:(id) obj;

+ (id) jsonifyObject:(id) obj;


@end
