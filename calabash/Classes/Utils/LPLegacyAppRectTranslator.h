#import <Foundation/Foundation.h>

// Supports apps that have been compiled under SDK 6.* but are running on iOS >= 8.0
@interface LPLegacyAppRectTranslator : NSObject

- (BOOL) appUnderTestRequiresLegacyRectTranslation;
- (NSDictionary *) dictionaryAfterLegacyRectTranslation:(NSDictionary *) rectDictionary;

@end
