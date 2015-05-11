# PhoenixClient

[![CI Status](http://img.shields.io/travis/Justin Schneck/PhoenixClient.svg?style=flat)](https://travis-ci.org/Justin Schneck/PhoenixClient)
[![Version](https://img.shields.io/cocoapods/v/PhoenixClient.svg?style=flat)](http://cocoapods.org/pods/PhoenixClient)
[![License](https://img.shields.io/cocoapods/l/PhoenixClient.svg?style=flat)](http://cocoapods.org/pods/PhoenixClient)
[![Platform](https://img.shields.io/cocoapods/p/PhoenixClient.svg?style=flat)](http://cocoapods.org/pods/PhoenixClient)

## Usage

PhoenixClient is intended for use with Phoenix version >= 0.13.0. This client is not backwards compatible with a phoenix server less than this version.

### Socket Connection

```
PhxSocket *socket = [[PhxSocket alloc] initWithURL:url heartbeatInterval:20];
```

### Socket Hooks

```
[socket onClose:^(void) {
  NSLog(@"the connection dropped");
}];

[socket onError:^(id error) {
  NSLog(@"there was an error with the connection!");
}];
```

### Channels

```
PhxChannel *chan = [[PhxChannel alloc] initWithSocket:socket topic:@"rooms:123" params:@{@"token":roomToken}];
[chan onEvent:@"new_msg" callback:^(id message) {
  NSLog(@"Got message %@", message);
}];
```

### Channel Hooks

```
[chan onClose:^(void) {
  NSLog(@"the channel has gone away gracefully");
}];

[chan onError:^(id error) {
  NSLog(@"there was an error!");
}];
```

### Joining Channels

```
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

```
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

## Author

Justin Schneck, jschneck@mac.com

## License

PhoenixClient is available under the MIT license. See the LICENSE file for more info.
