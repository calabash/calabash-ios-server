#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPInfoPlist.h"

static unsigned short const LPCalabashServerDefaultPort = 37265;
static NSString *const LPCalabashServerPortInfoPlistKey = @"CalabashServerPort";

@implementation LPInfoPlist

- (unsigned short) serverPort {
  NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
  NSNumber *infoPlistValue = info[LPCalabashServerPortInfoPlistKey];
  if (!infoPlistValue) {
    return LPCalabashServerDefaultPort;
  } else {
    return [infoPlistValue unsignedShortValue];
  }
}

- (NSString *) stringForDTSDKName {
  NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
  return info[@"DTSDKName"];
}

- (NSString *) stringForDisplayName {
  return [[NSBundle mainBundle] infoDictionary][@"CFBundleDisplayName"];
}

@end
