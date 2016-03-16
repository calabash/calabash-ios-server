#import "SecondViewController.h"

@interface SecondViewController ()

@property (weak, nonatomic) IBOutlet UIButton *topLeftButton;
@property (weak, nonatomic) IBOutlet UIButton *topRightButton;
@property (weak, nonatomic) IBOutlet UIButton *bottomLeftButton;
@property (weak, nonatomic) IBOutlet UIButton *bottomRightButton;
@property (weak, nonatomic) IBOutlet UIButton *middleLeftButton;
@property (weak, nonatomic) IBOutlet UIButton *middleRightButton;
@property (weak, nonatomic) IBOutlet UIButton *topMiddleButton;
@property (weak, nonatomic) IBOutlet UIButton *bottomMiddleButton;
- (IBAction)buttonTouchedSecret:(UIButton *)sender;

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
  NSArray *subviews = [self.view subviews];
  for (UIView *subView in subviews) {
    if ([subView isKindOfClass:[UIButton class]]) {
      UIButton *button = (UIButton *)subView;
      [button setTitle:@"Hidden" forState:UIControlStateNormal];
    }
  }
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
}

- (IBAction)buttonTouchedSecret:(UIButton *)sender {
  [sender setTitle:@"Found me!" forState:UIControlStateNormal];
}

@end
