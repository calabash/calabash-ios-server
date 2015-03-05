#import <Foundation/Foundation.h>

@interface LPInfoPlist : NSObject

- (unsigned short) serverPort;
- (NSString *) stringForDTSDKName;
- (NSString *) stringForDisplayName;
- (NSString *) stringForIdentifier;
- (NSString *) stringForVersion;
- (NSString *) stringForShortVersion;

@end
