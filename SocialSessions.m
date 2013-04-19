//
//  FBSessions.m
//
//  Created by Rex Sheng on 10/16/12.
//  Copyright (c) 2012 Log(n) LLC. All rights reserved.
//

#import "SocialSessions.h"
#import "SocialSessionsSubclass.h"

NSString *const SUInvalidSlotNumber = @"com.lognllc.SocialSessions:InvalidSlotNumber";

static NSString *const SUUserIDKeyFormat = @"%@UserID%d";
static NSString *const SUUserNameKeyFormat = @"%@UserName%d";
static NSString *const SUUserEmailKeyFormat = @"%@UserEmail%d";
static NSString *const SUTokenKeyFormat = @"%@Token%d";
static NSString *const SUTokenSecretKeyFormat = @"%@TokenSecret%d";
static NSString *const SUTokenExpirationDateKeyFormat = @"%@TokenExpirationDate%d";

@implementation SocialSessions

- (id)initWithPrefix:(NSString *)prefix
{
	return [self initWithPrefix:prefix maximumUserSlots:7];
}

- (id)initWithPrefix:(NSString *)prefix maximumUserSlots:(int)maximumUserSlots
{
	if (self = [super init]) {
		_maximumUserSlots = maximumUserSlots;
		_prefix = [NSString stringWithFormat:@"%@%@", prefix, NSStringFromClass(self.class)];
	}
	return self;
}

+ (BOOL)canHandleURL:(NSURL *)URL
{
	if ([self conformsToProtocol:@protocol(SocialSessionsTrait)])
		return [URL.scheme hasPrefix:[(id<SocialSessionsTrait>)self socialIdentifier]];
	return NO;
}

- (void)sendNotification
{
	[[NSNotificationCenter defaultCenter] postNotificationName:[NSString stringWithFormat:@"%@ValueChanged", _prefix] object:nil];
}

- (void)validateSlotNumber:(int)slot
{
	if (slot < 0 || slot >= [self maximumUserSlots]) {
		[[NSException exceptionWithName:SUInvalidSlotNumber
								 reason:[NSString stringWithFormat:@"Invalid slot number %d specified", slot]
							   userInfo:nil]
		 raise];
	}
}

- (BOOL)isSlotEmpty:(int)slot
{
	NSString *token = [self userTokenInSlot:slot];
	return  token == nil;
}

- (NSUInteger)usedSlotCount
{
	int numSlots = [self maximumUserSlots];
	NSUInteger count = 0;
	for (int i = 0; i < numSlots; ++i) {
		if ([self isSlotEmpty:i] == NO) {
			count++;
		}
	}
	return count;
}

- (BOOL)areAllSlotsEmpty
{
	int numSlots = [self maximumUserSlots];
	for (int i = 0; i < numSlots; ++i) {
		if ([self isSlotEmpty:i] == NO) {
			return NO;
		}
	}
	return YES;
}

- (NSString *)idKeyForSlot:(int)slot
{
	return [NSString stringWithFormat:SUUserIDKeyFormat, _prefix, slot];
}

- (NSString *)nameKeyForSlot:(int)slot
{
	return [NSString stringWithFormat:SUUserNameKeyFormat, _prefix, slot];
}

- (NSString *)emailKeyForSlot:(int)slot
{
	return [NSString stringWithFormat:SUUserEmailKeyFormat, _prefix, slot];
}

- (NSString *)tokenKeyForSlot:(int)slot
{
	return [NSString stringWithFormat:SUTokenKeyFormat, _prefix, slot];
}

- (NSString *)tokenSecretKeyForSlot:(int)slot
{
	return [NSString stringWithFormat:SUTokenSecretKeyFormat, _prefix, slot];
}

- (NSString *)tokenExpirationDateKeyForSlot:(int)slot
{
	return [NSString stringWithFormat:SUTokenExpirationDateKeyFormat, _prefix, slot];
}

- (LNUser *)userInSlot:(int)slot
{
	NSString *token = [self userTokenInSlot:slot];
	if (token) {
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		NSString *idKey = [self idKeyForSlot:slot];
		NSString *nameKey = [self nameKeyForSlot:slot];
		NSString *emailKey = [self emailKeyForSlot:slot];
		
		LNUser *user = [LNUser new];
		user.slot = slot;
		user.accessToken = token;
		user.accessTokenSecret = [self userTokenSecretInSlot:slot];
        user.accessTokenExpirationDate = [self userTokenExpirationDateInSlot:slot];
		user.id = [defaults objectForKey:idKey];
		user.name = [defaults objectForKey:nameKey];
		user.email = [defaults objectForKey:emailKey];
		return user;
	}
	return nil;
}

- (void)updateUser:(LNUser *)user inSlot:(int)slot;
{
	[self validateSlotNumber:slot];
	if (!user) {
		return [self removeUserInSlot:slot];
	}
	
	NSString *userId = user.id;
	NSString *token = user.accessToken;
	if (!userId && !token) {
		NSAssert(userId || token, @"you must provide user.id or user.accessToken");
	}
	int numSlots = [self maximumUserSlots];
	
	if (userId) {
		for (int i = 0; i < numSlots; i++) {
			if (i != slot && [[self userInSlot:i].id isEqualToString:userId]) {
				[self removeUserInSlot:i];
			}
		}
	} else if (token) {
		for (int i = 0; i < numSlots; i++) {
			if (i != slot && [[self userInSlot:i].accessToken isEqualToString:token]) {
				[self removeUserInSlot:i];
			}
		}
	}
	
	NSString *idKey = [self idKeyForSlot:slot];
	NSString *nameKey = [self nameKeyForSlot:slot];
	NSString *emailKey = [self emailKeyForSlot:slot];
	NSString *tokenSecretKey = [self tokenSecretKeyForSlot:slot];
    NSString *tokenExpirationDateKey = [self tokenExpirationDateKeyForSlot:slot];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
#if DEBUG
	NSLog(@"%d) id: %@, name: %@ token: %@", slot, user.id, user.name, user.accessToken);
#endif
	if (user.id) [defaults setObject:user.id forKey:idKey];
	if (user.name) [defaults setObject:user.name forKey:nameKey];
	if (user.email) [defaults setObject:user.email forKey:emailKey];
	if (user.accessTokenSecret) [defaults setObject:user.accessTokenSecret forKey:tokenSecretKey];
	if (user.accessToken) [self setUserToken:user.accessToken InSlot:slot];
    if (user.accessTokenExpirationDate) [self setUserTokenExpirationDate:user.accessTokenExpirationDate InSlot:slot];
	
	[defaults synchronize];
	
	[self sendNotification];
}

- (NSString *)userTokenInSlot:(int)slot
{
	[self validateSlotNumber:slot];
	return [[NSUserDefaults standardUserDefaults] objectForKey:[self tokenKeyForSlot:slot]];
}

- (void)setUserToken:(NSString *)token InSlot:(int)slot
{
	NSString *tokenKey = [self tokenKeyForSlot:slot];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if (token) {
		[defaults setObject:token forKey:tokenKey];
	} else {
		[defaults removeObjectForKey:tokenKey];
	}
	[defaults synchronize];
}

- (void)setUserTokenExpirationDate:(NSDate *)expirationDate InSlot:(int)slot
{
    NSString *tokenExpirationKey = [self tokenExpirationDateKeyForSlot:slot];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if (tokenExpirationKey) {
		[defaults setObject:tokenExpirationKey forKey:tokenExpirationKey];
	} else {
		[defaults removeObjectForKey:tokenExpirationKey];
	}
	[defaults synchronize];
}

- (NSString *)userTokenSecretInSlot:(int)slot
{
	[self validateSlotNumber:slot];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	return [defaults objectForKey:[self tokenSecretKeyForSlot:slot]];
}

- (NSDate *)userTokenExpirationDateInSlot:(int)slot
{
    [self validateSlotNumber:slot];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	return [defaults objectForKey:[self tokenExpirationDateKeyForSlot:slot]];
}

- (void)removeUserTokenInSlot:(int)slot
{
	NSString *tokenKey = [self tokenKeyForSlot:slot];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults removeObjectForKey:tokenKey];
	[defaults synchronize];
}

- (void)removeUserInSlot:(int)slot
{
	NSString *idKey = [self idKeyForSlot:slot];
	NSString *nameKey = [self nameKeyForSlot:slot];
	NSString *emailKey = [self emailKeyForSlot:slot];
	NSString *tokenSecretKey = [self tokenSecretKeyForSlot:slot];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	NSLog(@"clearing %@ slot %d", _prefix, slot);
	[defaults removeObjectForKey:idKey];
	[defaults removeObjectForKey:nameKey];
	[defaults removeObjectForKey:emailKey];
	[self removeUserTokenInSlot:slot];
	[defaults removeObjectForKey:tokenSecretKey];
	
	[defaults synchronize];
	
	[self sendNotification];
}

@end
