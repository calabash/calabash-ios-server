//
//  LPAppDelegate.h
//  ServerTest
//
//  Created by Joshua Moody on 2.7.12.
//  Copyright (c) 2012 Little Joy Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LPAppDelegate : UIResponder <UIApplicationDelegate, UITabBarControllerDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) UITabBarController *tabBarController;

@end
