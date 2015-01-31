//
//  LPJSONUtils.h
//  Created by Karl Krukow on 11/08/11.
//  Copyright 2011 LessPainful. All rights reserved.
//

@interface LPJSONUtils : NSObject

+ (void) dictionary:(NSMutableDictionary *) dictionary
          setObject:(id) object
             forKey:(NSString *) key;

+ (NSString *) stringForSelector:(SEL) selector returnValueEncodingForReceiver:(id) receiver;

+ (BOOL) selector:(SEL) selector returnsUnhandledEncodingForReceiver:(id) receiver;

+ (BOOL) selector:(SEL) selector returnsNSObjectForReceiver:(id) receiver;

+ (BOOL) selector:(SEL) selector returnsVoidForReceiver:(id) receiver;

+ (BOOL) selector:(SEL) selector returnsAutoBoxableValueForReceiver:(id) receiver;

+ (void) dictionary:(NSMutableDictionary *) dictionary
    setObjectForKey:(NSString *) key
      usingSelector:(SEL) selector
         onReceiver:(id) receiver;

+ (NSString *) serializeDictionary:(NSDictionary *) dictionary;

+ (NSDictionary *) deserializeDictionary:(NSString *) string;

+ (NSString *) serializeArray:(NSArray *) array;

+ (NSArray *) deserializeArray:(NSString *) string;

+ (NSString *) serializeObject:(id) obj;

+ (id) jsonifyObject:(id) obj;

+(id)jsonifyObject:(id)obj fullDump:(BOOL)dump;

@end
