//
//  LPI.mm
//
//  Created by Karl Krukow on 18/08/11.
//  Copyright (c) 2011 LessPainful. All rights reserved.
//


#import "CalabashServer.h"

int ___calabashserverinit();

int ___lesspainfulserver = ___calabashserverinit();

int ___calabashserverinit() {
    @autoreleasepool {
        [CalabashServer start];
    }
    return 42;
}
