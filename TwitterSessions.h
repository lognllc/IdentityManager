//
//  TwitterSessions.h
//
//  Created by Rex Sheng on 10/22/12.
//  Copyright (c) 2012 Log(n) LLC. All rights reserved.
//

#import "SocialSessions.h"

@class OAuth1Client;

@interface TwitterSessions : SocialSessions <SocialSessionsTrait>

@property (nonatomic, strong, readonly) OAuth1Client *client;

@end
