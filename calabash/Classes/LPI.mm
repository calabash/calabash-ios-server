
//
//  LPI.mm
//
//  Created by Karl Krukow on 18/08/11.
//  Copyright (c) 2011 LessPainful. All rights reserved.
//

#import "CalabashServer.h"
#import "LPGitVersionDefines.h"

#ifdef LP_SERVER_ID_VALUE
static const char* kLPServerIdentifierValue = LP_SERVER_ID_VALUE;
#else
static const char* kLPServerIdentifierValue = "LP_SERVER_ID_VALUE is an unknown symbol";
#endif

int ___calabashserverinit();

int ___lesspainfulserver = ___calabashserverinit();

// Starting in Xcode 9, printf has become essentially useless - the output
// appears no where.
//
// Attempts to use NSLog and CocoaLumberjack here have caused compile problems.

int ___calabashserverinit() {

  char *skipToken = getenv("XTC_SKIP_LPSERVER_TOKEN");
  char *identifier = strdup(kLPServerIdentifierValue);

  if (skipToken == NULL) {
    printf("CalabashServer | XTC_SKIP_LPSERVER_TOKEN is not in the app environment\n");
    printf("CalabashServer | Will start LPServer with identifier: %s\n", identifier);
    [CalabashServer start];
    return 42;
  }

  printf("CalabashServer | XTC_SKIP_LPSERVER_TOKEN is defined in the app environment\n");

  if (strcmp(skipToken, identifier) != 0) {
    printf("CalabashServer | but it is not the same as the embedded server identifier\n");
    printf("CalabashServer |        SKIP TOKEN = %s\n", skipToken);
    printf("CalabashServer | SERVER IDENTIFIER = %s\n", identifier);
    printf("CalabashServer | Will start LPServer with identifier: %s\n", identifier);
    [CalabashServer start];
    return 42;
  } else {
    printf("CalabashServer | and it is the same as the embedded server identifier\n");
    printf("CalabashServer |        SKIP TOKEN = %s\n", skipToken);
    printf("CalabashServer | SERVER IDENTIFIER = %s\n", identifier);
    printf("CalabashServer | Will NOT start LPServer with identifier: %s\n", identifier);
    return 42;
  }
}
