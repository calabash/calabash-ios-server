//
//  LPScreencastRoute.h
//  Created by Karl Krukow on 27/08/11.
//  Copyright (c) 2011 2011 LessPainful. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LPHTTPConnection.h"
#import "LPRoute.h"
#import "ScreenCaptureView.h"

@interface LPLPScreencastRoute : NSObject<LPRoute> {
    NSDictionary *_params;
    LPHTTPConnection *_conn;
    ScreenCaptureView *_screenCapture;
    
}
@end
