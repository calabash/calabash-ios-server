//
//  LPOrientationOperation.m
//  Calabash
//
//  Copyright (c) 2013 Xamarin. All rights reserved.
//

#import "LPOrientationOperation.h"

static NSString *const kDevice = @"device";
static NSString *const kStatusBar = @"status_bar";
static NSString *const kLeft = @"left";
static NSString *const kRight = @"right";
static NSString *const kUp = @"up";
static NSString *const kDown = @"down";
static NSString *const kUnknown = @"unknown";
static NSString *const kFaceDown = @"face down";
static NSString *const kFaceUp = @"face up";

@implementation LPOrientationOperation

- (NSString *) description {
  return [NSString stringWithFormat:@"Orientation: %@", _arguments];
}


+ (NSString *) deviceOrientation {

  [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
  UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
  [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
  switch (orientation) {
    case UIDeviceOrientationUnknown: return kUnknown;
    case UIDeviceOrientationPortrait: return kDown;
    case UIDeviceOrientationPortraitUpsideDown: return kUp;
      /*** UNEXPECTED ***/
      /*
       confusing semantics

       the rotation methods in the gem orient by the position of the home button
       e.g. if the home is on the right we say "the device is in the right orientation"

       from the apple docs -

       UIDeviceOrientationLandscapeRight:  The device is in landscape mode,
       with the device held upright and the home button on the __left__ side.

       ===>  so we reverse left and right <===
       */
    case UIDeviceOrientationLandscapeLeft: return kRight;
    case UIDeviceOrientationLandscapeRight: return kLeft;
      /******************/
    case UIDeviceOrientationFaceDown: return kFaceDown;
    case UIDeviceOrientationFaceUp: return kFaceUp;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunreachable-code"
    default: return kUnknown;
#pragma clang diagnostic pop
  }
}


+ (NSString *) statusBarOrientation {
  UIInterfaceOrientation orientation = [[UIApplication sharedApplication]
          statusBarOrientation];
  switch (orientation) {
    case UIInterfaceOrientationPortrait: return kDown;
    case UIInterfaceOrientationPortraitUpsideDown: return kUp;
      /*** UNEXPECTED ***/
      /*
       confusing semantics

       from the app docs -

       UIInterfaceOrientationLandscapeLeft: The device is in landscape mode,
       with the device held upright and the home button on the __left__ side.

       ==> no need to reverse left and right <==
      */
    case UIInterfaceOrientationLandscapeLeft: return kLeft;
    case UIInterfaceOrientationLandscapeRight: return kRight;
      /******************/
  }
}


// _arguments ==> {'device' | 'status_bar'}
- (id) performWithTarget:(UIView *) _view error:(NSError **) error {

  NSUInteger argCount = [_arguments count];
  if (argCount == 0) {
    NSLog(@"Warning: requires exactly one argument: {'%@' | '%@'} found none",
            kDevice, kStatusBar);
    return nil;
  }

  if (argCount > 1) {
    NSLog(@"Warning: argument should be {'%@' | '%@'} - found '[%@']", kDevice,
            kStatusBar, [_arguments componentsJoinedByString:@", "]);
    return nil;
  }

  NSString *firstArg = [_arguments objectAtIndex:0];
  if ([@[kDevice, kStatusBar] containsObject:firstArg] == NO) {
    NSLog(@"Warning: argument should be {'%@' | '%@'} - found '%@'", kDevice,
            kStatusBar, firstArg);
  }

  if ([kDevice isEqualToString:firstArg]) {
    return [LPOrientationOperation deviceOrientation];
  } else if ([kStatusBar isEqualToString:firstArg]) {
    return [LPOrientationOperation statusBarOrientation];
  } else {
    NSLog(@"Warning: feel through conditional for arguments: '[%@]'",
            [_arguments componentsJoinedByString:@", "]);
    return nil;
  }
}

@end
