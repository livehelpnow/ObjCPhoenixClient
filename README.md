# PhoenixClient

[![Build Status](https://travis-ci.org/livehelpnow/ObjCPhoenixClient.svg?branch=master)](https://travis-ci.org/livehelpnow/ObjCPhoenixClient)
[![Version](https://img.shields.io/cocoapods/v/PhoenixClient.svg?style=flat)](http://cocoapods.org/pods/PhoenixClient)
[![License](https://img.shields.io/cocoapods/l/PhoenixClient.svg?style=flat)](http://cocoapods.org/pods/PhoenixClient)
[![Platform](https://img.shields.io/cocoapods/p/PhoenixClient.svg?style=flat)](http://cocoapods.org/pods/PhoenixClient)

## Usage

PhoenixClient is ready for use with Phoenix Framework v1.0.0. The PhoenixClient enables communication with a phoenix framework web project through the use of channels over websocket.

Learn more about the Phoenix Framework at
http://www.phoenixframework.org/

### Socket Connection

```objective-c
PhxSocket *socket = [[PhxSocket alloc] initWithURL:url heartbeatInterval:20];
[socket connectWithParams:@{@"user_id":1234}]
```

### Socket Hooks

```objective-c
[socket onClose:^(void) {
  NSLog(@"the connection dropped");
}];

[socket onError:^(id error) {
  NSLog(@"there was an error with the connection!");
}];
```

### Channels

```objc
PhxChannel *chan = [[PhxChannel alloc] initWithSocket:socket topic:@"rooms:123" params:@{@"token":roomToken}];
[chan onEvent:@"new_msg" callback:^(id message) {
  NSLog(@"Got message %@", message);
}];
```

### Channel Hooks

```objective-c
[chan onClose:^(void) {
  NSLog(@"the channel has gone away gracefully");
}];

[chan onError:^(id error) {
  NSLog(@"there was an error!");
}];
```

### Joining Channels

```objective-c
id join = [chan join];
[join onReceive:@"ok" callback:^(id messages) {
  NSLog(@"catching up %@", messages);
}];
[join onReceive:@"error" callback:^(id reason) {
  NSLog(@"failed join %@", reason);
}];
[join after:10000 callback:^(void) {
  NSLog(@"Networking issue. Still waiting...");
}];
```

### Pushing Messages

```objective-c
PhxPush* push = [chan pushEvent:@"new_msg" payload:@{@"Some Message"}];
[push onReceive:@"ok" callback:^(id message) {
  NSLog(@"created message %@", message);
}];
[push onReceive:@"error" callback:^(id reason) {
  NSLog(@"create failed %@", reason);
}];
[push after:10000 callback:^(void) {
  NSLog(@"Networking issue. Still waiting...");
}];
```

## Requirements

## Installation

PhoenixClient is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "PhoenixClient"
```

Or without cocoapods

You can down the source and include all the files located in /Pod/Classes in your project

## Example
Included in the source is the ChannelDemo iOS app. to use this app you will need to run the phoenix_chat_example. You can check this app out from

https://github.com/chrismccord/phoenix_chat_example

Follow the directions on the repo to launch the Phoenix app then launch the ChannelDemo in the Examples folder of this repository.

## License

PhoenixClient is available under the MIT license. See the LICENSE file for more info.
