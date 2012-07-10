//
//  LPFirstViewController.h
//  ServerTest
//
//  Created by Joshua Moody on 2.7.12.
//  Copyright (c) 2012 Little Joy Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LPFirstViewController : UIViewController

- (IBAction)buttonTouched:(id)sender forEvent:(UIEvent *)event;
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *button;

@end
