//
//  PhxSocket_Private.h
//  Pods
//
//  Created by Justin Schneck on 5/11/15.
//
//

#import <Foundation/Foundation.h>



@class PhxSocket;
@class PhxChannel;

@interface PhxSocket ()

- (void)addChannel:(PhxChannel*)channel;
- (void)removeChannel:(PhxChannel*)channel;

@end