//
//  QueryOperation.m
//  Created by Karl Krukow on 10/09/11.
//  Copyright (c) 2011 LessPainful. All rights reserved.
//

#import "LPQueryOperation.h"

@implementation LPQueryOperation
- (NSString *) description {
	return [NSString stringWithFormat:@"Query: %@",_arguments];
}

- (id) performWithTarget:(UIView*)_view error:(NSError **)error {
    id target = _view;
    if([_arguments count] <= 0) {
        return _view;
    }
    for (NSInteger i=0;i<[_arguments count];i++) {
        NSString *selStr = [_arguments objectAtIndex:i];
        SEL sel = NSSelectorFromString(selStr);
        if (![target respondsToSelector:sel]) {
            return @"*****";
        } else {
            id objValue;
            int intValue;
            long longValue;
            char *charPtrValue; 
            char charValue;
            short shortValue;
            float floatValue;
            double doubleValue;
            
            NSMethodSignature *sig = [target methodSignatureForSelector:sel];
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sig];
            [invocation setSelector:sel];
            [invocation setTarget:target];
            @try {
                [invocation invoke];
            }
            @catch (NSException *exception) {
                NSLog(@"Perform %@ with target %@ caught %@: %@", selStr, target, [exception name], [exception reason]);
                return nil;
            }
            
            const char* type = [[invocation methodSignature] methodReturnType];
            NSString *returnType = [NSString stringWithFormat:@"%s", type];
            const char* trimmedType = [[returnType substringToIndex:1] cStringUsingEncoding:NSASCIIStringEncoding];
            switch(*trimmedType) {
                case '@':
                    [invocation getReturnValue:(void **)&objValue];
                    if (objValue == nil) {
                        return nil;
                    } else {
                        if (i == [_arguments count]-1) {
                            return [objValue description];
                        } else {
                            target = objValue;
                            continue;
                        }
                        
                    }
                case 'i':
                    [invocation getReturnValue:(void **)&intValue];
                    return [NSString stringWithFormat:@"%i", intValue];
                case 's':
                    [invocation getReturnValue:(void **)&shortValue];
                    return [NSString stringWithFormat:@"%ud", shortValue];
                case 'd':
                    [invocation getReturnValue:(void **)&doubleValue];
                    return [NSString stringWithFormat:@"%lf", doubleValue];
                case 'f':
                    [invocation getReturnValue:(void **)&floatValue];
                    return [NSString stringWithFormat:@"%f", floatValue];
                case 'l':
                    [invocation getReturnValue:(void **)&longValue];
                    return [NSString stringWithFormat:@"%ld", longValue];
                case '*':
                    [invocation getReturnValue:(void **)&charPtrValue];
                    return [NSString stringWithFormat:@"%s", charPtrValue];
                case 'c':
                    [invocation getReturnValue:(void **)&charValue];
                    return [NSString stringWithFormat:@"%d", charValue];
                case '{': {
                    unsigned int length = [[invocation methodSignature] methodReturnLength];
                    void *buffer = (void *)malloc(length);
                    [invocation getReturnValue:buffer];
                    NSValue *value = [[[NSValue alloc] initWithBytes:buffer objCType:type] autorelease];
                    return [value description];
                }
            }
        }
    
    }
    
    
    
    
    
	return nil;
}

@end
