//
//  NSString+URLEncoding.h
//  Pods
//
//  Created by Justin Schneck on 8/17/15.
//
//

#import <Foundation/Foundation.h>

@interface NSString (URLEncoding)
- (NSString *)URLEncodedString;
- (NSString *)URLDecodedString;
@end
