#import <Foundation/Foundation.h>

/*
 Reference material for Objective-C type encodings.
 * https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html
 * http://nshipster.com/type-encodings/
 */

@class LPInvocationResult;

@interface LPInvoker : NSObject

@property(assign, nonatomic, readonly) SEL selector;
@property(strong, nonatomic, readonly) id target;

// Designated initializer.
- (id) initWithSelector:(SEL) selector
                 target:(id) target;


/*
 Always returns an object.  Will never return nil.

 The LPInvocationResult property 'value' will contain the value that is the
 result of the invocation.

 If the selector has a void return type, the value will be the string: '<VOID>'.

 If the selector returns nil, the value will be NSNull.

 LPInvocationResult has two convencience methods:

 1. isNull  #=> true iff the invocation resulted in nil.
 2. isError #=> true iff the invocation resulted in an error.

 LPInvocationResult has one subclass: LPInvocationError.

 If the invocation results in an error, an LPInvocationError will be returned.

 LPInvocationError instances have a type (enum) and their description selector
 will return details about why the invocation failed.

 1. Target does not respond to selector.
 => *****

 2. Selector returns an type that cannot be coerced into an object, like a
    union or a bitfield.
 => Error: cannot coerce returned value to an object

 3. Selector returns a type with an unknown encoding.
 => Error: selector returns an unknown encoding

 4. One or more selector arguments are not supported, like unions or bitfields.
 => Error: selector has arguments that are not handled

 5. An incorrect number of arguments were provided to the selector.
 => Error: incorrect number of arguments provided for selector

 6. Invoking the selector throws an exception.
 => Error: invoking selector on target raised an exception";

 6. Any other problem.
 => Error: invoking selector on target could not be performed

 Usage:

 LPInvocationResult *invocationResult;
 invocationResult = [LPInvoker invokeSelector:self.selector
                                   withTarget:target
                                    arguments:self.arguments];
 id returnValue = nil;

 if ([invocationResult isError]) {
   NSString *description = [invocationResult description];
   if (error) {
     NSDictionary *userInfo =
     @{
         NSLocalizedDescriptionKey : description
      };
     *error = [NSError errorWithDomain:@"CalabashServer"
                                  code:1
                              userInfo:userInfo];
   }

   LPLogError(@"Could not call selector '%@' on target '%@' - %@",
   NSStringFromSelector(self.selector), target, description);
   returnValue = description;
 } else {
   if ([invocationResult isNSNull]) {
   returnValue = nil;
 } else {
   returnValue = invocationResult.value;
 }

 */
+ (LPInvocationResult *) invokeZeroArgumentSelector:(SEL) selector
                                         withTarget:(id) target;

+ (LPInvocationResult *) invokeSelector:(SEL) selector
                             withTarget:(id) receiver
                              arguments:(NSArray *) arguments;

+ (LPInvocationResult *) invokeOnMainThreadZeroArgumentSelector:(SEL) selector
                                                     withTarget:(id) target;

+ (LPInvocationResult *) invokeOnMainThreadSelector:(SEL) selector
                                         withTarget:(id) target
                                          arguments:(NSArray *) arguments;

- (BOOL) targetRespondsToSelector;
- (NSString *) encodingForSelectorReturnType;
- (BOOL) selectorReturnTypeEncodingIsUnhandled;
- (BOOL) selectorHasArgumentWithUnhandledEncoding;
- (BOOL) selectorArgumentCountMatchesArgumentsCount:(NSArray *) arguments;

@end
