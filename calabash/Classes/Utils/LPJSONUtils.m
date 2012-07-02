//
//  LPJSONUtils.m
//  Created by Karl Krukow on 11/08/11.
//  Copyright 2011 LessPainful. All rights reserved.
//

#import "LPJSONUtils.h"
#import "LPCJSONSerializer.h"
#import "LPCJSONDeserializer.h"

@implementation LPJSONUtils

+ (NSString*) serializeDictionary:(NSDictionary*) dictionary {
    LPCJSONSerializer* s = [LPCJSONSerializer serializer];
    NSError* error = nil;
    NSData* d = [s serializeDictionary:dictionary error:&error];
    if (error) {
        NSLog(@"Unable to serialize dictionary (%@), %@",error,dictionary);
    }
    NSString* res = [[NSString alloc]  initWithBytes:[d bytes]
                              length:[d length] encoding: NSUTF8StringEncoding];
    return res;
}
+ (NSDictionary*) deserializeDictionary:(NSString*) string {
    LPCJSONDeserializer* ds = [LPCJSONDeserializer deserializer];
    NSError* error = nil;
    NSDictionary* res = [ds deserializeAsDictionary:[string dataUsingEncoding:NSUTF8StringEncoding]error:&error];
    if (error) {
        NSLog(@"Unable to deserialize  %@",string);
    }
    return res;
}

+ (NSString*) serializeArray:(NSArray*) array {
    LPCJSONSerializer* s = [LPCJSONSerializer serializer];
    NSError* error = nil;
    NSData* d = [s serializeArray:array error:&error];
    if (error) {
        NSLog(@"Unable to serialize arrayy (%@), %@",error,array);
    }
    NSString* res = [[NSString alloc]  initWithBytes:[d bytes]
                                              length:[d length] encoding: NSUTF8StringEncoding];
    return res;
}
+ (NSArray*) deserializeArray:(NSString*) string {
    LPCJSONDeserializer* ds = [LPCJSONDeserializer deserializer];
    NSError* error = nil;
    NSArray* res = [ds deserializeAsArray:[string dataUsingEncoding:NSUTF8StringEncoding] error:&error];
    if (error) {
        NSLog(@"Unable to deserialize  %@",string);
    }
    return res;
}

+(NSString *)serializeObject:(id)obj
{
    LPCJSONSerializer* s = [LPCJSONSerializer serializer];
    NSError* error = nil;
    NSData* d = [s serializeObject:obj error:&error];
    if (error) {
        NSLog(@"Unable to serialize object (%@), %@",error,[obj description]);
    }
    NSString* res = [[NSString alloc]  initWithBytes:[d bytes]
                                              length:[d length] encoding: NSUTF8StringEncoding];
    return res;

}

@end
