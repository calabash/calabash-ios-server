//
//  RecordRoute.h
//  Created by Karl Krukow on 15/08/11.
//  Copyright 2011 LessPainful. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LPRoute.h"

@interface LPRecordRoute : NSObject <LPRoute> {
  NSDictionary *_params;
  LPHTTPConnection *_conn;
}
@end
