//
//  LNSignInViewController.h
//  Hauler Deals
//
//  Created by Rex Sheng on 10/26/12.
//  Copyright (c) 2012 Log(n) LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
@class IdentityManager;

@interface LNSignInViewController : UIViewController

@property (nonatomic, strong, readonly) UITextField *emailField;
@property (nonatomic, strong, readonly) UITextField *passwordField;
@property (nonatomic, strong, readonly) IdentityManager *identityManager;

- (void)signIn;
- (void)signUp;
- (void)forgotPassword;

@end
