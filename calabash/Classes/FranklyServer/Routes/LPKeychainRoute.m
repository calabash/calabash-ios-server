//
//  LPKeychainRoute.m
//  calabash
//
//  Created by John Gallagher on 2/15/14.
//  Copyright (c) 2014 LessPainful. All rights reserved.
//

#import "LPKeychainRoute.h"
#import "LPJSONUtils.h"
#import "LPSSKeychain.h"

@implementation LPKeychainRoute

- (BOOL) supportsMethod:(NSString *) method atPath:(NSString *) path {
  return [method isEqualToString:@"POST"] ||[method isEqualToString:@"GET"];
}

- (NSDictionary *) JSONResponseForMethod: (NSString *)method URI: (NSString *)path data: (NSDictionary*)data {
  NSError *error;

  if ([method isEqualToString:@"POST"]) {
    NSString *service = data[@"service"];
    if (!service) {
      // no service - clear out the entire keychain
      for (NSDictionary *d in [LPSSKeychain allAccounts]) {
        service = d[kLPSSKeychainWhereKey];
        NSString *account = d[kLPSSKeychainAccountKey];
        if (![LPSSKeychain deletePasswordForService:service account:account error:&error]) {
          return @{@"outcome": @"FAILURE",
                   @"reason": [NSString stringWithFormat:@"Error deleting password for %@ in service %@", account, service],
                   @"details": error.localizedDescription};

        }
      }
      return @{@"outcome": @"SUCCESS", @"results": @[]};
    }

    NSString *account = data[@"account"];
    if (!account) {
      // no account - clear out all accounts for this service
      for (NSDictionary *d in [LPSSKeychain accountsForService:service]) {
        service = d[kLPSSKeychainWhereKey];
        account = d[kLPSSKeychainAccountKey];
        if (![LPSSKeychain deletePasswordForService:service account:account error:&error]) {
          return @{@"outcome": @"FAILURE",
                   @"reason": [NSString stringWithFormat:@"Error deleting password for %@ in service %@", account, service],
                   @"details": error.localizedDescription};

        }
      }
      return @{@"outcome": @"SUCCESS", @"results": @[]};
    }

    NSString *password = data[@"password"];
    if (!password) {
      // no password - delete this account's password
      if ([LPSSKeychain deletePasswordForService:service account:account error:&error]) {
        return @{@"outcome": @"SUCCESS", @"results": @[]};
      } else {
        return @{@"outcome": @"FAILURE",
                 @"reason": [NSString stringWithFormat:@"Error deleting password for %@ in service %@", account, service],
                 @"details": error.localizedDescription};
      }
    }

    // Got service, account, and password - set it!
    if ([LPSSKeychain setPassword:password forService:service account:account error:&error]) {
      return @{@"outcome": @"SUCCESS", @"results": @[]};
    } else {
      return @{@"outcome": @"FAILURE",
               @"reason": [NSString stringWithFormat:@"Error setting password for %@ in service %@", account, service],
               @"details": error.localizedDescription};
    }
  }

  NSString *service = data[@"service"];
  if (!service) {
    // not even a service - return all accounts
    return @{@"outcome": @"SUCCESS",
             @"results": [LPSSKeychain allAccounts] ?: @[]};
  }

  NSString *account = data[@"account"];
  if (!account) {
    // got a service but no account - return list of accounts
    // for this service
    return @{@"outcome": @"SUCCESS",
             @"results": [LPSSKeychain accountsForService:service] ?: @[]};
  }

  // see http://goo.gl/JrFJMM
  // for details about why this reports 'FAILURE' and what can be done on the client side
  // Got a service and an account; send back the password
  NSString *password = [LPSSKeychain passwordForService:service
                                                account:account
                                                  error:&error];
  if (password) {
    return @{@"outcome": @"SUCCESS", @"results": @[password]};
  } else {
    return @{@"outcome": @"FAILURE",
             @"reason": [NSString stringWithFormat:@"Error looking up password for %@ in service %@", account, service],
             @"details": error.localizedDescription};
  }
}

@end
