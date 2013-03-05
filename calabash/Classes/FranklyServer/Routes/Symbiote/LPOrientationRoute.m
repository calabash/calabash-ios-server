//
//  OrientationCommand.m
//  Chase.Mobi
//
//  Created by Pete Hodgson on 9/21/10.
//  Copyright 2010 ThoughtWorks. See NOTICE file for details.
//
#import "LPOrientationRoute.h"

#import "LPHTTPDataResponse.h"
#import "LPRouter.h"


@implementation LPOrientationRoute

- (NSDictionary *)representOrientation:(NSString *)orientation withDetailedOrientation:(NSString *)detailedOrientation{
    return [NSDictionary dictionaryWithObjectsAndKeys:orientation,@"orientation", detailedOrientation,@"detailed_orientation",nil];
}

- (NSDictionary *)getOrientationRepresentationViaStatusBar{
    switch([[UIApplication sharedApplication] statusBarOrientation]){
		case UIInterfaceOrientationLandscapeLeft:
            return [self representOrientation:@"landscape" withDetailedOrientation:@"landscape_left"];
		case UIInterfaceOrientationLandscapeRight:
            return [self representOrientation:@"landscape" withDetailedOrientation:@"landscape_right"];
		case UIInterfaceOrientationPortrait:
            return [self representOrientation:@"portrait" withDetailedOrientation:@"portrait"];
		case UIInterfaceOrientationPortraitUpsideDown:
            return [self representOrientation:@"portrait" withDetailedOrientation:@"portrait_upside_down"];
        default:
            NSLog(@"Device orientation via status bar is unknown");
            return nil;
    }
}

- (NSDictionary *)getOrientationRepresentationViaDevice{
    switch ( [UIDevice currentDevice].orientation ) {
		case UIDeviceOrientationLandscapeRight:
            return [self representOrientation:@"landscape" withDetailedOrientation:@"landscape_right"];
		case UIDeviceOrientationLandscapeLeft:
            return [self representOrientation:@"landscape" withDetailedOrientation:@"landscape_left"];
		case UIDeviceOrientationPortrait:
            return [self representOrientation:@"portrait" withDetailedOrientation:@"portrait"];
		case UIDeviceOrientationPortraitUpsideDown:
            return [self representOrientation:@"portrait" withDetailedOrientation:@"portrait_upside_down"];
        case UIDeviceOrientationFaceUp:
            NSLog(@"Device orientation is face up");
            return nil;
        case UIDeviceOrientationFaceDown:
            NSLog(@"Device orientation is face down");
            return nil;
        default:
            NSLog(@"Device orientation via device is unknown");
            return nil;
	}
}

- (NSString *)getOrientationDescriptionViaDevice{
    switch ( [UIDevice currentDevice].orientation ) {
		case UIDeviceOrientationLandscapeRight:
		case UIDeviceOrientationLandscapeLeft:
			return @"landscape";
		case UIDeviceOrientationPortrait:
		case UIDeviceOrientationPortraitUpsideDown:
			return @"portrait";
        case UIDeviceOrientationFaceUp:
            NSLog(@"Device orientation is face up");
            //fall thru
        case UIDeviceOrientationFaceDown:
            NSLog(@"Device orientation is face down");
            //fall thru
        case UIDeviceOrientationUnknown:
            NSLog(@"Device orientation is unknown");
            //fall thru
		default:
            return nil;
	}
}

- (BOOL)supportsMethod:(NSString *)method atPath:(NSString *)path {
    return [method isEqualToString:@"GET"];
}

#pragma mark Route implementation
- (NSObject<LPHTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path{

   	NSDictionary *orientationDescription = [self getOrientationRepresentationViaDevice];
    if( !orientationDescription ) {
        orientationDescription = [self getOrientationRepresentationViaDevice];
	}
	if(orientationDescription != nil) {
		NSData *data = [NSJSONSerialization dataWithJSONObject: orientationDescription options: 0 error: nil];
		return [[LPHTTPDataResponse alloc] initWithData: data];
	}
    return nil;
}

@end