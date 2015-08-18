//
//  PhxPush.h
//  Pods
//
//  Created by Justin Schneck on 5/1/15.
//
//

#import <Foundation/Foundation.h>
#import "PhxTypes.h"

@class PhxChannel;

@interface PhxPush : NSObject

- (id)initWithChannel:(PhxChannel*)channel
                event:(NSString*)event
              payload:(NSDictionary*)payload;

- (void)send;

- (PhxPush*)onReceive:(NSString*)status callback:(OnMessage)callback;
- (PhxPush*)after:(int)ms callback:(After)callback;

@end
