//
//  UIView+HierarchyDump.m
//  calabash
//
//  Created by Olivier Larivain on 3/6/13.
//  Copyright (c) 2013 LessPainful. All rights reserved.
//

#import "UIView+HierarchyDump.h"

#define PSEUDO_INF	@"inf"

@implementation UIView (HierarchyDump)
- (NSDictionary *) dumpHierarchyWithMapping: (NSDictionary *) classMapping {
    NSMutableDictionary *serializedView = [NSMutableDictionary dictionaryWithCapacity: 20];
	
    [serializedView setObject:NSStringFromClass(self.class) forKey: @"class"];
	
    // use the view's raw location in memory as a poor man's uid
    [serializedView setObject:[NSNumber numberWithInt:(int)self] forKey:@"uid"];
    
    // iterate on all mapping definition classes looking for a (super) class of the current object
    for(NSString *key in classMapping.keyEnumerator) {
        Class candidate = NSClassFromString(key);
        if(![self isKindOfClass:candidate]) {
            continue;
        }
        
        // now, serialize all defined attributes on the view, if possible
        NSArray *attributes = [classMapping objectForKey:key];
        for(NSString *attribute in attributes) {
            // fetch the value for that attribute and add it to the dictionary.
            // note: valueForAttribute is NOT nil safe (i.e. returns nil if value couldn't be extracted
            id value = [self valueForAttribute: attribute];
            
            // just skip nil values, we don't want to pollute the JSON tree with bullshitty empty values
            if(value == nil) {
                continue;
            }
            [serializedView setObject:value forKey:attribute];
        }
    }
	
	NSString *accessibilityIdentifier = self.accessibilityIdentifier;
	if(accessibilityIdentifier.length == 0) {
		accessibilityIdentifier = self.accessibilityLabel;
	}
	if(accessibilityIdentifier != nil) {
		[serializedView setObject: accessibilityIdentifier forKey: @"accessibilityLabel"];
	}
    
    // now, recurse on all subviews
    NSMutableArray *serializedSubviews = [NSMutableArray arrayWithCapacity: self.subviews.count];
    [serializedView setObject: serializedSubviews forKey: @"subviews"];
    
    for(UIView *subview in self.subviews) {
        NSDictionary *serializedSubview = [subview dumpHierarchyWithMapping: classMapping];
        [serializedSubviews addObject: serializedSubview];
    }
    
    return serializedView;
}

#pragma mark - Extracting an attribute
- (id) valueForAttribute: (NSString *) attribute {
	
	id value;
	
	// Just make sure the input is sane and we're not taking the app down
	@try {
		// Use KVC to get value for attribute, Raises NSUndefinedKeyException if key is not found
		value = [self valueForKey: attribute];
	}
	@catch (NSException *exception) {
		NSLog(@"Warning \"%@\" does not have a value for the key \"%@\".", self.class, attribute);
	}
	@finally {
		// Value can be retrieved via key or selector which are not alway identical, apple frequently overides getters for booleans an prefaces them with is
		if (!value) {
			SEL selector = NSSelectorFromString(attribute);
			if(![self respondsToSelector: selector]) {
				NSLog(@"Warning \"%@\" does not respond to \"%@\".", self.class, attribute);
				// TODO maybe we could remove that attribute from the classMapping since it doens't respond to selector?
				// if we decide to do, this check will have to move to -serializeView: since we've lost knowledge of the
				// class mapping defining this attribute
				return  nil;
			}
			
			value = [self performSelector:selector];
		}
	}
	
	if([value isKindOfClass: NSValue.class]) {
		value = [self extractInstanceFromValue: (NSValue *)value];
	}

    // at this point, we want only NSNumbers, NSArray, NSDictionary, NSString or NSNull,
    if(![value isKindOfClass: NSNumber.class] &&
	   ![value isKindOfClass: NSString.class] &&
	   ![value isKindOfClass: NSArray.class] &&
	   ![value isKindOfClass: NSDictionary.class] &&
	   ![value isKindOfClass: NSNull.class] &&
	   value != nil) {
        return [NSString stringWithFormat:@"<%@ @%i>", [value class], (int)value];
    }
    
    return value;
}

#pragma mark NSValue
- (id) extractInstanceFromValue:(NSValue *)value {
	
	const char * objcType = [value objCType];
	if(objcType == NULL) {
		return nil;
	}
	
	// Numbers just passthrough
	if([value isKindOfClass: NSNumber.class]) {
		if(isinf([(NSNumber*) value doubleValue])){
			return PSEUDO_INF;
		}
		return value;
	}
	
	// CG types
	NSDictionary * (^convertCGPoint)(CGPoint) = ^(CGPoint point) {
		return [NSDictionary dictionaryWithObjectsAndKeys:
				(isinf(point.x)) ? PSEUDO_INF : [NSNumber numberWithFloat: point.x], @"x",
				(isinf(point.y)) ? PSEUDO_INF : [NSNumber numberWithFloat: point.y], @"y",
				nil];
	};
	
	NSDictionary * (^convertCGSize)(CGSize) = ^(CGSize size) {
		return [NSDictionary dictionaryWithObjectsAndKeys:
				(isinf(size.width)) ? PSEUDO_INF : [NSNumber numberWithFloat:size.width], @"width",
				(isinf(size.height)) ? PSEUDO_INF : [NSNumber numberWithFloat:size.height], @"height",
				nil];
	};
	
	if(strcmp(@encode(CGRect), objcType) == 0) {
		CGRect rawRect = [value CGRectValue];
		
		return [NSDictionary dictionaryWithObjectsAndKeys:
				convertCGPoint(rawRect.origin), @"origin",
				convertCGSize(rawRect.size), @"size",
				nil];
	}
	
	
	if(strcmp(@encode(CGSize), objcType) == 0) {
		CGSize rawSize = [value CGSizeValue];
		return convertCGSize(rawSize);
	}
	
	if(strcmp(@encode(CGPoint), objcType) == 0) {
		CGPoint point = [value CGPointValue];
		return convertCGPoint(point);
	}
	
	NSString *typeString = [NSString stringWithFormat:@"%s", objcType];
    
    if( [typeString isEqualToString:@"f"] ){
        // for some reason we sometimes see NSValues which box a float but which are not NSNumbers. I don't understand
		// why. Re-boxing the value appears to do the trick however.
        float rawValue;
        [value getValue:&rawValue];
        return [NSNumber numberWithFloat:rawValue];
    }
	
	if([typeString hasPrefix: @"{"]){
		// Extract Class name from the type, format is {ClassName=Blablabla}
		NSString *valueType = [[[typeString substringFromIndex:1] componentsSeparatedByString:@"="] objectAtIndex:0];
		// In the future we could add support for converting any generic type into a dictionary, if it is helpful to do that
		return [NSString stringWithFormat:@"<%@>", valueType];
	}
	
	// just return nothing, we can't do much more anyway
	return nil;
}



@end
