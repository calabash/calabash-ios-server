#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPProcessInfoRoute.h"
#import "LPJSONUtils.h"
#import "LPHTTPDataResponse.h"

@implementation LPProcessInfoRoute

- (BOOL) supportsMethod:(NSString *) method atPath:(NSString *) path {
  return [method isEqualToString:@"GET"];
}

- (BOOL) canHandlePostForPath:(NSArray *) path {
  return [@"process-info" isEqualToString:[path lastObject]];
}

- (id) handleRequestForPath:(NSArray *) path withConnection:(id) connection {
  if (![self canHandlePostForPath:path]) {  return nil;  }

  NSDictionary *version = [self JSONResponseForMethod:@"GET"
                                                  URI:@"process-version"
                                                 data:nil];
  NSData *jsonData = [[LPJSONUtils serializeDictionary:version]
                      dataUsingEncoding:NSUTF8StringEncoding];

  return [[LPHTTPDataResponse alloc] initWithData:jsonData];
}

- (NSDictionary *) JSONResponseForMethod:(NSString *) method
                                     URI:(NSString *) path
                                    data:(NSDictionary *) data {

  NSArray *arguments = [[NSProcessInfo processInfo] arguments];
  NSDictionary *environment = [[NSProcessInfo processInfo] environment];

  NSDictionary *info = @{@"arguments" : arguments,
                         @"environment" : environment};

  return info;
}

@end
