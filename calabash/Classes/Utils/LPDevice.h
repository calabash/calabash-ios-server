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

@interface LPDevice : NSObject

@property(strong, nonatomic, readonly) NSDictionary *screenDimensions;
@property(assign, nonatomic, readonly) CGFloat sampleFactor;
@property(copy, nonatomic, readonly) NSString *system;
@property(copy, nonatomic, readonly) NSString *model;
@property(copy, nonatomic, readonly) NSString *formFactor;

+ (LPDevice *) sharedDevice;

- (BOOL) isSimulator;
- (BOOL) isPhysicalDevice;
- (BOOL) isIPhone6;
- (BOOL) isIPhone6Plus;
- (BOOL) iPad;

@end
