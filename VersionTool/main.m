#import <Foundation/Foundation.h>
#import "LPVersionRoute.h"
#import "LPGitVersionDefines.h"

#ifdef LP_GIT_SHORT_REVISION
static NSString *const kLPGitShortRevision = LP_GIT_SHORT_REVISION;
#else
static NSString *const kLPGitShortRevision = @"Unknown";
#endif

#ifdef LP_GIT_BRANCH
static NSString *const kLPGitBranch = LP_GIT_BRANCH;
#else
static NSString *const kLPGitBranch = @"Unknown";
#endif

#ifdef LP_GIT_REMOTE_ORIGIN
static NSString *const kLPGitRemoteOrigin = LP_GIT_REMOTE_ORIGIN;
#else
static NSString *const kLPGitRemoteOrigin = @"Unknown";
#endif

int main(int argc, const char * argv[]) {

  @autoreleasepool {
    NSUserDefaults *standardDefaults = [NSUserDefaults standardUserDefaults];
    NSString *revision = [standardDefaults stringForKey:@"-revision"];

    if ([revision isEqualToString:@"ALL"]) {
      printf("%s %s %s\n",
             [kLPGitRemoteOrigin cStringUsingEncoding:NSASCIIStringEncoding],
             [kLPGitBranch cStringUsingEncoding:NSASCIIStringEncoding],
             [kLPGitShortRevision cStringUsingEncoding:NSASCIIStringEncoding]);

    } else {
      NSString *calabashVersion = [kLPCALABASHVERSION componentsSeparatedByString:@" "].lastObject;
      printf("%s\n", [calabashVersion cStringUsingEncoding:NSASCIIStringEncoding]);

    }
  }
  return 0;
}
