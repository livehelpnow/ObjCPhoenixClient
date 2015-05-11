//
//  PhxTypes.h
//  Pods
//
//  Created by Justin Schneck on 5/11/15.
//
//

typedef enum {
    SocketConnecting,
    SocketOpen,
    SocketClosing,
    SocketClosed
} SocketState;


typedef enum {
    ChannelClosed,
    ChannelErrored,
    ChannelJoined,
    ChannelJoining
} ChannelState;

typedef void (^OnOpen)(void);
typedef void (^OnClose)(id event);
typedef void (^OnError)(id error);
typedef void (^OnMessage)(NSString *topic, NSString *event, id payload);
typedef void (^OnReceive)(id message);
typedef void (^After)(void);