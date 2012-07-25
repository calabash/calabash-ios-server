//
//  QueryOperation.m
//  Created by Karl Krukow on 10/09/11.
//  Copyright (c) 2011 LessPainful. All rights reserved.
//

#import "LPQueryOperation.h"
#import "LPJSONUtils.h"


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

- (id) performWithTarget:(UIView*)_view error:(NSError **)error {
    id target = _view;
    if([_arguments count] <= 0) {
        return [LPJSONUtils jsonifyObject: _view];
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
                id arg = [args objectAtIndex:i];
                const char *cType = [sig getArgumentTypeAtIndex:i+2];
                switch(*cType) {
                    case '@':
                        [invocation setArgument:&arg atIndex:i+2];
                        break;                        
                    case 'i':
                    {
                        NSInteger intVal = [arg integerValue];
                        [invocation setArgument:&intVal atIndex:i+2];
                        break;
                    }            
                    case 's':
                    {
                        short shVal = [arg shortValue];
                        [invocation setArgument:&shVal atIndex:i+2];
                        break;
                    }
                    case 'd':
                    {
                        double dbVal = [arg doubleValue];
                        [invocation setArgument:&dbVal atIndex:i+2];
                        break;
                    }
                    case 'f':
                    {
                        float fltVal = [arg floatValue];
                        [invocation setArgument:&fltVal atIndex:i+2];
                        break;
                    }
                    case 'l':
                    {
                        long lngVal = [arg longValue];
                        [invocation setArgument:&lngVal atIndex:i+2];
                        break;
                    }
                    case '*':
                        //not supported yet
                        @throw [NSString stringWithFormat: @"not yet support struct pointers: %@",sig];
                    case 'c':
                    {
                        char chVal =[arg charValue];
                        [invocation setArgument:&chVal atIndex:i+2];
                        break;
                    }
                    case '{': {
                        //not supported yet
                        @throw [NSString stringWithFormat: @"not yet support struct args: %@",sig];
                    }
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
                        return [LPJSONUtils jsonifyObject:objValue];
                    } else {
                        target = objValue;
                        continue;
                    }
                    
                }
            case 'i':
                [invocation getReturnValue:(void **)&intValue];
                return [NSNumber numberWithInt: intValue];
            case 's':
                [invocation getReturnValue:(void **)&shortValue];
                return [NSNumber numberWithShort:shortValue];
            case 'd':
                [invocation getReturnValue:(void **)&doubleValue];
                return [NSNumber numberWithDouble: doubleValue];
            case 'f':
                [invocation getReturnValue:(void **)&floatValue];
                return [NSNumber numberWithFloat:floatValue];
            case 'l':
                [invocation getReturnValue:(void **)&longValue];
                return [NSNumber numberWithLong: longValue];
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
                
                if ([returnType rangeOfString:@"{CGRect"].location == 0)
                {
                    CGRect *rec = (CGRect*)buffer;
                    return [NSDictionary dictionaryWithObjectsAndKeys:
                            [value description], @"description",
                            [NSNumber numberWithFloat:rec->origin.x],@"x",
                            [NSNumber numberWithFloat:rec->origin.y],@"y",
                            [NSNumber numberWithFloat:rec->size.width],@"width",
                            [NSNumber numberWithFloat:rec->size.height],@"height",
                            nil];
                    
                }
                else if ([returnType rangeOfString:@"{CGPoint="].location == 0)
                {
                    CGPoint *point = (CGPoint*)buffer;
                    return [NSDictionary dictionaryWithObjectsAndKeys:
                            [value description], @"description",
                            [NSNumber numberWithFloat:point->x],@"x",
                            [NSNumber numberWithFloat:point->y],@"y",
                            nil];
                    
                }
                else
                {
                    return [value description];                    
                }
            }
        }

        
    
    }
    
    
    
    
    
	return nil;
}

            
                 
@end
