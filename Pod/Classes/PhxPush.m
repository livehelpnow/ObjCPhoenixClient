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

NS_ASSUME_NONNULL_BEGIN

@interface PhxPush ()

@property (nonatomic, weak) PhxChannel *channel;
@property (nonatomic) NSString *event;
@property (nonatomic) NSString *refEvent;
@property (nonatomic) NSDictionary *payload;

@property (nullable, nonatomic, copy) After afterHook;
@property int afterInterval;
@property (nullable, nonatomic) NSTimer *afterTimer;

@property (nonatomic) NSMutableArray *recHooks;
@property (nullable, nonatomic) id receivedResp;
@property (atomic) BOOL sent;

@end

@implementation PhxPush

- (instancetype)initWithChannel:(PhxChannel*)channel
                          event:(NSString*)event
                        payload:(NSDictionary*)payload {
    self = [super init];
    if (self) {
        self.channel = channel;
        self.event = event;
        self.payload = payload;
        self.receivedResp = nil;
        self.afterHook = nil;
        self.recHooks = [NSMutableArray new];
        self.sent = NO;
    }
    return self;
}

- (void)send {
    NSString *ref = [self.channel.socket makeRef];
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

NS_ASSUME_NONNULL_END
