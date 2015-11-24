//
//  PhxSocket.h
//  Pods
//
//  Created by Justin Schneck on 5/1/15.
//
//

#import <Foundation/Foundation.h>
#import "PhxTypes.h"

@protocol PhxSocketDelegate <NSObject>

- (void)phxSocketDidOpen;
- (void)phxSocketDidClose:(id)event;
- (void)phxSocketDidReceiveError:(id)error;

@end

@class PhxChannel;

@interface PhxSocket : NSObject

@property (nonatomic, weak) id<PhxSocketDelegate> delegate;
@property (nonatomic, readwrite) BOOL reconnectOnError;

- (id)initWithURL:(NSURL*)url;
- (id)initWithURL:(NSURL*)url heartbeatInterval:(int)interval;

- (void)connect;
- (void)connectWithParams:(NSDictionary*)params;
- (void)disconnect;
- (void)reconnect;

- (void)onOpen:(OnOpen)callback;
- (void)onClose:(OnClose)callback;
- (void)onError:(OnError)callback;

- (void)onMessage:(OnMessage)callback;

- (BOOL)isConnected;

- (NSString*)makeRef;

- (SocketState)socketState;

- (void)push:(NSDictionary*)data;

@end
