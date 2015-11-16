//
//  PhxChannel.m
//  Pods
//
//  Created by Justin Schneck on 5/1/15.
//
//

#import "PhxChannel.h"
#import "PhxPush.h"
#import "PhxPush_Private.h"
#import "PhxSocket.h"
#import "PhxSocket_Private.h"

@interface PhxChannel ()

@property (nonatomic, readwrite) ChannelState state;

@property (nonatomic, retain) NSMutableArray *bindings;

@property (readwrite) BOOL joinedOnce;
@property (nonatomic, retain) PhxPush *joinPush;

@end

@implementation PhxChannel

- (id)initWithSocket:(PhxSocket *)socket topic:(NSString *)topic params:(NSDictionary *)params {
    self = [super init];
    if (self) {
        self.state = ChannelClosed;
        self.topic = topic;
        if (params != nil) {
            self.params = params;
        } else {
            self.params = @{};
        }
        self.socket = socket;
        self.bindings = [NSMutableArray new];
        [self.socket addChannel:self];
        
        self.joinedOnce = NO;
        self.joinPush = [[PhxPush alloc] initWithChannel:self event:@"phx_join" payload:self.params];
        
        [self.joinPush onReceive:@"ok" callback:^(id message) {
            self.state = ChannelJoined;
        }];
        
        [self.socket onOpen:^{
            [self rejoin];
        }];
        
        [self onClose:^(id event) {
            self.state = ChannelClosed;
            [self.socket removeChannel:self];
        }];
        
        [self onError:^(id error) {
            if (self.state != ChannelJoining) {
                self.state = ChannelErrored;
            }
        }];
        
        [self onEvent:@"phx_reply" callback:^(id message, id ref) {
            [self triggerEvent:[self replyEventName:ref] message:message ref:ref];
        }];
    }
    return self;
}

- (PhxPush*)join {
    if (self.joinedOnce) {
        // ERROR
    } else {
        self.joinedOnce = YES;
    }
    
    [self sendJoin];
    return self.joinPush;
}

- (void)rejoin {
    if (self.joinedOnce && self.state != ChannelJoined && self.state != ChannelJoining) {
        [self sendJoin];
    }
}

- (void)sendJoin {
    self.state = ChannelJoining;
    self.joinPush.payload = self.params;
    [self.joinPush send];
}

- (BOOL)canSendPush {
    return [self.socket isConnected] && (self.state == ChannelJoined);
}

- (void)leave {
    [[self pushEvent:@"phx_leave" payload:@{}] onReceive:@"ok" callback:^(id message) {
        [self triggerEvent:@"phx_close" message:@"leave" ref:nil];
    }];
}

- (void)onClose:(OnClose)callback {
    [self onEvent:@"phx_close" callback:^(id message, id ref) {
        callback(message);
    }];
}

- (void)onError:(OnError)callback {
    [self onEvent:@"phx_error" callback:^(id error, id ref) {
        callback(error);
    }];
}

- (void)onEvent:(NSString*)event callback:(OnReceive)callback {
    [self.bindings addObject:@{@"event":event, @"callback":callback}];
}

- (void)offEvent:(NSString*)event {
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(NSDictionary *binding, NSDictionary *bindings) {
        return [[binding valueForKey:@"event"] isEqualToString:event];
    }];
    NSArray *bindings = [self.bindings filteredArrayUsingPredicate:predicate];
    for (NSDictionary *binding in bindings) {
        [self.bindings removeObject:binding];
    }
}

- (BOOL)isMemberOfTopic:(NSString*)topic {
    return [self.topic isEqualToString:topic];
}

- (NSString*)replyEventName:(NSString*)ref {
    return [NSString stringWithFormat:@"chan_reply_%@", ref];
}

- (void)triggerEvent:(NSString*)event message:(id)message ref:(id)ref {
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(NSDictionary *binding, NSDictionary *bindings) {
        return [[binding valueForKey:@"event"] isEqualToString:event];
    }];
    NSArray *bindings = [self.bindings filteredArrayUsingPredicate:predicate];
    for (NSDictionary *binding in bindings) {
        OnReceive callback = [binding objectForKey:@"callback"];
        callback(message, ref);
    }
}

- (PhxPush*)pushEvent:(NSString*)event payload:(NSDictionary*)payload {
    PhxPush *pushEvent = [[PhxPush alloc] initWithChannel:self event:event payload:payload];
    [pushEvent send];
    return pushEvent;
}
@end
