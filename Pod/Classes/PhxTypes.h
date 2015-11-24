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
    ChannelJoining,
    ChannelJoined
} ChannelState;

typedef void (^OnOpen)(void);
typedef void (^OnClose)(id event);
typedef void (^OnError)(id error);
typedef void (^OnMessage)(id message);
typedef void (^OnReceive)(id message, id ref);
typedef void (^After)(void);