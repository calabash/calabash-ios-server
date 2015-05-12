#import <UIKit/UIKit.h>
@class NSManagedObjectContext;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic, readonly) NSManagedObjectContext *managedObjectContext;

@end
