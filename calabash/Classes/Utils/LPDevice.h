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
@property(copy, nonatomic, readonly) NSString *modelIdentifier;
@property(copy, nonatomic, readonly) NSString *formFactor;
@property(copy, nonatomic, readonly) NSString *deviceFamily;
@property(copy, nonatomic, readonly) NSString *name;
@property(copy, nonatomic, readonly) NSString *iOSVersion;
@property(copy, nonatomic, readonly) NSString *physicalDeviceModelIdentifier;

+ (LPDevice *) sharedDevice;

- (NSString *) simulatorModelIdentifier;
- (NSString *) simulatorVersionInfo;
- (BOOL) isSimulator;
- (BOOL) isPhysicalDevice;
- (BOOL) isIPhone6Like;
- (BOOL) isIPhone6PlusLike;
- (BOOL) isIPhone;
- (BOOL) isIPad;
- (BOOL) isIPadPro;
- (BOOL) isIPadPro12point9inch;
- (BOOL) isIPadPro9point7inch;
- (BOOL) isIPad9point7inch;
- (BOOL) isIPadPro10point5inch;
- (BOOL) isIPhone4Like;
- (BOOL) isIPhone5Like;
- (BOOL) isLetterBox;
- (BOOL) isIPhone10Like;
- (BOOL) isIPhone10SMaxLike;
- (BOOL) isIPhone10RLike;
- (BOOL) isIPhone10LetterBox;
- (BOOL) isIPhone11Like;
- (BOOL) isIPhone11ProLike;
- (BOOL) isIPhone11ProMaxLike;
- (BOOL) isIPhone12Like;
- (BOOL) isIPhone12ProLike;
- (BOOL) isIPhone12MiniLike;
- (BOOL) isIPhone12ProMaxLike;
- (BOOL) isIPhone13Like;
- (BOOL) isIPhone13ProLike;
- (BOOL) isIPhone13MiniLike;
- (BOOL) isIPhone13ProMaxLike;
- (NSString *) getIPAddress;

@end
