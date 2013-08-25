//
//  DumpCommand.m
//  Frank
//
//  Created by phodgson on 5/30/10.
//  Copyright 2010 ThoughtWorks. See NOTICE file for details.
//
#import "LPDumpRoute.h"

#import "LPRouter.h"
#import "LPHTTPResponse.h"
#import "LPHTTPDataResponse.h"
#import "UIView+HierarchyDump.h"

@interface LPDumpRoute()
@property (nonatomic) NSMutableDictionary *classMapping;
@end

@implementation LPDumpRoute

- (id) init {
    self = [super init];
    if(self) {
        self.classMapping = [[NSMutableDictionary alloc] init];
        [self loadClassMapping];
    }
    return self;
}

- (void) loadClassMapping {
    NSString *staticResourceBundlePath = [[NSBundle mainBundle] pathForResource: @"symbiote_static_resources.bundle" ofType: nil];
    NSBundle *staticResourceBundle = [NSBundle bundleWithPath: staticResourceBundlePath];

    [self loadClassMappingFromBundle:staticResourceBundle plistFile:@"ViewAttributeMapping" warnIfNotFound:YES];
    [self loadClassMappingFromBundle:staticResourceBundle plistFile:@"UserViewAttributeMapping" warnIfNotFound:NO];
    
    NSLog(@"Done loading view attribute mapping, found %i classes mapped.\nMapping definition:\n%@", self.classMapping.count, self.classMapping);
}

- (void)loadClassMappingFromBundle:(NSBundle *)bundle plistFile:(NSString *)fileName warnIfNotFound:(BOOL)warn {

    NSString *mappingPath = [bundle pathForResource:fileName ofType:@"plist"];
    if([mappingPath length] == 0) {
        if (warn) {
            NSLog(@"Warning, could NOT find %@.plist in symbiote_static_resources.bundle", fileName);
        }
        return;
    }

    // load the plist
    NSLog(@"Loading class mapping definition from %@.plist in symbiote_static_resources.bundle", fileName);
    NSDictionary *theClassMapping = [NSDictionary dictionaryWithContentsOfFile: mappingPath];
    // and turn all keys to Class instances and load the attributes for that class
    for(NSString *key in theClassMapping.keyEnumerator) {
        Class clazz = NSClassFromString(key);
        if(clazz == nil) {
            NSLog(@"Warning, class %@ could not be resolved, skipping.", key);
            continue;
        }

        // abort this class if the value isn't an array
        id attributes = [theClassMapping objectForKey: key];
        if(![attributes isKindOfClass: NSArray.class]) {
            NSLog(@"Warning, attribute value for class %@ isn't an array, skipping.", key);
            continue;
        }

        [self addAttributeMappings:attributes forClass:clazz];
    }
}

- (void)addAttributeMappings:(NSArray *)attributes forClass:(Class)clazz{
    NSArray *existingAttributes = [self.classMapping objectForKey:NSStringFromClass(clazz)];
    if (existingAttributes) {
        // This class already has a mapping.  Add new attributes to the
        // end of the list.
        NSMutableArray *mergedAttributes = [NSMutableArray arrayWithArray:existingAttributes];
        for (NSString *attribute in attributes) {
            if (![existingAttributes containsObject:attribute]) {
                [mergedAttributes addObject:attribute];
            }
        }
        attributes = mergedAttributes;
    }
    [self.classMapping setObject:attributes forKey:NSStringFromClass(clazz)];
}

#pragma mark - Command handling
- (BOOL)supportsMethod:(NSString *)method atPath:(NSString *)path {
    return [method isEqualToString:@"GET"] || [method isEqualToString: @"POST"];
}

- (NSObject<LPHTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path {
    // serialize starting from root window and return json representation of it
    UIWindow *root = [UIApplication sharedApplication].keyWindow;
    
	NSDictionary *dom = [root dumpHierarchyWithMapping: self.classMapping];
	if(dom != nil) {
		NSData *data = [NSJSONSerialization dataWithJSONObject: dom options: 0 error: nil];
		return [[LPHTTPDataResponse alloc] initWithData: data];
	}
    return nil;
}

@end