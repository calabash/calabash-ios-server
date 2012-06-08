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

-(SEL)parseValuesFromArray:(NSArray *)arr withArgs:(NSMutableArray *)args
{
    NSMutableString *selStr = [NSMutableString stringWithCapacity:32];
    for (NSDictionary *selPart in arr)
    {
        NSString *key = [[selPart keyEnumerator] nextObject];
        [selStr appendFormat:@"%@:",key];
        [args addObject:[selPart objectForKey:key]];        
    }
    return NSSelectorFromString(selStr);
}

-(BOOL)coerceArgument:(id)arg toType:(const char *)cType setValue:(void **)setValue
{
    switch(*cType) {
        case '@':
            *setValue = arg;
            return YES;
        case 'i':
        {
            NSInteger intVal = [arg integerValue];
            *setValue = &intVal;
            return NO;
        }            
        case 's':
        {
            short shVal = [arg shortValue];
            *setValue = &shVal;
            return NO;
        }
        case 'd':
        {
            double dbVal = [arg doubleValue];
            *setValue = &dbVal;
            return NO;
        }
        case 'f':
        {
            float fltVal = [arg floatValue];
            *setValue = &fltVal;
            return NO;           
        }
        case 'l':
        {
            long lngVal = [arg longValue];
            *setValue = &lngVal;
            return NO;
        }
        case '*':
            *setValue = arg;
            return NO;
        case 'c':
        {
            char chVal =[arg charValue];
            *setValue = &chVal;
            return NO;
        }
        case '{': {
            return NO;
        }
    }
    return NO;
 
}

- (id) performWithTarget:(UIView*)_view error:(NSError **)error {
    id target = _view;
    if([_arguments count] <= 0) {
        return _view;
    }
    for (NSInteger i=0;i<[_arguments count];i++) {
        id selObj = [_arguments objectAtIndex:i];
        id objValue;
        int intValue;
        long longValue;
        char *charPtrValue; 
        char charValue;
        short shortValue;
        float floatValue;
        double doubleValue;
        SEL sel;
        
        NSMutableArray *args = [NSMutableArray array];
        
        if ([selObj isKindOfClass:[NSString class]])
        {
            sel = NSSelectorFromString(selObj);
        }
        else if ([selObj isKindOfClass:[NSDictionary class]])
        {
            sel = [self parseValuesFromArray:[NSArray arrayWithObject: selObj] withArgs:args];
        }
        else if ([selObj isKindOfClass:[NSArray class]])
        {
            sel = [self parseValuesFromArray:selObj withArgs:args];
            
        }
        
        NSMethodSignature *sig = [target methodSignatureForSelector:sel];
        if (!sig || ![target respondsToSelector:sel]) 
        {
            return @"*****";
        } 
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sig];

            [invocation setSelector:sel];
            for (NSInteger i =0, N=[args count]; i<N; i++)
            {
                void *argToSet;
                BOOL isObj = [self coerceArgument:[args objectAtIndex:i] 
                               toType:[sig getArgumentTypeAtIndex:i+2] setValue:&argToSet];
                if (isObj)
                {
                        [invocation setArgument:&argToSet atIndex:i+2];
                }
                else
                {
                    [invocation setArgument:argToSet atIndex:i+2];
                }
                
            }
            [invocation setTarget:target];
            @try {
                [invocation invoke];
            }
            @catch (NSException *exception) {
                NSLog(@"Perform %@ with target %@ caught %@: %@", selObj, target, [exception name], [exception reason]);
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
                        return objValue;
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
    
    
    
    
    
	return nil;
}

            
                 
@end
