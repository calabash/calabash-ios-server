#import "FirstViewController.h"

@interface FirstViewController ()

@end

@implementation FirstViewController

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
}

- (void)viewDidLoad {
  [super viewDidLoad];
}

- (void) viewWillLayoutSubviews {
  NSString *path = [[NSBundle mainBundle] pathForResource:@"lp-simple-example"
                                                   ofType:@"html"];
  NSURL *url = [NSURL fileURLWithPath:path];
  [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
}

- (void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event
{

  if (motion == UIEventSubtypeMotionShake) {
    [self showAlertWithMessage:@"shake detected!"];
  }
  [super motionBegan:motion withEvent:event];
}


#pragma mark - Alert messages

- (void)showAlertWithMessage:(NSString *)message {
  UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@""
                                                      message:message
                                                     delegate:nil
                                            cancelButtonTitle:nil
                                            otherButtonTitles:@"OK", nil];

  [alertView show];
}

@end
