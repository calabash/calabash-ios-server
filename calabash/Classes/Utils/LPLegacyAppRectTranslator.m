#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPLegacyAppRectTranslator.h"
#import "LPInfoPlist.h"
#import "LPTouchUtils.h"

@interface LPLegacyAppRectTranslator ()

@property(strong, nonatomic) LPInfoPlist *infoPlist;
@property(strong, nonatomic) UIDevice *device;

- (BOOL) appCompiledAgainstSDK6;
- (BOOL) iOSVersionOnTestDeviceIsGteTo80;
- (UIInterfaceOrientation) statusBarOrientation;
- (BOOL) appOrientationRequiresTranslation;
- (CGSize) canonicalScreenSizeForLegacyApp;

@end

@implementation LPLegacyAppRectTranslator

- (LPInfoPlist *) infoPlist {
  if (_infoPlist) { return _infoPlist; }
  _infoPlist = [LPInfoPlist new];
  return _infoPlist;
}

- (UIDevice *) device {
  if (_device) { return _device; }
  _device = [UIDevice currentDevice];
  return _device;
}

- (UIInterfaceOrientation) statusBarOrientation {
  return [[UIApplication sharedApplication] statusBarOrientation];
}

- (BOOL) appCompiledAgainstSDK6 {
  NSString *dkSdk = [self.infoPlist stringForDTSDKName];
  return
  [dkSdk rangeOfString:@"6.0"].location != NSNotFound ||
  [dkSdk rangeOfString:@"6.1"].location != NSNotFound;
}

- (BOOL) iOSVersionOnTestDeviceIsGteTo80 {
  NSString *systemVersion = [self.device systemVersion];
  return [systemVersion compare:@"8.0" options:NSNumericSearch] != NSOrderedAscending;
}

// Don't be fooled: the UIDeviceOrientationIsLandscape(orientation) macro
// cannot be used here.
- (BOOL) appOrientationRequiresTranslation {
  NSUInteger orientation = [self statusBarOrientation];
  return
  orientation == UIInterfaceOrientationLandscapeLeft ||
  orientation == UIInterfaceOrientationLandscapeRight ||
  orientation == UIInterfaceOrientationPortraitUpsideDown;
}

- (BOOL) appUnderTestRequiresLegacyRectTranslation {
  return
  [self appCompiledAgainstSDK6] &&
  [self iOSVersionOnTestDeviceIsGteTo80] &&
  [self appOrientationRequiresTranslation];
}

- (CGSize) canonicalScreenSizeForLegacyApp {
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
    return CGSizeMake(768, 1024);
  } else if ([LPTouchUtils isThreeAndAHalfInchDevice]) {
    return CGSizeMake(320, 480);
  } else if ([LPTouchUtils is4InchDevice]) {
    return CGSizeMake(320, 568);
  } else {
    return CGSizeZero;
  }
}

- (NSDictionary *) dictionaryAfterLegacyRectTranslation:(NSDictionary *) rectDictionary {
  if (!rectDictionary) {
    NSLog(@"Cannot translate a nil dictionary; nothing to do");
    return rectDictionary;
  }

  NSArray *expectedKeys = @[@"center_x", @"center_y", @"x", @"y", @"width", @"height"];
  for (NSString *expectedKey in expectedKeys) {
    if (!rectDictionary[expectedKey]) {
      NSLog(@"Cannot translate dictionary: %@ it is missing key: %@",
            rectDictionary, expectedKey);
      NSLog(@"returning the original dictionary");
      return rectDictionary;
    }
  }

  UIInterfaceOrientation orientation = [self statusBarOrientation];

  NSMutableDictionary *translated;
  translated = [NSMutableDictionary dictionaryWithDictionary:rectDictionary];

  CGSize canonicalScreenSize = [self canonicalScreenSizeForLegacyApp];
  CGFloat canonWidth = canonicalScreenSize.width;
  CGFloat canonHeight = canonicalScreenSize.height;

  if (orientation == UIInterfaceOrientationLandscapeLeft) {
    CGFloat originalX = [rectDictionary[@"center_x"] floatValue];
    CGFloat originalY = [rectDictionary[@"center_y"] floatValue];
    translated[@"center_x"] = @(canonHeight - originalY);
    translated[@"center_y"] = @(originalX);
  } else if (orientation == UIInterfaceOrientationLandscapeRight) {
    CGFloat originalX = [rectDictionary[@"center_x"] floatValue];
    CGFloat originalY = [rectDictionary[@"center_y"] floatValue];
    translated[@"center_x"] = @(originalY);
    translated[@"center_y"] = @(canonWidth - originalX);
  } else if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
    CGFloat originalX = [rectDictionary[@"center_x"] floatValue];
    CGFloat originalY = [rectDictionary[@"center_y"] floatValue];
    translated[@"center_x"] = @(canonWidth - originalX);
    translated[@"center_y"] = @(canonHeight - originalY);
  } else {
    return rectDictionary;
  }
  return [NSDictionary dictionaryWithDictionary:translated];
}

@end
