#import "LPHTTPServer.h"
#import "LPGCDAsyncSocket.h"
#import "LPHTTPConnection.h"
#import "LPWebSocket.h"
#import "LPHTTPLogging.h"

#if !__has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

static LPLogLevel __unused lpHTTPLogLevel = LPLogLevelWarning;


@interface LPHTTPServer (PrivateAPI)

- (void)unpublishBonjour;

- (void)publishBonjour;

+ (void)startBonjourThreadIfNeeded;

+ (void)performBonjourBlock:(dispatch_block_t)block;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation LPHTTPServer

/**
 * Standard Constructor.
 * Instantiates an HTTP server, but does not start it.
 **/
- (id)init {
  if ((self = [super init])) {
    LPHTTPLogTrace();

    // Setup underlying dispatch queues
    serverQueue = dispatch_queue_create("LPHTTPServer", NULL);
    connectionQueue = dispatch_queue_create("LPHTTPConnection", NULL);

    IsOnServerQueueKey = &IsOnServerQueueKey;
    IsOnConnectionQueueKey = &IsOnConnectionQueueKey;

    void *nonNullUnusedPointer = (__bridge void *) self; // Whatever, just not null

    dispatch_queue_set_specific(serverQueue, IsOnServerQueueKey, nonNullUnusedPointer, NULL);
    dispatch_queue_set_specific(connectionQueue, IsOnConnectionQueueKey, nonNullUnusedPointer, NULL);

    // Initialize underlying GCD based tcp socket
    asyncSocket = [[LPGCDAsyncSocket alloc] initWithDelegate:self delegateQueue:serverQueue];

    // Use default connection class of LPHTTPConnection
    connectionClass = [LPHTTPConnection self];

    // By default bind on all available interfaces, en1, wifi etc
    interface = nil;

    // Use a default port of 0
    // This will allow the kernel to automatically pick an open port for us
    port = 0;

    // Configure default values for bonjour service

    // Bonjour domain. Use the local domain by default
    domain = @"local.";

    // If using an empty string ("") for the service name when registering,
    // the system will automatically use the "Computer Name".
    // Passing in an empty string will also handle name conflicts
    // by automatically appending a digit to the end of the name.
    name = @"";

    // Initialize arrays to hold all the HTTP and webSocket connections
    connections = [[NSMutableArray alloc] init];
    webSockets = [[NSMutableArray alloc] init];

    connectionsLock = [[NSLock alloc] init];
    webSocketsLock = [[NSLock alloc] init];

    // Register for notifications of closed connections
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(connectionDidDie:)
                                                 name:LPHTTPConnectionDidDieNotification
                                               object:nil];

    // Register for notifications of closed websocket connections
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(webSocketDidDie:)
                                                 name:LPWebSocketDidDieNotification
                                               object:nil];

    isRunning = NO;
  }
  return self;
}

/**
 * Standard Deconstructor.
 * Stops the server, and clients, and releases any resources connected with this instance.
 **/
- (void)dealloc {
  LPHTTPLogTrace();

  // Remove notification observer
  [[NSNotificationCenter defaultCenter] removeObserver:self];

  // Stop the server if it's running
  [self stop];

  // Release all instance variables

#if !OS_OBJECT_USE_OBJC
  dispatch_release(serverQueue);
  dispatch_release(connectionQueue);
#endif

  [asyncSocket setDelegate:nil delegateQueue:NULL];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Server Configuration
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * The document root is filesystem root for the webserver.
 * Thus requests for /index.html will be referencing the index.html file within the document root directory.
 * All file requests are relative to this document root.
 **/
- (NSString *)documentRoot {
  __block NSString *result;

  dispatch_sync(serverQueue, ^{
    result = self->documentRoot;
  });

  return result;
}

- (void)setDocumentRoot:(NSString *)value {
  LPHTTPLogTrace();

  // Document root used to be of type NSURL.
  // Add type checking for early warning to developers upgrading from older versions.

  if (value && ![value isKindOfClass:[NSString class]]) {
    LPHTTPLogWarn(@"%@: %@ - Expecting NSString parameter, received %@ parameter",
                  LP_THIS_FILE, LP_THIS_METHOD, NSStringFromClass([value class]));
    return;
  }

  NSString *valueCopy = [value copy];

  dispatch_async(serverQueue, ^{
    self->documentRoot = valueCopy;
  });

}

/**
 * The connection class is the class that will be used to handle connections.
 * That is, when a new connection is created, an instance of this class will be intialized.
 * The default connection class is LPHTTPConnection.
 * If you use a different connection class, it is assumed that the class extends LPHTTPConnection
 **/
- (Class)connectionClass {
  __block Class result;

  dispatch_sync(serverQueue, ^{
    result = self->connectionClass;
  });

  return result;
}

- (void)setConnectionClass:(Class)value {
  LPHTTPLogTrace();

  dispatch_async(serverQueue, ^{
    self->connectionClass = value;
  });
}

/**
 * What interface to bind the listening socket to.
 **/
- (NSString *)interface {
  __block NSString *result;

  dispatch_sync(serverQueue, ^{
    result = self->interface;
  });

  return result;
}

- (void)setInterface:(NSString *)value {
  NSString *valueCopy = [value copy];

  dispatch_async(serverQueue, ^{
    self->interface = valueCopy;
  });

}

/**
 * The port to listen for connections on.
 * By default this port is initially set to zero, which allows the kernel to pick an available port for us.
 * After the HTTP server has started, the port being used may be obtained by this method.
 **/
- (UInt16)port {
  __block UInt16 result;

  dispatch_sync(serverQueue, ^{
    result = self->port;
  });

  return result;
}

- (UInt16)listeningPort {
  __block UInt16 result;

  dispatch_sync(serverQueue, ^{
    if (self->isRunning)
      result = [self->asyncSocket localPort];
    else
      result = 0;
  });

  return result;
}

- (void)setPort:(UInt16)value {
  LPHTTPLogTrace();

  dispatch_async(serverQueue, ^{
    self->port = value;
  });
}

/**
 * Domain on which to broadcast this service via Bonjour.
 * The default domain is @"local".
 **/
- (NSString *)domain {
  __block NSString *result;

  dispatch_sync(serverQueue, ^{
    result = self->domain;
  });

  return result;
}

- (void)setDomain:(NSString *)value {
  LPHTTPLogTrace();

  NSString *valueCopy = [value copy];

  dispatch_async(serverQueue, ^{
    self->domain = valueCopy;
  });

}

/**
 * The name to use for this service via Bonjour.
 * The default name is an empty string,
 * which should result in the published name being the host name of the computer.
 **/
- (NSString *)name {
  __block NSString *result;

  dispatch_sync(serverQueue, ^{
    result = self->name;
  });

  return result;
}

- (NSString *)publishedName {
  __block NSString *result;

  dispatch_sync(serverQueue, ^{

    if (self->netService == nil) {
      result = nil;
    }
    else {

      dispatch_block_t bonjourBlock = ^{
        result = [[self->netService name] copy];
      };

      [[self class] performBonjourBlock:bonjourBlock];
    }
  });

  return result;
}

- (void)setName:(NSString *)value {
  NSString *valueCopy = [value copy];

  dispatch_async(serverQueue, ^{
    self->name = valueCopy;
  });

}

/**
 * The type of service to publish via Bonjour.
 * No type is set by default, and one must be set in order for the service to be published.
 **/
- (NSString *)type {
  __block NSString *result;

  dispatch_sync(serverQueue, ^{
    result = self->type;
  });

  return result;
}

- (void)setType:(NSString *)value {
  NSString *valueCopy = [value copy];

  dispatch_async(serverQueue, ^{
    self->type = valueCopy;
  });

}

/**
 * The extra data to use for this service via Bonjour.
 **/
- (NSDictionary *)TXTRecordDictionary {
  __block NSDictionary *result;

  dispatch_sync(serverQueue, ^{
    result = self->txtRecordDictionary;
  });

  return result;
}

- (void)setTXTRecordDictionary:(NSDictionary *)value {
  LPHTTPLogTrace();

  NSDictionary *valueCopy = [value copy];

  dispatch_async(serverQueue, ^{

    self->txtRecordDictionary = valueCopy;

    // Update the txtRecord of the netService if it has already been published
    if (self->netService) {
      NSNetService *theNetService = self->netService;
      NSData *txtRecordData = nil;
      if (self->txtRecordDictionary)
        txtRecordData = [NSNetService dataFromTXTRecordDictionary:self->txtRecordDictionary];

      dispatch_block_t bonjourBlock = ^{
        [theNetService setTXTRecordData:txtRecordData];
      };

      [[self class] performBonjourBlock:bonjourBlock];
    }
  });

}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Server Control
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL)start:(NSError *__autoreleasing*)errPtr {
  LPHTTPLogTrace();

  __block BOOL success = YES;
  __block NSError *err = nil;

  dispatch_sync(serverQueue, ^{
    @autoreleasepool {

      success = [self->asyncSocket acceptOnInterface:self->interface port:self->port error:&err];
      if (success) {
        LPHTTPLogInfo(@"%@: Started HTTP server on port %hu", LP_THIS_FILE, [self->asyncSocket localPort]);

        self->isRunning = YES;
        [self publishBonjour];
      }
      else {
        LPHTTPLogError(@"%@: Failed to start HTTP Server: %@", LP_THIS_FILE, err);
      }
    }
  });

  if (errPtr)
    *errPtr = err;

  return success;
}

- (void)stop {
  [self stop:NO];
}

- (void)stop:(BOOL)keepExistingConnections {
  LPHTTPLogTrace();

  dispatch_sync(serverQueue, ^{
    @autoreleasepool {

      // First stop publishing the service via bonjour
      [self unpublishBonjour];

      // Stop listening / accepting incoming connections
      [self->asyncSocket disconnect];
      self->isRunning = NO;

      if (!keepExistingConnections) {
        // Stop all HTTP connections the server owns
        [self->connectionsLock lock];
        for (LPHTTPConnection *connection in self->connections) {
          [connection stop];
        }
        [self->connections removeAllObjects];
        [self->connectionsLock unlock];

        // Stop all LPWebSocket connections the server owns
        [self->webSocketsLock lock];
        for (LPWebSocket *webSocket in self->webSockets) {
          [webSocket stop];
        }
        [self->webSockets removeAllObjects];
        [self->webSocketsLock unlock];
      }
    }
  });
}

- (BOOL)isRunning {
  __block BOOL result;

  dispatch_sync(serverQueue, ^{
    result = self->isRunning;
  });

  return result;
}

- (void)addWebSocket:(LPWebSocket *)ws {
  [webSocketsLock lock];

  LPHTTPLogTrace();
  [webSockets addObject:ws];

  [webSocketsLock unlock];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Server Status
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Returns the number of http client connections that are currently connected to the server.
 **/
- (NSUInteger)numberOfHTTPConnections {
  NSUInteger result = 0;

  [connectionsLock lock];
  result = [connections count];
  [connectionsLock unlock];

  return result;
}

/**
 * Returns the number of websocket client connections that are currently connected to the server.
 **/
- (NSUInteger)numberOfWebSocketConnections {
  NSUInteger result = 0;

  [webSocketsLock lock];
  result = [webSockets count];
  [webSocketsLock unlock];

  return result;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Incoming Connections
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (LPHTTPConfig *)config {
  // Override me if you want to provide a custom config to the new connection.
  //
  // Generally this involves overriding the LPHTTPConfig class to include any custom settings,
  // and then having this method return an instance of 'MyHTTPConfig'.

  // Note: Think you can make the server faster by putting each connection on its own queue?
  // Then benchmark it before and after and discover for yourself the shocking truth!
  //
  // Try the apache benchmark tool (already installed on your Mac):
  // $  ab -n 1000 -c 1 http://localhost:<port>/some_path.html

  return [[LPHTTPConfig alloc] initWithServer:self documentRoot:documentRoot queue:connectionQueue];
}

- (void)socket:(LPGCDAsyncSocket *)sock didAcceptNewSocket:(LPGCDAsyncSocket *)newSocket {
  LPHTTPConnection *newConnection = (LPHTTPConnection *) [[connectionClass alloc] initWithAsyncSocket:newSocket
                                                                                        configuration:[self config]];
  [connectionsLock lock];
  [connections addObject:newConnection];
  [connectionsLock unlock];

  [newConnection start];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Bonjour
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)publishBonjour {
  LPHTTPLogTrace();

  NSAssert(dispatch_get_specific(IsOnServerQueueKey) != NULL, @"Must be on serverQueue");

  if (type) {
    netService = [[NSNetService alloc] initWithDomain:domain type:type name:name port:[asyncSocket localPort]];
    [netService setDelegate:self];

    NSNetService *theNetService = netService;
    NSData *txtRecordData = nil;
    if (txtRecordDictionary)
      txtRecordData = [NSNetService dataFromTXTRecordDictionary:txtRecordDictionary];

    dispatch_block_t bonjourBlock = ^{

      [theNetService removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
      [theNetService scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
      [theNetService publish];

      // Do not set the txtRecordDictionary prior to publishing!!!
      // This will cause the OS to crash!!!
      if (txtRecordData) {
        [theNetService setTXTRecordData:txtRecordData];
      }
    };

    [[self class] startBonjourThreadIfNeeded];
    [[self class] performBonjourBlock:bonjourBlock];
  }
}

- (void)unpublishBonjour {
  LPHTTPLogTrace();

  NSAssert(dispatch_get_specific(IsOnServerQueueKey) != NULL, @"Must be on serverQueue");

  if (netService) {
    NSNetService *theNetService = netService;

    dispatch_block_t bonjourBlock = ^{

      [theNetService stop];
    };

    [[self class] performBonjourBlock:bonjourBlock];

    netService = nil;
  }
}

/**
 * Republishes the service via bonjour if the server is running.
 * If the service was not previously published, this method will publish it (if the server is running).
 **/
- (void)republishBonjour {
  LPHTTPLogTrace();

  dispatch_async(serverQueue, ^{

    [self unpublishBonjour];
    [self publishBonjour];
  });
}

/**
 * Called when our bonjour service has been successfully published.
 * This method does nothing but output a log message telling us about the published service.
 **/
- (void)netServiceDidPublish:(NSNetService *)ns {
  // Override me to do something here...
  //
  // Note: This method is invoked on our bonjour thread.

  LPHTTPLogInfo(@"Bonjour Service Published: domain(%@) type(%@) name(%@)", [ns domain], [ns type], [ns name]);
}

/**
 * Called if our bonjour service failed to publish itself.
 * This method does nothing but output a log message telling us about the published service.
 **/
- (void)netService:(NSNetService *)ns didNotPublish:(NSDictionary *)errorDict {
  // Override me to do something here...
  //
  // Note: This method in invoked on our bonjour thread.

  LPHTTPLogWarn(@"Failed to Publish Service: domain(%@) type(%@) name(%@) - %@",
                [ns domain], [ns type], [ns name], errorDict);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Notifications
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * This method is automatically called when a notification of type LPHTTPConnectionDidDieNotification is posted.
 * It allows us to remove the connection from our array.
 **/
- (void)connectionDidDie:(NSNotification *)notification {
  // Note: This method is called on the connection queue that posted the notification

  [connectionsLock lock];

  LPHTTPLogTrace();
  [connections removeObject:[notification object]];

  [connectionsLock unlock];
}

/**
 * This method is automatically called when a notification of type LPWebSocketDidDieNotification is posted.
 * It allows us to remove the websocket from our array.
 **/
- (void)webSocketDidDie:(NSNotification *)notification {
  // Note: This method is called on the connection queue that posted the notification

  [webSocketsLock lock];

  LPHTTPLogTrace();
  [webSockets removeObject:[notification object]];

  [webSocketsLock unlock];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Bonjour Thread
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * NSNetService is runloop based, so it requires a thread with a runloop.
 * This gives us two options:
 *
 * - Use the main thread
 * - Setup our own dedicated thread
 *
 * Since we have various blocks of code that need to synchronously access the netservice objects,
 * using the main thread becomes troublesome and a potential for deadlock.
 **/

static NSThread *bonjourThread;

+ (void)startBonjourThreadIfNeeded {
  LPHTTPLogTrace();

  static dispatch_once_t predicate;
  dispatch_once(&predicate, ^{

    LPHTTPLogVerbose(@"%@: Starting bonjour thread...", LP_THIS_FILE);

    bonjourThread = [[NSThread alloc] initWithTarget:self
                                            selector:@selector(bonjourThread)
                                              object:nil];
    [bonjourThread start];
  });
}

+ (void)bonjourThread {
  @autoreleasepool {

    LPHTTPLogVerbose(@"%@: BonjourThread: Started", LP_THIS_FILE);

    // We can't run the run loop unless it has an associated input source or a timer.
    // So we'll just create a timer that will never fire - unless the server runs for 10,000 years.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    [NSTimer scheduledTimerWithTimeInterval:[[NSDate distantFuture] timeIntervalSinceNow]
                                     target:self
                                   selector:@selector(donothingatall:)
                                   userInfo:nil
                                    repeats:YES];
#pragma clang diagnostic pop

    [[NSRunLoop currentRunLoop] run];

    LPHTTPLogVerbose(@"%@: BonjourThread: Aborted", LP_THIS_FILE);

  }
}

+ (void)executeBonjourBlock:(dispatch_block_t)block {
  LPHTTPLogTrace();

  NSAssert([NSThread currentThread] == bonjourThread, @"Executed on incorrect thread");

  block();
}

+ (void)performBonjourBlock:(dispatch_block_t)block {
  LPHTTPLogTrace();

  [self performSelector:@selector(executeBonjourBlock:)
               onThread:bonjourThread
             withObject:block
          waitUntilDone:YES];
}

@end
