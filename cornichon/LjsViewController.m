//
//  LjsViewController.m
//  cornichon
//
//  Created by Joshua Moody on 18.6.12.
//  Copyright (c) 2012 Little Joy Software. All rights reserved.
//

#import "LjsViewController.h"

@interface LjsViewController ()

@end

@implementation LjsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
      return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
  } else {
      return YES;
  }
}

@end
