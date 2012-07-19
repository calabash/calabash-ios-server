#import "NSObject+LPAdditions.h"



@implementation NSObject (NSObject_LPAdditions)

- (id) performSelectorSafely:(SEL)aSelector {
    NSParameterAssert(aSelector != NULL);
    NSParameterAssert([self respondsToSelector:aSelector]);
    
    NSMethodSignature* methodSig = [self methodSignatureForSelector:aSelector];
    NSParameterAssert(methodSig != nil);
    
    const char* retType = [methodSig methodReturnType];
    if(strcmp(retType, @encode(id)) == 0 || strcmp(retType, @encode(void)) == 0){
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        return [self performSelector:aSelector];
#pragma clang diagnostic pop
        
    } else {
        NSLog(@"-[%@ performSelector:@selector(%@)] shouldn't be used. The selector doesn't return an object or void", 
              [self class], NSStringFromSelector(aSelector));
        return nil;
    }
}

- (BOOL) selectorReturnsObjectOrVoid:(SEL) aSelector {
    NSParameterAssert(aSelector != NULL);
    NSParameterAssert([self respondsToSelector:aSelector]);
    NSMethodSignature* methodSig = [self methodSignatureForSelector:aSelector];
    NSParameterAssert(methodSig != nil);
    const char* retType = [methodSig methodReturnType];
    return strcmp(retType, @encode(id)) == 0 || strcmp(retType, @encode(void)) == 0;
}

- (BOOL) selectorReturnsNonObjectAndNonVoid:(SEL) aSelector {
    NSParameterAssert(aSelector != NULL);
    NSParameterAssert([self respondsToSelector:aSelector]);
    NSMethodSignature* methodSig = [self methodSignatureForSelector:aSelector];
    NSParameterAssert(methodSig != nil);
    return ![self selectorReturnsObjectOrVoid:aSelector];
}

@end
