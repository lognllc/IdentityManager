//
//  IdentityManager.m
//
//  Created by Rex Sheng on 10/22/12.
//  Copyright (c) 2012 Log(n) LLC. All rights reserved.
//

#import "IdentityManager.h"
#import "OAuth1Gateway.h"
#import "SocialSessions.h"

@interface IdentityManager ()

@property (strong, nonatomic) NSMutableArray *registeredSocialSessions;
@property (strong, nonatomic) NSMutableDictionary *sessionsObjects;
@property (strong, nonatomic) NSString *prefix;

@end

@implementation IdentityManager

- (id)initWithPrefix:(NSString *)prefix maximumUserSlots:(int)slots
{
	if (self = [super init]) {
		_prefix = prefix;
		_slots = slots;
		_registeredSocialSessions = [NSMutableArray arrayWithCapacity:3];
		_sessionsObjects = [NSMutableDictionary dictionaryWithCapacity:3];
	}
	return self;
}

- (BOOL)registerSocialSessionsClass:(Class)sessionClass
{
	if (![sessionClass conformsToProtocol:@protocol(SocialSessionsTrait)]) {
		return NO;
	}
	NSString *identifier = [sessionClass socialIdentifier];
	
	id sessions = [[sessionClass alloc] initWithPrefix:_prefix maximumUserSlots:_slots];
	_sessionsObjects[identifier] = sessions;
	[_registeredSocialSessions removeObject:identifier];
	[_registeredSocialSessions insertObject:identifier atIndex:0];
    return YES;
}

- (void)unregisterSocialSessionsClass:(Class)sessionClass
{
	if (![sessionClass conformsToProtocol:@protocol(SocialSessionsTrait)]) {
		return;
	}
	NSString *identifier = [sessionClass socialIdentifier];
	[_sessionsObjects removeObjectForKey:identifier];
    [_registeredSocialSessions removeObject:identifier];
}

- (int)usedSlots
{
	int usedSlotsCount = 0;
	for (id<SocialSessionsTrait> sessions in [_sessionsObjects allValues]) {
		usedSlotsCount += [sessions usedSlotCount];
	}
	return usedSlotsCount;
}

- (int)authenticateIdentityWithServiceIdentifier:(NSString *)identifier reuseSlot:(BOOL)reuse completion:(void(^)(LNUser *))completion
{
	BOOL avaiable = reuse;
	if (!avaiable) {
		avaiable = [self usedSlots] < _slots;
	}
	if (avaiable) {
		id<SocialSessionsTrait> sessions = [self registeredSocialSessionsWithServiceIdentifier:identifier];
		if (sessions) {
			int maxCount = [sessions maximumUserSlots];
			int i = 0;
			for (; i < maxCount; i++) {
				if ([sessions isSlotEmpty:i]) {
					[sessions loginSlot:i completion:completion];
					return i;
				}
			}
			if (reuse) {
				i = 0;
#if DEBUG
				NSLog(@"no slot is empty reusing first one");
#endif
				[sessions loginSlot:i completion:completion];
				return i;
			}
		} else {
			NSLog(@"Error: identifier '%@' does not match any registered socialsessions", identifier);
			if (completion) completion(nil);
		}
	}
	return -1;
}

- (void)logoutAll
{
	for (id<SocialSessionsTrait> sessions in [_sessionsObjects allValues]) {
		int maxCount = [sessions maximumUserSlots];
		for (int i = 0; i < maxCount; i++) {
			[sessions removeUserInSlot:i];
		}
	}
}

- (BOOL)handleOpenURL:(NSURL *)url
{
	__block BOOL handled = NO;
	[[_sessionsObjects allValues] enumerateObjectsUsingBlock:^(id<SocialSessionsTrait> obj, NSUInteger idx, BOOL *stop) {
		if ([[obj class] canHandleURL:url]) {
			[obj handleOpenURL:url];
			handled = YES;
			*stop = YES;
		}
	}];
	return handled;
}

- (id<SocialSessionsTrait>)registeredSocialSessionsWithServiceIdentifier:(NSString *)identifier
{
	return _sessionsObjects[identifier];
}

@end
