//
//  LPDevice.h
//  calabash
//
//  Created by Karl Krukow on 1/30/14.
//  Copyright (c) 2014 Xamarin. All rights reserved.
//
#import <UIKit/UIKit.h>

extern NSString *const LPDeviceSimKeyModelIdentifier;
extern NSString *const LPDeviceSimKeyVersionInfo;
extern NSString *const LPDeviceSimKeyIphoneSimulatorDevice_LEGACY;

@interface LPDevice : NSObject

@property(strong, nonatomic, readonly) NSDictionary *screenDimensions;
@property(assign, nonatomic, readonly) CGFloat sampleFactor;
@property(copy, nonatomic, readonly) NSString *modelIdentifier;
@property(copy, nonatomic, readonly) NSString *formFactor;
@property(copy, nonatomic, readonly) NSString *deviceFamily;
@property(copy, nonatomic, readonly) NSString *name;
@property(copy, nonatomic, readonly) NSString *iOSVersion;
@property(copy, nonatomic, readonly) NSString *physicalDeviceModelIdentifier;

+ (LPDevice *) sharedDevice;

- (NSString *) simulatorVersionInfo;

// Required for clients < 0.16.2 - @see LPVersionRoute
- (NSString *) LEGACY_iPhoneSimulatorDevice;
- (NSString *) LEGACY_systemFromUname;


- (BOOL) isSimulator;
- (BOOL) isPhysicalDevice;
- (BOOL) isIPhone6Like;
- (BOOL) isIPhone6PlusLike;
- (BOOL) isIPad;
- (BOOL) isIPadPro;
- (BOOL) isIPhone4Like;
- (BOOL) isIPhone5Like;
- (BOOL) isLetterBox;
- (NSString *) getIPAddress;

@end
