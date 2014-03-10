//
//  RecordRoute.m
//  Created by Karl Krukow on 15/08/11.
//  Copyright 2011 LessPainful. All rights reserved.
//

#import "LPRecordRoute.h"
#import "LPHTTPDataResponse.h"
#import "LPRecorder.h"
#import "LPNoContentResponse.h"

@interface LPRecordRoute ()
- (void) startRecording;

- (NSData *) stopRecording;
@end

@implementation LPRecordRoute

- (void) setParameters:(NSDictionary *) parameters {
  _params = [parameters retain];
}


- (void) setConnection:(LPHTTPConnection *) connection {
  _conn = connection;
}


- (void) dealloc {
  [_params release];
  _params = nil;
  _conn = nil;
  [super dealloc];
}


- (BOOL) supportsMethod:(NSString *) method atPath:(NSString *) path {
  return [method isEqualToString:@"POST"];
}


- (NSObject <LPHTTPResponse> *) httpResponseForMethod:(NSString *) method URI:(NSString *) path {
  NSString *action = [_params objectForKey:@"action"];
  if ([action isEqualToString:@"start"]) {
    [self startRecording];
    return [[[LPNoContentResponse alloc] init] autorelease];
  } else if ([action isEqualToString:@"stop"]) {
    NSData *data = [self stopRecording];
    return [[[LPHTTPDataResponse alloc] initWithData:data] autorelease];
  } else {
    return nil;
  }
}


- (void) startRecording {
  [[LPRecorder sharedRecorder] record];
}


- (NSData *) stopRecording {
  [[LPRecorder sharedRecorder] stop];

  NSString *error = nil;

  NSData *plistData = [NSPropertyListSerialization dataFromPropertyList:[[LPRecorder sharedRecorder]
          events]
                                                                 format:NSPropertyListXMLFormat_v1_0
                                                       errorDescription:&error];
  if (error) {
    NSLog(@"error getting plist data: %@", error);
    return nil;
  } else {
    return plistData;
  }
//
//    NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
//
//    NSString* appID = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
//    static NSDateFormatter *fm = nil;
//    if (!fm) {
//        fm=[[NSDateFormatter alloc] init];
//        [fm setDateFormat:@"ddMM'-'HH':'mm':'SSSS"];
//    }
//    NSString* timestamp = [fm stringFromDate:[NSDate date]];
//    NSString* tempFile = [NSString stringWithFormat:@"record_%@_%@.plist",appID,timestamp,nil];
//
//    NSString *plistPath = [rootPath stringByAppendingPathComponent:tempFile];
//
//
//    [[Recorder sharedRecorder] saveToFile:plistPath];
//    return tempFile;
}

@end
