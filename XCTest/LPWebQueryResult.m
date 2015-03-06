#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPWebQueryResult.h"

#pragma mark - LPWebQueryHash - Abstract Class

@interface LPWebQueryHash ()

@property (strong, nonatomic) NSDictionary *dictionary;

- (BOOL) hasOnlyTheseKeys:(NSArray *) keys;

@end

@implementation LPWebQueryHash

- (id) initWithDictionary:(NSDictionary *) dictionary {
  self = [super init];
  if (self) {
    _dictionary = [dictionary mutableCopy];
  }
  return self;
}

- (BOOL) isSameAs:(id<LPWebQuerySameAs>) other {
  SEL selector = @selector(dictionary);
  if (![other respondsToSelector:selector]) {  return NO;  }

  NSMethodSignature *signature;
  signature = [LPWebQueryHash instanceMethodSignatureForSelector:selector];

  NSInvocation *invocation;
  invocation = [NSInvocation invocationWithMethodSignature:signature];
  [invocation setTarget:other];
  [invocation setSelector:selector];
  [invocation invoke];

  NSUInteger length = [signature methodReturnLength];
  void *buffer = (void *) malloc(length);

  [invocation invoke];
  [invocation getReturnValue:&buffer];

  id invocationResult = (__bridge id)buffer;

  if (![invocationResult isKindOfClass:[NSDictionary class]]) { return NO; }

  NSDictionary *otherDictionary = (NSDictionary *)invocationResult;

  return self.dictionary.count == otherDictionary.count;
}

- (BOOL) isValid {
  for (NSString *key in [self.dictionary allKeys]) {
    if ([[self.dictionary objectForKey:key] isEqual:[NSNull null]]) {
      return NO;
    }
  }
  return YES;
}

- (BOOL) hasOnlyTheseKeys:(NSArray *) keys {
  NSArray *hashKeys = [self.dictionary allKeys];

  if (hashKeys.count != keys.count) { return NO; }

  for (NSString *expectedKey in keys) {
    if ([hashKeys indexOfObject:expectedKey] == NSNotFound) {
      return NO;
    }
  }
  return YES;
}

@end

#pragma mark - LPWebQueryCenter - the center point

@implementation LPWebQueryCenter

- (NSNumber *) x { return self.dictionary[@"X"]; }
- (NSNumber *) y { return self.dictionary[@"Y"]; }

- (BOOL) isSameAs:(id<LPWebQuerySameAs>)other {
  if (![other isKindOfClass:[LPWebQueryCenter class]]) { return NO; }

  LPWebQueryCenter *center = (LPWebQueryCenter *) other;

  return
  [super isSameAs:other] &&
  [self.x isEqualToNumber:center.x] &&
  [self.y isEqualToNumber:center.y];
}

- (BOOL) isValid {
  return
  [super isValid] &&
  [self hasOnlyTheseKeys:@[@"X", @"Y"]];
}

@end

#pragma mark - LPWebQueryRect - the rect + left/top/width

@implementation LPWebQueryRect

- (NSNumber *) center_x { return self.dictionary[@"center_x"]; }
- (NSNumber *) center_y { return self.dictionary[@"center_y"]; }
- (NSNumber *) height { return self.dictionary[@"height"]; }
- (NSNumber *) left { return self.dictionary[@"left"]; }
- (NSNumber *) top { return self.dictionary[@"top"]; }
- (NSNumber *) width { return self.dictionary[@"width"]; }
- (NSNumber *) x { return self.dictionary[@"x"]; }
- (NSNumber *) y { return self.dictionary[@"y"]; }

- (BOOL) isSameAs:(id<LPWebQuerySameAs>)other {
  if (![other isKindOfClass:[LPWebQueryRect class]]) { return NO; }

  LPWebQueryRect *rect = (LPWebQueryRect *) other;

  return
  [super isSameAs:other] &&
  [self.center_x isEqualToNumber:rect.center_x] &&
  [self.center_y isEqualToNumber:rect.center_y] &&
  [self.height isEqualToNumber:rect.height] &&
  [self.left isEqualToNumber:rect.left] &&
  [self.top isEqualToNumber:rect.top] &&
  [self.width isEqualToNumber:rect.width] &&
  [self.x isEqualToNumber:rect.x] &&
  [self.y isEqualToNumber:rect.y];
}

- (BOOL) isValid {
  return
  [super isValid] &&
  [self hasOnlyTheseKeys:@[@"center_x", @"center_y", @"height", @"left",
                           @"top", @"width", @"x", @"y"]];
}

@end

#pragma mark - LPWebQueryResult - represents a single element found by a web query

@implementation LPWebQueryResult

- (id) initWithJSON:(NSString *) json {
  self = [super init];
  if (self) {
    NSData *data = [json dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *decoded = [NSJSONSerialization JSONObjectWithData:data
                                                            options:kNilOptions
                                                              error:nil];
    self.dictionary = decoded;
  }
  return self;
}

- (LPWebQueryRect *) rect {
  return [[LPWebQueryRect alloc] initWithDictionary:self.dictionary[@"rect"]];
}

- (LPWebQueryCenter *) center {
  return [[LPWebQueryCenter alloc] initWithDictionary:self.dictionary[@"center"]];
}

- (NSString *) klass { return self.dictionary[@"class"]; }
- (NSString *) href { return self.dictionary[@"href"]; }
- (NSString *) identifier { return self.dictionary[@"id"]; }
- (NSString *) nodeName { return self.dictionary[@"nodeName"]; }
- (NSString *) nodeType { return self.dictionary[@"nodeType"]; }
- (NSString *) textContent { return self.dictionary[@"textContent"]; }
- (NSString *) webView { return self.dictionary[@"webView"]; }

- (BOOL) isSameAs:(id<LPWebQuerySameAs>)other {
  if (![other isKindOfClass:[LPWebQueryResult class]]) { return NO; }

  LPWebQueryResult *element = (LPWebQueryResult *) other;

  return
  // Skip it because it is based on an object address
  //[self.webView isEqualToString:element.webView]
  [super isSameAs:other] &&
  [self.center isSameAs:element.center] &&
  [self.klass isEqualToString:element.klass] &&
  [self.href isEqualToString:element.href] &&
  [self.identifier isEqualToString:element.identifier] &&
  [self.nodeName isEqualToString:element.nodeName] &&
  [self.nodeType isEqualToString:element.nodeType] &&
  [self.rect isSameAs:element.rect] &&
  [self.textContent isEqualToString:element.textContent];
}

- (BOOL) isValid {
  return
  [super isValid] &&
  [self hasOnlyTheseKeys:@[@"center", @"class", @"href", @"id", @"nodeName",
                           @"nodeType", @"rect", @"textContent", @"webView"]];
}

@end
