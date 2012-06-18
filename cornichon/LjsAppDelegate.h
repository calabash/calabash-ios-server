//
//  LjsAppDelegate.h
//  cornichon
//
//  Created by Joshua Moody on 18.6.12.
//  Copyright (c) 2012 Little Joy Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LjsViewController;

@interface LjsAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) LjsViewController *viewController;

@end
