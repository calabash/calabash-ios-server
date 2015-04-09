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

@end
