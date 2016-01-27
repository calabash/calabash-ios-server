#import "SecondViewController.h"

@interface SecondViewController ()

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

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
}

@end
