//
//  SSKeychain.m
//  SSKeychain
//
//  Created by Sam Soffes on 5/19/10.
//  Copyright (c) 2010-2013 Sam Soffes. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "LPSSKeychain.h"

NSString *const kLPSSKeychainErrorDomain = @"com.samsoffes.sskeychain";
NSString *const kLPSSKeychainAccountKey = @"acct";
NSString *const kLPSSKeychainCreatedAtKey = @"cdat";
NSString *const kLPSSKeychainClassKey = @"labl";
NSString *const kLPSSKeychainDescriptionKey = @"desc";
NSString *const kLPSSKeychainLabelKey = @"labl";
NSString *const kLPSSKeychainLastModifiedKey = @"mdat";
NSString *const kLPSSKeychainWhereKey = @"svce";

#if __IPHONE_4_0 && TARGET_OS_IPHONE
    static CFTypeRef SSKeychainAccessibilityType = NULL;
#endif

@implementation LPSSKeychain

+ (NSString *)passwordForService:(NSString *)serviceName account:(NSString *)account {
	return [self passwordForService:serviceName account:account error:nil];
}


+ (NSString *)passwordForService:(NSString *)serviceName account:(NSString *)account error:(NSError *__autoreleasing *)error {
    LPSSKeychainQuery *query = [[LPSSKeychainQuery alloc] init];
    query.service = serviceName;
    query.account = account;
    [query fetch:error];
    return query.password;
}


+ (BOOL)deletePasswordForService:(NSString *)serviceName account:(NSString *)account {
	return [self deletePasswordForService:serviceName account:account error:nil];
}


+ (BOOL)deletePasswordForService:(NSString *)serviceName account:(NSString *)account error:(NSError *__autoreleasing *)error {
    LPSSKeychainQuery *query = [[LPSSKeychainQuery alloc] init];
    query.service = serviceName;
    query.account = account;
    return [query deleteItem:error];
}


+ (BOOL)setPassword:(NSString *)password forService:(NSString *)serviceName account:(NSString *)account {
	return [self setPassword:password forService:serviceName account:account error:nil];
}


+ (BOOL)setPassword:(NSString *)password forService:(NSString *)serviceName account:(NSString *)account error:(NSError *__autoreleasing *)error {
    LPSSKeychainQuery *query = [[LPSSKeychainQuery alloc] init];
    query.service = serviceName;
    query.account = account;
    query.password = password;
    return [query save:error];
}


+ (NSArray *)allAccounts {
    return [self accountsForService:nil];
}


+ (NSArray *)accountsForService:(NSString *)serviceName {
    LPSSKeychainQuery *query = [[LPSSKeychainQuery alloc] init];
    query.service = serviceName;
    return [query fetchAll:nil];
}


#if __IPHONE_4_0 && TARGET_OS_IPHONE
+ (CFTypeRef)accessibilityType {
	return SSKeychainAccessibilityType;
}


+ (void)setAccessibilityType:(CFTypeRef)accessibilityType {
	CFRetain(accessibilityType);
	if (SSKeychainAccessibilityType) {
		CFRelease(SSKeychainAccessibilityType);
	}
	SSKeychainAccessibilityType = accessibilityType;
}
#endif

@end
