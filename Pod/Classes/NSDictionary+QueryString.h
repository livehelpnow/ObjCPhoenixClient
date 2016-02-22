//
//  NSDictionary+QueryString.h
//  Pods
//
//  Created by Justin Schneck on 8/17/15.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDictionary (QueryString)
+ (NSDictionary *)dictionaryWithQueryString:(NSString *)queryString;
- (NSString *)queryStringValue;
@end

NS_ASSUME_NONNULL_END
