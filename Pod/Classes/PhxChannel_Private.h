//
//  PhxChannel_Private.h
//  Pods
//
//  Created by Justin Schneck on 5/11/15.
//
//

#import <Foundation/Foundation.h>

@class PhxChannel;

@interface PhxChannel ()

- (void)rejoin;
- (void)triggerEvent:(NSString*)event message:(NSString*)message;
- (BOOL)isMemberOfTopic:(NSString*)topic;
- (NSString*)replyEventName:(NSString*)ref;

@end