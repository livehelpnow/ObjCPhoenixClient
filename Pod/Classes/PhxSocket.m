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
#import "NSDictionary+QueryString.h"

static NSTimeInterval reconnectInterval = 5;

@interface PhxSocket () <SRWebSocketDelegate>

@property (nonatomic, retain) SRWebSocket *socket;
@property (nonatomic, retain) NSURL *URL;
@property (nonatomic, assign) int heartbeatInterval;

@property (nonatomic, retain) NSMutableArray *channels;
@property (nonatomic, strong) NSOperationQueue *queue;

@property (nonatomic, retain) NSTimer *sendBufferTimer;
@property (nonatomic, retain) NSTimer *reconnectTimer;
@property (nonatomic, retain) NSTimer *heartbeatTimer;

@property (nonatomic, retain) NSMutableArray *openCallbacks;
@property (nonatomic, retain) NSMutableArray *closeCallbacks;
@property (nonatomic, retain) NSMutableArray *errorCallbacks;
@property (nonatomic, retain) NSMutableArray *messageCallbacks;

@property (nonatomic, retain) NSDictionary *params;

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
        self.params = nil;
        self.heartbeatInterval = interval;
        self.channels = [NSMutableArray new];
        self.openCallbacks = [NSMutableArray new];
        self.closeCallbacks = [NSMutableArray new];
        self.errorCallbacks = [NSMutableArray new];
        self.messageCallbacks = [NSMutableArray new];
        self.reconnectOnError = YES;

        self.queue = [[NSOperationQueue alloc] init];
        [self.queue setSuspended:YES];
        
        //[self reconnect];
    }
    return self;
}

- (void)connect {
    [self connectWithParams:nil];
}

- (void)connectWithParams:(NSDictionary*)params {
    NSURL *url;
    self.params = params;
    if (self.params != nil) {
        
        url = [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@", [self.URL absoluteString], [self.params queryStringValue]]];
    } else {
        url = self.URL;
    }
    
    NSLog(@"URL: %@", url);
    self.socket = [[SRWebSocket alloc]initWithURL:url];
    self.socket.delegate = self;
    [self.socket open];
}

- (void)disconnect {
    [self discardHeartbeatTimer];
    [self discardReconnectTimer];
    [self disconnectSocket];
}

- (void)reconnect {
    [self disconnectSocket];
    [self connectWithParams:self.params];
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

- (void)push:(NSDictionary*)data {
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:0 error:&error];
    if (!error) {
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        [self.queue addOperationWithBlock:^{
            [self.socket send:jsonString];
        }];
    }
}

#pragma mark - Private Methods

- (void)disconnectSocket {
    if (self.socket) {
        self.socket.delegate = nil;
        [self.socket close];
        self.socket = nil;
    }
}

- (void)discardHeartbeatTimer
{
    if (self.heartbeatTimer) {
        [self.heartbeatTimer invalidate];
        self.heartbeatTimer = nil;
    }
}

- (void)discardReconnectTimer {
    if (self.reconnectTimer) {
        [self.reconnectTimer invalidate];
        self.reconnectTimer = nil;
    }
}

- (void)onConnOpen {
    NSLog(@"PhxSocket Opened");
    [self.queue setSuspended:NO];
    [self discardReconnectTimer];
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
    [self.queue setSuspended:YES];
    [self triggerChanError:event];
    
    if (self.reconnectOnError) {
        [self discardReconnectTimer];
        self.reconnectTimer = [NSTimer scheduledTimerWithTimeInterval:reconnectInterval target:self selector:@selector(reconnect) userInfo:nil repeats:YES];
    }
    [self discardHeartbeatTimer];
    
    for (OnClose callback in self.closeCallbacks) {
        callback(event);
    }
    
    if ([self.delegate respondsToSelector:@selector(phxSocketDidClose:)]) {
        [self.delegate phxSocketDidClose:event];
    }
}

- (void)onConnError:(id)error {
    NSLog(@"PhxSocket Failed with Error: %@", [error localizedDescription]);
    [self.queue setSuspended:YES];
    [self discardHeartbeatTimer];

    for (OnError callback in self.errorCallbacks) {
        callback(error);
    }
    
    if ([self.delegate respondsToSelector:@selector(phxSocketDidReceiveError:)]) {
        [self.delegate phxSocketDidReceiveError:error];
    }
    [self onConnClose:error];
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
        NSString *ref = [json valueForKey:@"ref"];
        NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(PhxChannel *channel, NSDictionary *bindings) {
            return [channel.topic isEqualToString:topic];
        }];
        NSArray *channels = [self.channels filteredArrayUsingPredicate:predicate];
        for (PhxChannel *channel in channels) {
            [channel triggerEvent:event message:payload ref:ref];
        }
        for (OnMessage callback in self.messageCallbacks) {
            callback(json);
        }
    }
}

- (void)triggerChanError:(id)error {
    for (PhxChannel *channel in self.channels) {
        [channel triggerEvent:@"phx_error" message:error ref:nil];
    }
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
