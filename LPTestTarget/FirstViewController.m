#import "FirstViewController.h"

@interface FirstViewController ()

- (void) showShakeAlert;

@end

@implementation FirstViewController

- (void) didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
}

- (void) viewDidLoad {
  [super viewDidLoad];
}

- (void) viewWillLayoutSubviews {
  NSString *path = [[NSBundle mainBundle] pathForResource:@"lp-simple-example"
                                                   ofType:@"html"];
  NSURL *url = [NSURL fileURLWithPath:path];
  [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
}

- (void) motionBegan:(UIEventSubtype) motion withEvent:(UIEvent *) event {

  if (motion == UIEventSubtypeMotionShake) {
    [self showShakeAlert];
  }
  [super motionBegan:motion withEvent:event];
}


#pragma mark - Alert messages

- (void) showShakeAlert {
  NSString *title = NSLocalizedString(@"Shaking",
                                      "Title of alert when the app detects a shake.");
  NSString *ok = NSLocalizedString(@"OK",
                                   @"Title of button that dismisses an alert.");
  NSString *message = NSLocalizedString(@"shake detected!",
                                        @"Message of the alert when the app dectects a shake.");
  UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                      message:message
                                                     delegate:nil
                                            cancelButtonTitle:nil
                                            otherButtonTitles:ok, nil];

  [alertView show];
}

@end
