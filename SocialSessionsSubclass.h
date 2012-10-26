//
//  SocialSessions+Subclassing.h
//
//  Created by Rex Sheng on 10/23/12.
//  Copyright (c) 2012 Log(n) LLC. All rights reserved.
//

#import "SocialSessions.h"

#define IDENTITYMANAGER_ERROR_DOMAIN @"com.lognllc.IdentityManager"

@interface SocialSessions (ForSubclassEyesOnly)

- (NSString *)idKeyForSlot:(int)slot;
- (NSString *)nameKeyForSlot:(int)slot;
- (NSString *)emailKeyForSlot:(int)slot;
- (NSString *)tokenKeyForSlot:(int)slot;
- (NSString *)tokenSecretKeyForSlot:(int)slot;

- (NSString *)userTokenInSlot:(int)slot;
- (void)removeUserTokenInSlot:(int)slot;
- (void)setUserToken:(NSString *)token InSlot:(int)slot;

- (void)updateUser:(LNUser *)user inSlot:(int)slot;

@end
