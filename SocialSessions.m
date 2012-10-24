//
//  FBSessions.m
//
//  Created by Rex Sheng on 10/16/12.
//  Copyright (c) 2012 Log(n) LLC. All rights reserved.
//

#import "SocialSessions.h"

NSString *const SUInvalidSlotNumber = @"com.lognllc.SocialSessions:InvalidSlotNumber";

static NSString *const SUUserIDKeyFormat = @"%@UserID%d";
static NSString *const SUUserNameKeyFormat = @"%@UserName%d";
static NSString *const SUTokenKeyFormat = @"%@Token%d";
static NSString *const SUTokenSecretKeyFormat = @"%@TokenSecret%d";

@implementation SocialSessions

@synthesize maximumUserSlots, prefix;

- (id)initWithPrefix:(NSString *)_prefix
{
	return [self initWithPrefix:_prefix maximumUserSlots:7];
}

- (id)initWithPrefix:(NSString *)_prefix maximumUserSlots:(int)_maximumUserSlots
{
	if (self = [super init]) {
		maximumUserSlots = _maximumUserSlots;
		prefix = [NSString stringWithFormat:@"%@%@", _prefix, NSStringFromClass(self.class)];
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
	[[NSNotificationCenter defaultCenter] postNotificationName:[NSString stringWithFormat:@"%@ValueChanged", prefix] object:nil];
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
	return [self userTokenInSlot:slot] == nil;
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
	return [NSString stringWithFormat:SUUserIDKeyFormat, prefix, slot];
}

- (NSString *)nameKeyForSlot:(int)slot
{
	return [NSString stringWithFormat:SUUserNameKeyFormat, prefix, slot];
}

- (NSString *)tokenKeyForSlot:(int)slot
{
	return [NSString stringWithFormat:SUTokenKeyFormat, prefix, slot];
}

- (NSString *)tokenSecretKeyForSlot:(int)slot
{
	return [NSString stringWithFormat:SUTokenSecretKeyFormat, prefix, slot];
}

- (NSString *)userNameInSlot:(int)slot
{
	[self validateSlotNumber:slot];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	return [defaults objectForKey:[self nameKeyForSlot:slot]];
}

- (NSString *)userIDInSlot:(int)slot
{
	[self validateSlotNumber:slot];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	return [defaults objectForKey:[self idKeyForSlot:slot]];
}

- (NSString *)userTokenInSlot:(int)slot
{
	[self validateSlotNumber:slot];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	return [defaults objectForKey:[self tokenKeyForSlot:slot]];
}

- (NSString *)userTokenSecretInSlot:(int)slot
{
	[self validateSlotNumber:slot];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	return [defaults objectForKey:[self tokenSecretKeyForSlot:slot]];
}

- (void)removeUserInSlot:(int)slot
{
	NSString *idKey = [self idKeyForSlot:slot];
	NSString *nameKey = [self nameKeyForSlot:slot];
	NSString *tokenKey = [self tokenKeyForSlot:slot];
	NSString *tokenSecretKey = [self tokenSecretKeyForSlot:slot];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	NSLog(@"clearing slot %d", slot);
	[defaults removeObjectForKey:idKey];
	[defaults removeObjectForKey:nameKey];
	[defaults removeObjectForKey:tokenKey];
	[defaults removeObjectForKey:tokenSecretKey];
	
	[defaults synchronize];
	
	[self sendNotification];
}

@end
