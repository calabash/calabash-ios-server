//
//  LPJSONUtils+Accessors.m
//  calabash
//
//  Created by Chris Fuentes on 6/5/15.
//  Copyright (c) 2015 Xamarin. All rights reserved.
//

#import "LPJSONUtils+Accessors.h"
#import <objc/runtime.h>

@interface LPJSONUtils ()
@end

#pragma mark - Convenience C String Util
static inline NSString *objCStr(const char *cString) {
  return [NSString stringWithCString:cString encoding:[NSString defaultCStringEncoding]];
};

@implementation LPJSONUtils (Accessors)


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

+ (NSDictionary *)accessorsForObject:(id)object options:(unsigned short)options {
  NSMutableDictionary *customAccessors = [NSMutableDictionary new];
  Class c = [object class];
  unsigned int propertyCount;
  
  do {
    objc_property_t *properties = class_copyPropertyList(c, &propertyCount);
    
    for (int i = 0; i < propertyCount; i++) {
      
      objc_property_t property  = properties[i];
      const char *propNameStr   = property_getName(property);
      
      if (propNameStr[0] != '_' || options & kLPAccessorOptionsOnlyExcludeSuperclasses) { continue; }
      
      NSDictionary *accessors = [self customAccessorsForProperty:property];
      if (accessors) {
        customAccessors[objCStr(propNameStr)] = accessors;
      }
    }
    
    free(properties);
    if (options & kLPAccessorOptionsOnlyExcludeSuperclasses) { break; }
  } while (( c = [c superclass] ));
  
  return customAccessors.count ? customAccessors : nil;
}

/*
 customAccessorsForProperty
 Returns custom named accessors, if any, for a given property of an object.
 
 @param property   the property for which you'd like the custom accessors
 @return  NSString the custom accessors if any (formatted like a JSON object),
 or nil if no custom properties exist.
 */
+ (NSDictionary *)customAccessorsForProperty:(objc_property_t)property {
  unsigned int attributeCount;
  NSMutableDictionary *accessors = [NSMutableDictionary dictionaryWithCapacity:2];
  
  objc_property_attribute_t *attributes = property_copyAttributeList(property, &attributeCount);
  for (int j = 0; j < attributeCount; j++) {
    objc_property_attribute_t attribute = attributes[j];
    
    if (strlen(attribute.value) > 0 && attribute.value[0] != '_'
        && (attribute.name[0] == 'G' || attribute.name[0] == 'S')) {
      
      NSString *value       = objCStr(attribute.value);
      
      if (attribute.name[0] == 'G') {
        accessors[@"getter"] = value;
      } else if (attribute.name[0] == 'S') {
        accessors[@"setter"] = value;
      }
    }
  }
  free(attributes);
  return accessors.count > 0 ? accessors : nil;
}

#define BUF_LEN 256
+ (NSString *)methodDescription:(Method)m {
  char buff[BUF_LEN];
  NSMutableString *description = [NSMutableString string];
  
  int numArgs = method_getNumberOfArguments(m);
  for (int i = 0; i < numArgs; i++) {
    method_getArgumentType(m, i, buff, BUF_LEN);
    [description appendFormat:@"Arg: %s\t", buff];
  }
  return description;
}

@end
