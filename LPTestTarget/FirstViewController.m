#import "FirstViewController.h"

typedef enum : NSUInteger {
  kTagView = 0,
  kTagWebView
} view_tags;

@interface FirstViewController ()

@property(strong, nonatomic, readonly) UIWebView *webView;

- (void) showShakeAlert;

@end

@implementation FirstViewController

#pragma mark - Memory Management

@synthesize webView = _webView;

- (instancetype) init {
  self = [super init];
  if (self){
    UIImage *image = [UIImage imageNamed:@"first"];

    NSString *title = NSLocalizedString(@"First", @"title of first tab bar");
    self.tabBarItem = [[UITabBarItem alloc] initWithTitle:title
                                                    image:image
                                                      tag:0];
  }
  return self;
}

#pragma mark - Lazy Evaled Ivars

- (UIWebView *) webView {
  if (_webView) { return _webView; }
  CGRect frame = CGRectMake(0, 20,
                            self.view.bounds.size.width,
                            self.view.bounds.size.height - 20);
  _webView = [[UIWebView alloc] initWithFrame:frame];
  _webView.accessibilityLabel = @"Landing page";
  _webView.accessibilityIdentifier = @"landing page";
  _webView.tag = kTagWebView;
  return _webView;
}

#pragma mark - View Lifecycle

- (void) didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
}

- (void) loadView {
  CGRect frame = [[UIScreen mainScreen] applicationFrame];
  UIView *view = [[UIView alloc] initWithFrame:frame];

  view.tag = kTagView;
  view.accessibilityIdentifier = @"root";
  view.accessibilityLabel = @"Root";

  view.backgroundColor = [UIColor whiteColor];
  view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  self.view = view;
}

- (void) viewWillLayoutSubviews {
  [super viewWillLayoutSubviews];
}

- (void) viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
  if (![self.view viewWithTag:kTagWebView]) {
    UIWebView *webView = self.webView;
    [self.view addSubview:webView];

    NSString *page = @"https://calabash-ci.macminicolo.net/CalWebViewApp/page.html";
    NSURL *url = [NSURL URLWithString:page];
    [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
  }
  [super viewDidAppear:animated];
}

#pragma mark - Shake Delegate

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
