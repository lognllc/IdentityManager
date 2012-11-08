//
//  FacebookSessions.h
//
//  Created by Rex Sheng on 10/22/12.
//  Copyright (c) 2012 Log(n) LLC. All rights reserved.
//

#import "SocialSessions.h"
@class FBSession;
@class FBRequest;

@interface FacebookSessions : SocialSessions <SocialSessionsTrait>

@property (nonatomic, strong, readonly) FBSession *currentSession;
@property (nonatomic, strong, readonly) FBRequest *pendingRequest;
- (FBSession *)sessionForSlot:(int)slot;

@end
