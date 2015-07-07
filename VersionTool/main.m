#import <Foundation/Foundation.h>
#import "LPVersionRoute.h"

int main(int argc, const char * argv[]) {

  @autoreleasepool {
    NSString *calabashVersion = [kLPCALABASHVERSION componentsSeparatedByString:@" "].lastObject;
    printf("%s\n", [calabashVersion cStringUsingEncoding:NSASCIIStringEncoding]);
  }
  return 0;
}
