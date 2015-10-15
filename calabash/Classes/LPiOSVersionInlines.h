NS_INLINE NSString* lp_sys_version() {
  static dispatch_once_t onceToken;
  static NSString *shared  = nil;
  dispatch_once(&onceToken, ^{
    shared = [[UIDevice currentDevice] systemVersion];
  });
  return shared;
}

NS_INLINE BOOL lp_ios_version_eql(NSString* v) {
  return [lp_sys_version() compare:v options:NSNumericSearch] == NSOrderedSame;
}

NS_INLINE BOOL lp_ios_version_gt(NSString* v) {
  return [lp_sys_version() compare:v options:NSNumericSearch] == NSOrderedDescending;
}

NS_INLINE BOOL lp_ios_version_gte(NSString* v) {
  return [lp_sys_version() compare:v options:NSNumericSearch] != NSOrderedAscending;
}

NS_INLINE BOOL lp_ios_version_lt(NSString* v) {
  return [lp_sys_version() compare:v options:NSNumericSearch] == NSOrderedAscending;
}

NS_INLINE BOOL lp_ios_version_lte(NSString* v) {
  return [lp_sys_version() compare:v options:NSNumericSearch] != NSOrderedDescending;
}