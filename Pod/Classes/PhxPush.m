//
//  PhxPush.m
//  Pods
//
//  Created by Justin Schneck on 5/1/15.
//
//

#import "PhxPush.h"
#import "PhxChannel.h"
#import "PhxChannel_Private.h"
#import "PhxSocket.h"

@interface PhxPush ()

@property (nonatomic, weak) PhxChannel *channel;
@property (nonatomic, retain) NSString *event;
@property (nonatomic, retain) NSString *refEvent;
@property (nonatomic, retain) NSDictionary *payload;

@property (nonatomic, copy) After afterHook;
@property (readwrite) int afterInterval;
@property (nonatomic, retain) NSTimer *afterTimer;

@property (nonatomic, retain) NSMutableArray *recHooks;
@property (nonatomic, retain) id receivedResp;
@property (readwrite) BOOL sent;

@end

@implementation PhxPush

- (id)initWithChannel:(PhxChannel*)channel
                event:(NSString*)event
              payload:(NSDictionary*)payload {
    self = [super init];
    if (self) {
        self.channel = channel;
        self.event = event;
        if (payload) {
            self.payload = payload;
        } else {
            self.payload = @{};
        }
        self.receivedResp = nil;
        self.afterHook = nil;
        self.recHooks = [NSMutableArray new];
        self.sent = NO;
    }
    return self;
}

- (void)send {
    const NSString *ref = [self.channel.socket makeRef];
    self.refEvent = [self.channel replyEventName:ref];
    self.receivedResp = nil;
    self.sent = NO;
    
    __weak typeof(self) weakSelf = self;
    [self.channel onEvent:self.refEvent callback:^(id message, id ref) {
        weakSelf.receivedResp = message;
        [weakSelf matchReceive:message];
        [weakSelf cancelRefEvent];
        [weakSelf cancelAfter];
    }];
    [self startAfter];
    self.sent = YES;
    [self.channel.socket push:@{@"topic":self.channel.topic, @"event": self.event, @"payload":self.payload, @"ref": ref}];
}

- (PhxPush*)onReceive:(NSString *)status callback:(OnMessage)callback {
    if (self.receivedResp && [[self.receivedResp valueForKey:@"status"] isEqualToString:status]) {
        callback(self.receivedResp);
    }
    [self.recHooks addObject:@{@"status": status, @"callback": callback}];
    return self;
}

- (PhxPush*)after:(int)ms callback:(After)callback {
    if (self.afterHook) {
        // ERROR
    }
    self.afterTimer = [NSTimer scheduledTimerWithTimeInterval:ms target:self selector:@selector(afterTimerFire:) userInfo:nil repeats:NO];
    self.afterInterval = ms;
    self.afterHook = callback;
    return self;
}

- (void)cancelRefEvent {
    [self.channel offEvent:self.refEvent];
}

- (void)cancelAfter {
    if (!self.afterHook) {
        return;
    }
    [self.afterTimer invalidate];
    self.afterTimer = nil;
}

- (void)startAfter {
    if (!self.afterHook) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    After callback = ^() {
        [weakSelf cancelRefEvent];
        weakSelf.afterHook();
    };
    self.afterTimer = [NSTimer scheduledTimerWithTimeInterval:self.afterInterval target:self selector:@selector(afterTimerFire:) userInfo:callback repeats:NO];
}

- (void)afterTimerFire:(NSTimer*)timer {
    if ([timer userInfo]) {
        After callback = [timer userInfo];
        callback();
    }
}

- (void)matchReceive:(NSDictionary*)payload {
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(NSDictionary *recHook, NSDictionary *bindings) {
        return [[recHook valueForKey:@"status"] isEqualToString:[payload valueForKey:@"status"]];
    }];
    NSArray *recHooks = [self.recHooks filteredArrayUsingPredicate:predicate];
    for (NSDictionary *recHook in recHooks) {
        OnMessage callback = [recHook objectForKey:@"callback"];
        callback([payload objectForKey:@"response"]);
    }
}

@end
