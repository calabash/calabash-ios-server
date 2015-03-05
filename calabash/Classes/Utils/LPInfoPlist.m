#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPInfoPlist.h"

static unsigned short const LPCalabashServerDefaultPort = 37265;
static NSString *const LPCalabashServerPortInfoPlistKey = @"CalabashServerPort";

@interface LPInfoPlist ()

@property(strong, nonatomic, readonly) NSDictionary *infoDictionary;

@end

@implementation LPInfoPlist

@synthesize infoDictionary = _infoDictionary;

- (NSDictionary *) infoDictionary {
  if (_infoDictionary) { return _infoDictionary; }
  _infoDictionary = [[NSBundle mainBundle] infoDictionary];
  return _infoDictionary;
}

- (unsigned short) serverPort {
  NSDictionary *info = self.infoDictionary;
  NSNumber *infoPlistValue = info[LPCalabashServerPortInfoPlistKey];
  if (!infoPlistValue) {
    return LPCalabashServerDefaultPort;
  } else {
    return [infoPlistValue unsignedShortValue];
  }
}

- (NSString *) stringForDTSDKName {
  return self.infoDictionary[@"DTSDKName"];
}

- (NSString *) stringForDisplayName {
  return self.infoDictionary[@"CFBundleDisplayName"];
}

@end
