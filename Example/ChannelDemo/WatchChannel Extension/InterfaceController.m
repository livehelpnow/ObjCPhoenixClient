//
//  InterfaceController.m
//  WatchChannel Extension
//
//  Created by Justin Schneck on 8/18/15.
//  Copyright © 2015 PhoenixFramework. All rights reserved.
//

#import "InterfaceController.h"
#import "MessageTableRow.h"
#import <WatchConnectivity/WatchConnectivity.h>
@import WatchKit;

@interface InterfaceController() <WCSessionDelegate>
@property (nonatomic, retain) NSMutableArray *messages;
@property (nonatomic, retain) IBOutlet WKInterfaceTable *messageTable;
@property (nonatomic, retain) IBOutlet WKInterfaceButton *sendButton;
@property (nonatomic, retain) WCSession *session;
@end


@implementation InterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

    // Configure interface objects here.
    // Connect and accept
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
    
    if ([WCSession isSupported]) {
        if (self.session == nil) {
            self.session = [WCSession defaultSession];
        }
        self.session.delegate = self;
        [self.session activateSession];
    }
    
    
    if (self.messages == nil) {
        self.messages = [NSMutableArray new];
    }
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}


- (IBAction)sendMessage:(id)sender {
    [self presentTextInputControllerWithSuggestions:@[@"Hello There", @"Yes", @"No"] allowedInputMode:WKTextInputModePlain completion:^(NSArray * _Nullable results) {
        id body = [results objectAtIndex:0];
        if (body != nil && self.session.reachable) {
            NSDictionary *applicationData = [[NSDictionary alloc] initWithObjects:@[body] forKeys:@[@"body"]];

            [self.session sendMessage:applicationData
                                       replyHandler:^(NSDictionary *reply) {
                                           //handle reply from iPhone app here
                                           NSLog(@"iPhone Reply: %@", reply);
                                       }
                                       errorHandler:^(NSError *error) {
                                           //catch any errors here
                                           NSLog(@"Error: %@", [error localizedDescription]);
                                       }
             ];
        }
        
    }];
}

- (void)session:(WCSession *)session didReceiveMessage:(NSDictionary<NSString *,id> *)message replyHandler:(void (^)(NSDictionary<NSString *,id> * _Nonnull))replyHandler {
    NSString *user = [message valueForKey:@"user"];
    NSString *body = [message valueForKey:@"body"];
    [self.messages addObject:@{@"user":user, @"body":body}];
    [self reloadTable];
}

- (void)reloadTable {
    if (self.messageTable.numberOfRows != self.messages.count) {
        [self.messageTable setNumberOfRows:self.messages.count withRowType:@"MessageTableRow"];
    }
    for (int i = 0; i < self.messages.count; i++) {
        MessageTableRow *row = [self.messageTable rowControllerAtIndex:i];
        NSDictionary *message = [self.messages objectAtIndex:i];
        [row.user setText:[message valueForKey:@"user"]];
        [row.body setText:[message valueForKey:@"body"]];
    }
    [self.messageTable scrollToRowAtIndex:self.messages.count -1];
}

@end



