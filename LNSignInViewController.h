//
//  LNSignInViewController.h
//
//  Created by Rex Sheng on 10/26/12.
//  Copyright (c) 2012 Log(n) LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LNUser.h"
#import "LNTextField.h"

@class IdentityManager;
@class LNSignInViewController;

@protocol LNSignInViewControllerDelegate <NSObject>

- (void)signInViewController:(LNSignInViewController *)controller signIn:(LNUser *)user;

- (NSPredicate *)signInViewController:(LNSignInViewController *)controller predicateForField:(LNTextField *)field errorMessage:(NSString **)errorMessage;

@optional
- (void)signUp;
- (void)signInViewController:(LNSignInViewController *)controller signInFacebook:(LNUser *)user;
- (CGRect)frameForFacebookButtonInSignInViewController:(LNSignInViewController *)controller;
- (void)signInViewController:(LNSignInViewController *)controller signInTwitter:(LNUser *)user;
- (CGRect)frameForTwitterButtonInSignInViewController:(LNSignInViewController *)controller;


@end

@interface LNSignInViewController : UIViewController

@property (nonatomic, strong, readonly) LNTextField *emailField;
@property (nonatomic, strong, readonly) LNTextField *passwordField;
@property (nonatomic, strong, readonly) UIButton *loginButton;
@property (nonatomic, strong, readonly) UIButton *signUpButton;
@property (nonatomic, strong, readonly) UIButton *facebookLoginButton;
@property (nonatomic, strong, readonly) UIButton *twitterLoginButton;

@property (nonatomic, strong) IdentityManager *identityManager;
@property (nonatomic, assign) CGFloat logoHeight;
@property (nonatomic, assign) CGFloat logoScale;
@property (nonatomic, assign) CGFloat logoYFactor;

@property (nonatomic, weak) id<LNSignInViewControllerDelegate> delegate;

@end
