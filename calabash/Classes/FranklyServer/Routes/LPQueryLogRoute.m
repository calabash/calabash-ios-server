//
//  LPQueryLogRoute.m
//  calabash
//
//  Created by Jim McBeath on 12/26/12.
//  Copyright (c) 2012 LessPainful.
//

#import "LPQueryLogRoute.h"
#import "asl.h"

@implementation LPQueryLogRoute
- (BOOL) supportsMethod:(NSString *) method atPath:(NSString *) path {
  return [method isEqualToString:@"GET"];
}


- (NSDictionary *) JSONResponseForMethod:(NSString *) method URI:(NSString *) path data:(NSDictionary *) data {

  int count = 0;

  //Build a query message containing all our criteria.
  aslmsg query = asl_new(ASL_TYPE_QUERY);

  for (NSString *key in [data keyEnumerator]) {
    int op = ASL_QUERY_OP_EQUAL;
    NSString *kData = [data valueForKey:key];

    if ([key isEqualToString:@"count"]) {
      count = [kData intValue];
      continue;
    }

    //If the key string contains one or more dots, process those modifiers.
    //Put the operation first, the modifiers following.
    if ([key rangeOfString:@"."].location != NSNotFound) {
      NSArray *keyParts = [key componentsSeparatedByString:@"."];
      key = [keyParts objectAtIndex:0];
      for (int i = 1; i < [keyParts count]; i++) {
        NSString *modifier = [[keyParts objectAtIndex:i] lowercaseString];
        if ([modifier isEqualToString:@"equal"]) {
          op = ASL_QUERY_OP_EQUAL;
        } else if ([modifier isEqualToString:@"greater"]) {
          op = ASL_QUERY_OP_GREATER;
        } else if ([modifier isEqualToString:@"greater_equal"]) {
          op = ASL_QUERY_OP_GREATER_EQUAL;
        } else if ([modifier isEqualToString:@"less"]) {
          op = ASL_QUERY_OP_LESS;
        } else if ([modifier isEqualToString:@"less_equal"]) {
          op = ASL_QUERY_OP_LESS_EQUAL;
        } else if ([modifier isEqualToString:@"not_equal"]) {
          op = ASL_QUERY_OP_NOT_EQUAL;
        } else if ([modifier isEqualToString:@"regex"]) {
          op = ASL_QUERY_OP_REGEX;
        } else if ([modifier isEqualToString:@"true"]) {
          op = ASL_QUERY_OP_TRUE;
        } else if ([modifier isEqualToString:@"casefold"]) {
          op |= ASL_QUERY_OP_CASEFOLD;
        } else if ([modifier isEqualToString:@"prefix"]) {
          op |= ASL_QUERY_OP_PREFIX;
        } else if ([modifier isEqualToString:@"suffix"]) {
          op |= ASL_QUERY_OP_SUFFIX;
        } else if ([modifier isEqualToString:@"substring"]) {
          op |= ASL_QUERY_OP_SUBSTRING;
        } else if ([modifier isEqualToString:@"numeric"]) {
          op |= ASL_QUERY_OP_NUMERIC;
        }
        //ignore unknown values
      }
    }

    //If we get here, assume the key is a ASL field to be set.
    //Note this means the user must pass in correct key strings such as "Facility" or "Sender".
    asl_set_query(query, [key UTF8String], [kData UTF8String], op);
  }

  //Begin the search.
  aslresponse response = asl_search(NULL, query);

  asl_free(query);

  // todo possible memory leak in LPQueryLogRoute
  NSMutableArray *messages = [[NSMutableArray alloc] init];
  aslmsg msg;
  while ((msg = aslresponse_next(response)) && count-- > 0) {
    //Load all the key/value pairs from the message into a dictionary.
    const char *k;
    NSMutableDictionary *msgDict = [[NSMutableDictionary alloc] init];
    for (unsigned i = 0U; (k = asl_key(msg, i)); ++i) {
      const char *v = asl_get(msg, k);
      [msgDict setObject:[NSString stringWithUTF8String:v]
                  forKey:[NSString stringWithUTF8String:k]];
    }
    [messages addObject:msgDict];
  }
  // todo possible memory leak in LPQueryLogRoute
  aslresponse_free(response);  //Also frees the messages used in the above loop.

  NSArray *results = [NSArray arrayWithArray:messages];

  return [NSDictionary dictionaryWithObjectsAndKeys:results, @"results",
                                                    @"SUCCESS", @"outcome",
                                                    nil];
}

@end
