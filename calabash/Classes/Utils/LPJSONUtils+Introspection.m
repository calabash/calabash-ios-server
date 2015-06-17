#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPJSONUtils+Introspection.h"
#import <objc/runtime.h>

@interface LPJSONUtils ()
@end

#pragma mark - Convenience C String Util
static inline NSString *objCStr(const char *cString) {
  return [NSString stringWithCString:cString encoding:[NSString defaultCStringEncoding]];
};

@implementation LPJSONUtils (Introspection)
static NSUInteger const LPJSONUtilsIntrospectionMethodDescriptionBufferLength = 256;

#pragma mark - Public API
/*
 getCustomAccessors
 Returns a list of 'custom accessors', defined as accessors which
 do not follow the custom naming conventions. E.g., for property
 'foo', the custom naming conventions would be getter=foo, setter=setFoo.
 If the names are different than convention dictates (e.g. getter=obtainFooValue,
 setter=updateFooValue), they are included in the returned list.
 
 @param object - the object for which you'd like the custom accessors
 @return NSDictionary - a dictionary of strings describing the custom accessors, or nil
 if none exist.
 */
+ (NSDictionary *)objectIntrospection:(id)object {
  NSDictionary *customAccessors = @{
                                    @"properties" : [NSMutableDictionary new],
                                    @"methods"    : [NSMutableArray new]
                                    };
  
  Class c = [object class];
  unsigned int propertyCount, methodCount;
  
  do {
    /* Get properties for current class */
    objc_property_t *properties = class_copyPropertyList(c, &propertyCount);
    for (int i = 0; i < propertyCount; i++) {
      objc_property_t property  = properties[i];
      NSString *propName        = objCStr(property_getName(property));
      NSDictionary *accessors   = [self customAccessorsForProperty:property name:propName object:object];
      customAccessors[@"properties"][propName] = accessors;
    }
    free(properties);
    
    /* Get selectors for current class */
    Method *methods = class_copyMethodList(c, &methodCount);
    for (int i = 0; i < methodCount; i++) {
      SEL method = method_getName(methods[i]);
      NSString *methodName = NSStringFromSelector(method);
      if ([object respondsToSelector:method]) {
        [customAccessors[@"methods"] addObject:methodName];
      } else {
        NSLog(@"Object doesn't respond to method: ");
      }
    }
    free(methods);
    
  } while (( c = [c superclass] ));
  
  return customAccessors;
}

/*
 customAccessorsForProperty
 Returns custom named accessors, if any, for a given property of an object.
 
 @param property   the property for which you'd like the custom accessors
 @return  NSString the custom accessors if any (formatted like a JSON object),
 or nil if no custom properties exist.
 
 See https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html
 */
+ (NSDictionary *)customAccessorsForProperty:(objc_property_t)property name:(NSString *)propName object:(id)obj {
  unsigned int attributeCount;
  NSMutableDictionary *accessors = [NSMutableDictionary dictionaryWithCapacity:2];
  
  BOOL  customGetter  = NO,
        customSetter  = NO,
        readonly      = NO;
  
  objc_property_attribute_t *attributes = property_copyAttributeList(property, &attributeCount);
  for (int j = 0; j < attributeCount; j++) {
    objc_property_attribute_t attribute = attributes[j];
      
    NSString *value       = objCStr(attribute.value);
    switch (attribute.name[0]) {
        
      case 'G': /* custom getter */
        customGetter = YES;
        accessors[@"getter"] = value;
        break;
        
      case 'S': /* custom setter */
        customSetter = YES;
        accessors[@"setter"] = value;
        break;
        
      case 'R': /* readonly */
        readonly = YES;
        accessors[@"setter"] = @"READONLY";
        break;
        
      default:
        break;
    }
  }
  if (!customGetter && [obj respondsToSelector:NSSelectorFromString(propName)]) {
    accessors[@"getter"] = propName;
  }
  if (!customSetter && !readonly) {
    NSString *firstLetterCap  = [[propName substringToIndex:1] uppercaseString];
    NSString *theRest         = [propName substringFromIndex:1];
    NSString *setter          = [NSString stringWithFormat:@"set%@%@:", firstLetterCap, theRest];
    if ([obj respondsToSelector:NSSelectorFromString(setter)]) { accessors[@"setter"] = setter; }
    else { accessors[@"setter"] = @"<UNKNOWN>"; }
  }
  free(attributes);
  return accessors;
}

+ (NSString *)methodDescription:(Method)m {
  char buff[LPJSONUtilsIntrospectionMethodDescriptionBufferLength];
  NSMutableString *description = [NSMutableString string];
  
  int numArgs = method_getNumberOfArguments(m);
  for (int i = 0; i < numArgs; i++) {
    method_getArgumentType(m, i, buff, LPJSONUtilsIntrospectionMethodDescriptionBufferLength);
    [description appendFormat:@"Arg: %s\t", buff];
  }
  return description;
}

@end
