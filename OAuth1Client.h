//
//  OAuth1Client.h
//
//  Created by Rex Sheng on 10/24/12.
//  Copyright (c) 2012 Log(n) LLC. All rights reserved.
//

#import "AFHTTPClient.h"

@interface OAuth1Client : AFHTTPClient

- (id)initWithBaseURL:(NSURL *)url
                  key:(NSString *)clientID
               secret:(NSString *)_secret;

@property (nonatomic, copy) NSString *userToken;
@property (nonatomic, copy) NSString *userTokenSecret;

@end


@interface NSURL (OAuthAdditions)

+ (NSDictionary *)ab_parseURLQueryString:(NSString *)query;

@end