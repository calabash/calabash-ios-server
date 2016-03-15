#import "SecondViewController.h"

@interface SecondViewController ()

@property (weak, nonatomic) IBOutlet UIButton *secretButton;
- (IBAction)buttonTouchedSecret:(id)sender;

@end

@implementation SecondViewController

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];

  if (self) {
    UIImage *image = [UIImage imageNamed:@"second"];
    NSString *title = NSLocalizedString(@"Second", @"title of second tab bar");
    self.tabBarItem = [[UITabBarItem alloc] initWithTitle:title
                                                    image:image
                                                      tag:0];
  }

  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [self.secretButton setTitle:@"Hidden" forState:UIControlStateNormal];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
}

- (IBAction)buttonTouchedSecret:(id)sender {
  NSLog(@"Secret button touched");
  [self.secretButton setTitle:@"Found me!" forState:UIControlStateNormal];
}

@end
