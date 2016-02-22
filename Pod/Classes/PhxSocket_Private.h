//
//  PhxSocket_Private.h
//  Pods
//
//  Created by Justin Schneck on 5/11/15.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class PhxSocket;
@class PhxChannel;

@interface PhxSocket ()

- (void)addChannel:(PhxChannel*)channel;
- (void)removeChannel:(PhxChannel*)channel;

@end

NS_ASSUME_NONNULL_END
