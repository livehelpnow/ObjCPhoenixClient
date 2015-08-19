//
//  MessageTableRow.h
//  ChannelDemo
//
//  Created by Justin Schneck on 8/18/15.
//  Copyright © 2015 PhoenixFramework. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WatchKit/WatchKit.h>

@interface MessageTableRow : NSObject
@property (weak) IBOutlet WKInterfaceLabel *user;
@property (weak) IBOutlet WKInterfaceLabel *body;
@end
