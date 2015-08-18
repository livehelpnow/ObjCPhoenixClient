//
//  NSDictionary+QueryString.h
//  Pods
//
//  Created by Justin Schneck on 8/17/15.
//
//

#import <Foundation/Foundation.h>

@interface NSDictionary (QueryString)
+ (NSDictionary *)dictionaryWithQueryString:(NSString *)queryString;
- (NSString *)queryStringValue;
@end
