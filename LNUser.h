//
//  LNUser.h
//  Hauler Deals
//
//  Created by Rex Sheng on 10/26/12.
//  Copyright (c) 2012 Log(n) LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LNUser : NSObject

@property (nonatomic, copy) NSString *id;
@property (nonatomic, copy) NSString *email;
@property (nonatomic, copy) NSString *password;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) NSURL *avatarURL;
@property (nonatomic, copy) NSString *accessToken;
@property (nonatomic, copy) NSString *accessTokenSecret;
@property (nonatomic, assign) int slot;

@end
