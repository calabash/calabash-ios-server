#import <Foundation/Foundation.h>

/**
 When using repeating timers with target self it is important to invalidate
 the timer before deallocating self because the timer maintains a reference
 to the target until invalidate is called.  It is also often very useful to
 have, say the App Delegate, start and stop timers when the user moves from
 one state to another.

 Enter LPRepeatingTimerProtocol.  Implementers must define methods for
 starting/stopping and memory management.
 */
@protocol LPRepeatingTimerProtocol <NSObject>

@required
/**
 Implementer should stop timers with invalidate and release the timers.
 */
- (void)stopAndReleaseRepeatingTimers;

/**
 Implementer should start timers and retain them and should ensure that if a
 timer is already running, that is is invalidated and released.
 */
- (void)startAndRetainRepeatingTimers;

@end
