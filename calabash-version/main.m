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
    printf("%s\n", [kLPCALABASHVERSION cStringUsingEncoding:NSASCIIStringEncoding]);
  }
  return 0;
}
