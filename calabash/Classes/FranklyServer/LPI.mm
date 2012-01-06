//
//  LPI.mm
//  MobileBank
//
//  Created by Karl Krukow on 18/08/11.
//  Copyright (c) 2011 Trifork. All rights reserved.
//

#include <iostream>
#import "LessPainfulServer.h"
int ___lesspainfulserverinit();

int ___lesspainfulserver = ___lesspainfulserverinit();

int ___lesspainfulserverinit() {
    NSAutoreleasePool *ap = [[NSAutoreleasePool alloc] init];
    [LessPainfulServer start];
    [ap release];
    return 42;
}
