//
//  LPFirstViewController.m
//  ServerTest
//
//  Created by Joshua Moody on 2.7.12.
//  Copyright (c) 2012 Little Joy Software. All rights reserved.
//

#import "LPFirstViewController.h"

@interface LPFirstViewController ()

@end

@implementation LPFirstViewController
@synthesize button;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    self.title = NSLocalizedString(@"First", @"First");
    self.tabBarItem.image = [UIImage imageNamed:@"first"];
    }
    return self;
}
							
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.button.accessibilityIdentifier = @"button";
}

- (void)viewDidUnload
{
    [self setButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (IBAction)buttonTouched:(id)sender forEvent:(UIEvent *)event {
    NSLog(@"button touched");
}
@end
