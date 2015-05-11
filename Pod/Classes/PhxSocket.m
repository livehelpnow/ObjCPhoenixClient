//
//  PhxSocket.m
//  Pods
//
//  Created by Justin Schneck on 5/1/15.
//
//

#import "PhxSocket.h"
#import "PhxSocket_Private.h"
#import <SocketRocket/SRWebSocket.h>
#import "PhxChannel.h"
#import "PhxChannel_Private.h"

static int reconnectInterval = 5;
static int bufferFlushInterval = 0.5;

@interface PhxSocket () <SRWebSocketDelegate>

@property (nonatomic, retain) SRWebSocket *socket;
@property (nonatomic, retain) NSURL *URL;
@property (nonatomic, assign) int heartbeatInterval;
@property (nonatomic) SocketState socketState;

@property (nonatomic, retain) NSMutableArray *channels;
@property (nonatomic, retain) NSMutableArray *sendBuffer;

@property (nonatomic, retain) NSTimer *sendBufferTimer;
@property (nonatomic, retain) NSTimer *reconnectTimer;
@property (nonatomic, retain) NSTimer *heartbeatTimer;

@property (nonatomic, retain) NSMutableArray *openCallbacks;
@property (nonatomic, retain) NSMutableArray *closeCallbacks;
@property (nonatomic, retain) NSMutableArray *errorCallbacks;
@property (nonatomic, retain) NSMutableArray *messageCallbacks;

@property (readwrite) int ref;

@end

@implementation PhxSocket

- (id)initWithURL:(NSURL*)url {
    return [self initWithURL:url heartbeatInterval:0];
}

- (id)initWithURL:(NSURL*)url heartbeatInterval:(int)interval {
    self = [super init];
    if (self) {
        self.URL = url;
        self.heartbeatInterval = interval;
        self.channels = [NSMutableArray new];
        self.sendBuffer = [NSMutableArray new];
        self.openCallbacks = [NSMutableArray new];
        self.closeCallbacks = [NSMutableArray new];
        self.errorCallbacks = [NSMutableArray new];
        self.messageCallbacks = [NSMutableArray new];
        
        [self resetBufferTimer];
        [self reconnect];
    }
    return self;
}

- (void)connect {
    self.socket = [[SRWebSocket alloc]initWithURL:self.URL];
    self.socket.delegate = self;
    [self.socket open];
}

- (void)disconnect {
    if (self.socket) {
        self.socket.delegate = nil;
        [self.socket close];
        self.socket = nil;
    }
}

- (void)reconnect {
    [self disconnect];
    [self connect];
}

- (BOOL)isConnected {
    return [self socketState] == SocketOpen;
}

- (SocketState)socketState {
    switch (self.socket.readyState) {
        case 0:
            return SocketConnecting;
            break;
        case 1:
            return SocketOpen;
            break;
        case 2:
            return SocketClosing;
            break;
        case 3:
            return SocketClosed;
            break;
        default:
            return SocketClosed;
            break;
    }
}

- (void)addChannel:(PhxChannel *)channel {
    [self.channels addObject:channel];
}

- (void)removeChannel:(PhxChannel*)channel {
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(PhxChannel *evalChannel, NSDictionary *bindings) {
        return evalChannel == channel;
    }];
    NSArray *channels = [self.channels filteredArrayUsingPredicate:predicate];
    for (PhxChannel *channel in channels) {
        [self.channels removeObject:channel];
    }
}

- (void)onOpen:(OnOpen)callback {
    [self.openCallbacks addObject:callback];
}

- (void)onClose:(OnClose)callback {
    [self.closeCallbacks addObject:callback];
}

- (void)onError:(OnError)callback {
    [self.errorCallbacks addObject:callback];
}

- (void)onMessage:(OnMessage)callback {
    [self.messageCallbacks addObject:callback];
}

#pragma mark - Private Methods

- (void)push:(NSDictionary*)data {
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:0 error:&error];
    if (!error) {
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        if ([self isConnected]) {
            [self.socket send:jsonString];
        } else {
            [self.sendBuffer addObject:jsonString];
        }
    }
}

- (void)onConnOpen {
    NSLog(@"PhxSocket Opened");
    [self flushSendBuffer];
    if (self.reconnectTimer) {
        [self.reconnectTimer invalidate];
        self.reconnectTimer = nil;
    }
    if (self.heartbeatInterval > 0) {
        [self startHeartbeatTimerWithInterval:self.heartbeatInterval];
    }
    
    for (OnOpen callback in self.openCallbacks) {
        callback();
    }
    
    if ([self.delegate respondsToSelector:@selector(phxSocketDidOpen)]) {
        [self.delegate phxSocketDidOpen];
    }
}

- (void)onConnClose:(id)event {
    NSLog(@"PhxSocket Closed");
    if (self.reconnectOnError) {
        if (self.reconnectTimer) {
            [self.reconnectTimer invalidate];
            self.reconnectTimer = nil;
        }
        self.reconnectTimer = [NSTimer scheduledTimerWithTimeInterval:reconnectInterval target:self selector:@selector(reconnect) userInfo:nil repeats:YES];
    }
    if (self.heartbeatTimer) {
        [self.heartbeatTimer invalidate];
        self.heartbeatTimer = nil;
    }
    
    for (OnClose callback in self.closeCallbacks) {
        callback(event);
    }
    
    if ([self.delegate respondsToSelector:@selector(phxSocketDidClose:)]) {
        [self.delegate phxSocketDidClose:event];
    }
}

- (void)onConnError:(id)error {
    NSLog(@"PhxSocket Failed with Error: %@", [error localizedDescription]);
    for (OnError callback in self.errorCallbacks) {
        callback(error);
    }
    
    if ([self.delegate respondsToSelector:@selector(phxSocketDidReceiveError:)]) {
        [self.delegate phxSocketDidReceiveError:error];
    }

}

- (void)onConnMessage:(NSString*)rawMessage {
    NSLog(@"PhxSocket Message:%@",(NSString*)rawMessage);
    NSData *data = [rawMessage dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (!error) {
        NSString *topic = [json valueForKey:@"topic"];
        NSString *event = [json valueForKey:@"event"];
        NSString *payload = [json valueForKey:@"payload"];
        NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(PhxChannel *channel, NSDictionary *bindings) {
            return [channel.topic isEqualToString:topic];
        }];
        NSArray *channels = [self.channels filteredArrayUsingPredicate:predicate];
        for (PhxChannel *channel in channels) {
            [channel triggerEvent:event message:payload];
        }
        for (OnMessage callback in self.messageCallbacks) {
            callback(topic, event, payload);
        }
    }
}

- (void)triggerChanError:(id)error {
    for (PhxChannel *channel in self.channels) {
        [channel triggerEvent:@"phx_error" message:error];
    }
}

- (void)flushSendBuffer {
    if ([self isConnected] && [self.sendBuffer count] > 0) {
        // Enum the buffer and send data
        for (NSString* jsonString in self.sendBuffer) {
            [self.socket send:jsonString];
        }
        // Empty the Array
        [self.sendBuffer removeAllObjects];
        [self resetBufferTimer];
    }
}

- (void)resetBufferTimer {
    if (self.sendBufferTimer) {
        [self.sendBufferTimer invalidate];
        self.sendBufferTimer = nil;
    }
    self.sendBufferTimer = [NSTimer scheduledTimerWithTimeInterval:bufferFlushInterval target:self selector:@selector(flushSendBuffer) userInfo:nil repeats:true];
}

- (void)startHeartbeatTimerWithInterval:(int)interval {
    self.heartbeatTimer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(sendHeartbeat) userInfo:nil repeats:YES];
}

- (void)sendHeartbeat {
    [self push:@{@"topic":@"phoenix", @"event":@"heartbeat", @"payload": @{}, @"ref":[self makeRef]}];
}

- (NSString*)makeRef {
    // TODO: Catch integer overflow
    int newRef = self.ref + 1;
    return [NSString stringWithFormat:@"%i", newRef];
}


#pragma mark - SRWebSocket Delegate

- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
    [self onConnOpen];
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
    [self onConnMessage:message];
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    [self onConnError:error];
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    [self onConnClose:reason];
}

@end
