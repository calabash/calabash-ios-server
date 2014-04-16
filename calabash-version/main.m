//
//  main.m
//  version
//
//  Created by Joshua Moody on 27.3.14.
//  Copyright (c) 2014 Xamarin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LPVersionRoute.h"

int main(int argc, const char * argv[]) {

  @autoreleasepool {
    NSString *calabashVersion = [kLPCALABASHVERSION componentsSeparatedByString:@" "].lastObject;
    printf("%s\n", [calabashVersion cStringUsingEncoding:NSASCIIStringEncoding]);
  }
  return 0;
}
