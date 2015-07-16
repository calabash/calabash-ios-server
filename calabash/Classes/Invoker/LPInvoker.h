#import <Foundation/Foundation.h>

@interface LPInvoker : NSObject

@property(assign, nonatomic, readonly) SEL selector;
@property(strong, nonatomic, readonly) id target;

// Designated initializer.
- (id) initWithSelector:(SEL) selector
                 target:(id) target;

/*
 Always returns an object.  Will never return nil.  If the selector returns
 nil, [NSNull null] will be returned.

 These methods handle exceptional cases by returning a constant string.

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

 6. Selector has a void return value.
    => <VOID>

 7. The invocation throws an exception.
    => Error: invoking selector on target raised an exception


 In cases 1 - 5, the selector will not be invoked.

 In case 5, the selector will be invoked.  If the invocation raises an
 exception is raised, 'Error: exception raised' will be returned.

 It is the responsibility of the caller to understand these rules.
*/
+ (id) invokeZeroArgumentSelector:(SEL) selector withTarget:(id) receiver;

+ (id) invokeSelector:(SEL) selector
           withTarget:(id) receiver
            arguments:(NSArray *) arguments;

- (BOOL) targetRespondsToSelector;
- (NSString *) encodingForSelectorReturnType;
- (BOOL) selectorReturnTypeEncodingIsUnhandled;
- (BOOL) selectorHasArgumentWithUnhandledEncoding;
- (BOOL) selectorArgumentCountMatchesArgumentsCount:(NSArray *) arguments;

@end
