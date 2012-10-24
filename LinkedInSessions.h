//
//  LinkedInSessions.h
//
//  Created by Rex Sheng on 10/23/12.
//  Copyright (c) 2012 Log(n) LLC. All rights reserved.
//

#import "SocialSessions.h"

@class AFHTTPClient;

@interface LinkedInSessions : SocialSessions <SocialSessionsTrait>

@property (nonatomic, strong, readonly) AFHTTPClient *client;

@end
