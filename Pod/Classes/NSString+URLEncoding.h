//
//  NSString+URLEncoding.h
//  Pods
//
//  Created by Justin Schneck on 8/17/15.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (URLEncoding)
- (NSString *)URLEncodedString;
- (NSString *)URLDecodedString;
@end

NS_ASSUME_NONNULL_END
