#import "AppDelegate.h"
#import "MBFingerTipWindow.h"
#import <CoreData/CoreData.h>
#import "LPCoreDataStack.h"
#import "CocoaLumberjack/CocoaLumberjack.h"
#import "FirstViewController.h"
#import "SecondViewController.h"

static const DDLogLevel ddLogLevel = DDLogLevelDebug;

typedef struct {
  NSInteger code;
  CGFloat visibility;
  NSUInteger decibels;
} LPSmokeAlarm;

@interface AppDelegate ()

@end

@implementation AppDelegate

- (UIWindow *)window {
    if (!_window) {
        MBFingerTipWindow *ftWindow = [[MBFingerTipWindow alloc]
                                       initWithFrame:[[UIScreen mainScreen] bounds]];
        ftWindow.alwaysShowTouches = YES;
        _window = ftWindow;
    }
    return _window;
}

// Calabash backdoors
- (void) backdoorThatReturnsVoid { DDLogDebug(@"Method that returns void"); }
- (BOOL) backdoorYES { return YES; }
- (BOOL) backdoorNO { return NO; }
- (int) backdoorInt { return (int)-17; }
- (unsigned int) backdoorUInt { return (unsigned int)17; }
- (NSInteger) backdoorNSInteger { return (NSInteger)-17; }
- (NSUInteger) backdoorNSUInteger { return (NSUInteger)17; }
- (short) backdoorShort { return (short)-1; }
- (unsigned short) backdoorUShort { return (unsigned short)1; }
- (float) backdoorFloat { return (float)0.314; }
- (double) backdoorDouble { return (double)54.46; }
- (CGFloat) backdoorCGFloat { return (CGFloat)54.46; }
- (char *) backdoorCharStar { return "char *"; }
- (const char *) backdoorConstCharStar { return (const char *)"const char *"; }
- (char) backdoorChar { return 'c'; }
- (unsigned char) backdoorUChar { return (unsigned char)'C'; }
- (long) backdoorLong { return (long)-42; }
- (unsigned long) backdoorULong { return (unsigned long)42; }
- (long long) backdoorLongLong { return (long long)-43; }
- (unsigned long long) backdoorULongLong { return (unsigned long long)43; }
- (CGPoint) backdoorPoint { return CGPointZero; }
- (CGSize) backdoorSize { return CGSizeZero; }
- (CGRect) backdoorRect { return CGRectZero; }

- (LPSmokeAlarm) backdoorSmokeAlarm {
  LPSmokeAlarm alarm;
  alarm.code = -1;
  alarm.visibility = 0.5;
  alarm.decibels = 10;
  return alarm;
}

// There is Objective-C encoding for long double
// Calling backdoor will raise an exception
// Xcode 7 update: looks like "D" is the long double encoding
- (long double) backdoorLDouble { return (long double)54.46; }

- (NSArray *) backdoorArray { return @[@"a", @"b", @(3)]; }
- (NSString *) backdoorString { return @"string"; }
- (NSDate *) backdoorDate { return [NSDate date]; }
- (NSNumber *) backdoorNumber { return @(11); }
- (NSString *) backdoorWithString:(NSString *) arg { return arg; }

- (NSDictionary *) backdoorDictionary {
  return
    @{
      @"a" : @(0),
      @"b" : @(1),
      @"c" : [NSNull null]
    };
}

- (NSArray *) backdoorWithString:(NSString *) string
                           array:(NSArray *) array {
  return @[string, array];
}

- (NSDictionary *) backdoorWithString:(NSString *) string
                                array:(NSArray *) array
                           dictionary:(NSDictionary *) dictionary {
  return
    @{
       @"string" : string,
       @"array" : array,
       @"dictionary" : dictionary
    };
}

- (BOOL) backdoorWithBOOL_YES:(BOOL) arg { return arg == YES; }
- (BOOL) backdoorWithBOOL_NO:(BOOL) arg { return arg == NO; }
- (BOOL) backdoorWithBool_true:(bool) arg { return arg == true; }
- (BOOL) backdoorWithBool_false:(bool) arg { return arg == false; }
- (BOOL) backdoorWithNSInteger:(NSInteger) arg { return arg == -17; }
- (BOOL) backdoorWithNSUInteger:(NSUInteger) arg { return arg == 17; }
- (BOOL) backdoorWithShort:(short) arg { return arg == -1; }
- (BOOL) backdoorWithUShort:(unsigned short) arg { return arg == 1; }
- (BOOL) backdoorWithCGFloat:(CGFloat) arg {
  return arg < 54.47 && arg > 54.45;
}
- (BOOL) backdoorWithDouble:(double) arg {
  return arg < 54.47 && arg > 54.45;
}
- (BOOL) backdoorWithFloat:(float) arg {
  return arg < 0.3141 && arg > 0.3140;
}
- (BOOL) backdoorWithChar:(char) arg { return arg == 'c'; }
- (BOOL) backdoorWithUChar:(unsigned char) arg { return arg == 'C'; }
- (BOOL) backdoorWithLong:(long) arg { return arg == -42; }
- (BOOL) backdoorWithULong:(unsigned long) arg { return arg == 42; }
- (BOOL) backdoorWithLongLong:(long long) arg { return arg == -43; }
- (BOOL) backdoorWithULongLong:(unsigned long long) arg { return arg == 43; }

- (BOOL) backdoorWithArgCharStar:(char *) arg {
  NSString *argObjC = [NSString stringWithCString:(const char *)arg
                                         encoding:NSASCIIStringEncoding];
  return [argObjC isEqualToString:@"char *"];
}

- (BOOL) backdoorWithArgConstCharStar:(const char *) arg {
 NSString *argObjC = [NSString stringWithCString:arg
                                        encoding:NSASCIIStringEncoding];
  return [argObjC isEqualToString:@"const char *"];
}

- (BOOL) backdoorWithArgCGPoint:(CGPoint) arg {
  return arg.x == 1 && arg.y == 2;
}

- (BOOL) backdoorWithArgCGRect:(CGRect) arg {
  return arg.origin.x == 1 && arg.origin.y == 2 && arg.size.width == 3 && arg.size.height == 4;
}

- (BOOL) backdoorWithArgClass:(Class) arg {
  NSString *arrayClassName = NSStringFromClass([NSArray class]);
  NSString *argClassname = NSStringFromClass(arg);
  return [arrayClassName isEqualToString:argClassname];
}

- (BOOL) backdoorWithArgSelf:(id) arg {
  NSString *selfClass = NSStringFromClass([self class]);
  NSString *argClass = NSStringFromClass([arg class]);
  return [selfClass isEqualToString:argClass];
}

- (BOOL) backdoorWithArgNil:(id) arg {
  return !arg;
}

#pragma mark - Unhandled Argument Types

- (void) backdoorWithArgVoidStar:(void *) arg { };
- (void) backdoorWithFloatStar:(float *) arg { };
- (BOOL) backdoorWithArgObjectStarStar:(NSError *__autoreleasing*) arg { return NO; }
- (void) backdoorWithArgSelector:(SEL) arg { }
- (void) backdoorWithArgPrimativeArray:(int []) arg { }
- (void) backdoorWithArgStruct:(LPSmokeAlarm) arg { }

@synthesize managedObjectContext = _managedObjectContext;

- (NSManagedObjectContext *) managedObjectContext {
  if (_managedObjectContext) { return _managedObjectContext; }
  _managedObjectContext = [[LPCoreDataStack new] managedObjectContext];
  return _managedObjectContext;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

  [DDLog addLogger:[DDTTYLogger sharedInstance]];
  [DDLog addLogger:[DDASLLogger sharedInstance]];
  DDLogDebug(@"Configured CocoaLumberjack!");

  UIViewController *firstController, *secondController;

  firstController = [FirstViewController new];

  secondController = [[SecondViewController alloc]
                      initWithNibName:@"SecondViewController"
                      bundle:nil];
  UITabBarController *tabController = [UITabBarController new];
  tabController.tabBar.translucent = NO;
  tabController.viewControllers = @[firstController, secondController];

  self.window.rootViewController = tabController;
  [self.window makeKeyAndVisible];
  return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
  // Sent when the application is about to move from active to inactive state.
  // This can occur for certain types of temporary interruptions (such as an
  // incoming phone call or SMS message) or when the user quits the application
  // and it begins the transition to the background state. Use this method to
  // pause ongoing tasks, disable timers, and throttle down OpenGL ES frame
  // rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
  // Use this method to release shared resources, save user data, invalidate
  // timers, and store enough application state information to restore your
  // application to its current state in case it is terminated later.  If your
  // application supports background execution, this method is called instead
  // of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
  // Called as part of the transition from the background to the inactive state;
  // here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
  // Restart any tasks that were paused (or not yet started) while the
  // application was inactive. If the application was previously in the
  // background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
  // Called when the application is about to terminate. Save data if
  // appropriate. See also applicationDidEnterBackground:.
}

@end
