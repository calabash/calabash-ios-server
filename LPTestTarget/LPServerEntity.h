#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface LPServerEntity : NSManagedObject

@property(nonatomic, copy) NSString *name;
@property(nonatomic, copy) NSString *address;
@property(nonatomic, assign) NSInteger lastPing;

@end
