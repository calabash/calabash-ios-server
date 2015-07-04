#import <Foundation/Foundation.h>

@class LPHTTPMessage;
@class LPGCDAsyncSocket;


#define LPWebSocketDidDieNotification  @"LPWebSocketDidDie"

@interface LPWebSocket : NSObject {
  dispatch_queue_t websocketQueue;

  LPHTTPMessage *request;
  LPGCDAsyncSocket *asyncSocket;

  NSData *term;

  BOOL isStarted;
  BOOL isOpen;
  BOOL isVersion76;

  id __unsafe_unretained delegate;
}

+ (BOOL)isWebSocketRequest:(LPHTTPMessage *)request;

- (id)initWithRequest:(LPHTTPMessage *)request socket:(LPGCDAsyncSocket *)socket;

/**
* Delegate option.
*
* In most cases it will be easier to subclass LPWebSocket,
* but some circumstances may lead one to prefer standard delegate callbacks instead.
**/
@property(/* atomic */ unsafe_unretained) id delegate;

/**
* The LPWebSocket class is thread-safe, generally via it's GCD queue.
* All public API methods are thread-safe,
* and the subclass API methods are thread-safe as they are all invoked on the same GCD queue.
**/
@property(nonatomic, readonly) dispatch_queue_t websocketQueue;

/**
* Public API
*
* These methods are automatically called by the HTTPServer.
* You may invoke the stop method yourself to close the LPWebSocket manually.
**/
- (void)start;

- (void)stop;

/**
* Public API
*
* Sends a message over the LPWebSocket.
* This method is thread-safe.
**/
- (void)sendMessage:(NSString *)msg;

/**
* Public API
*
* Sends a message over the LPWebSocket.
* This method is thread-safe.
**/
- (void)sendData:(NSData *)msg;

/**
* Subclass API
*
* These methods are designed to be overriden by subclasses.
**/
- (void)didOpen;

- (void)didReceiveMessage:(NSString *)msg;

- (void)didClose;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
* There are two ways to create your own custom LPWebSocket:
*
* - Subclass it and override the methods you're interested in.
* - Use traditional delegate paradigm along with your own custom class.
*
* They both exist to allow for maximum flexibility.
* In most cases it will be easier to subclass LPWebSocket.
* However some circumstances may lead one to prefer standard delegate callbacks instead.
* One such example, you're already subclassing another class, so subclassing LPWebSocket isn't an option.
**/

@protocol LPWebSocketDelegate
@optional

- (void)webSocketDidOpen:(LPWebSocket *)ws;

- (void)webSocket:(LPWebSocket *)ws didReceiveMessage:(NSString *)msg;

- (void)webSocketDidClose:(LPWebSocket *)ws;

@end
