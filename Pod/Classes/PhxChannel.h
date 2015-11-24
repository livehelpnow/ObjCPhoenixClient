//
//  PhxChannel.h
//  Pods
//
//  Created by Justin Schneck on 5/1/15.
//
//

#import <Foundation/Foundation.h>
#import "PhxTypes.h"


@class PhxSocket;
@class PhxChannel;
@class PhxPush;

@protocol PhxChannelDelegate <NSObject>

- (void)phxChannelClosed;
- (void)phxChannelDidReceiveError:(id)error;

@end

@interface PhxChannel : NSObject

@property (nonatomic, weak) id<PhxChannelDelegate> delegate;
@property (nonatomic, weak) PhxSocket* socket;
@property (nonatomic, readonly) ChannelState state;
@property (nonatomic, retain) NSString* topic;
@property (nonatomic, retain) NSDictionary *params;

- (id)initWithSocket:(PhxSocket*)socket
               topic:(NSString*)topic
              params:(NSDictionary*)params;

- (PhxPush*)join;
- (void)leave;

- (void)onEvent:(NSString*)event callback:(OnReceive)callback;
- (void)offEvent:(NSString*)event;

- (void)onClose:(OnClose)callback;
- (void)onError:(OnError)callback;

- (PhxPush*)pushEvent:(NSString*)event payload:(NSDictionary*)payload;

@end