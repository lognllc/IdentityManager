//
//  LNSignInViewController.m
//  Hauler Deals
//
//  Created by Rex Sheng on 10/26/12.
//  Copyright (c) 2012 Log(n) LLC. All rights reserved.
//

#import "LNSignInViewController.h"
#import "LNTextField.h"
#import "IdentityManager.h"
#import "FacebookSessions.h"
#import "TwitterSessions.h"
#import "MBProgressHUD.h"

@interface LNSignInViewController () <UITextFieldDelegate, UIGestureRecognizerDelegate>

@end

@implementation LNSignInViewController
{
	CGSize logoSize;
	UIImageView *logoView;
	UIView *loginSection;
	BOOL animationPlayed;
}

@synthesize emailField, passwordField, identityManager, delegate;
@synthesize loginButton, signUpButton, facebookLoginButton, twitterLoginButton;
@synthesize logoHeight, logoScale, logoYFactor;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		logoScale = 1;
		logoYFactor = .618f;
	}
	return self;
}

#pragma mark - Action
- (void)signIn
{
	[loginSection endEditing:YES];
	NSString *password = [passwordField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	NSString *email = [emailField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	NSString *errorMessage;
	NSPredicate *predicate = [self.delegate signInViewController:self predicateForField:emailField errorMessage:&errorMessage];
	if (predicate) {
		if (![predicate evaluateWithObject:email]) {
			return [self displayHUDError:@"Login" message:errorMessage];
		}
	}
	predicate = [self.delegate signInViewController:self predicateForField:passwordField errorMessage:&errorMessage];
	if (predicate) {
		if (![predicate evaluateWithObject:password]) {
			return [self displayHUDError:@"Login" message:errorMessage];
		}
	}
	LNUser *user = [LNUser new];
	user.email = email;
	user.password = password;
	[self.delegate signInViewController:self signIn:user];
}

- (void)facebookLogin:(id)sender
{
	FacebookSessions *sessions = [identityManager registeredSocialSessionsWithServiceIdentifier:[FacebookSessions socialIdentifier]];
	[sessions loginSlot:0 completion:^(BOOL success) {
		if (success) {
			[self.delegate signInViewController:self signInFacebook:[sessions userInSlot:0]];
		} else {
			[self displayError:@"Facebook Login" message:@"You have canceled facebook login."];
		}
	}];
}

- (void)displayError:(NSString *)title message:(NSString *)message
{
	dispatch_async(dispatch_get_main_queue(), ^{
		[self hideHUD:YES];
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(title, @"")
															message:NSLocalizedString(message, @"")
														   delegate:self
												  cancelButtonTitle:NSLocalizedString(@"OK", @"")
												  otherButtonTitles:nil];
		[alertView show];
	});
}

- (void)twitterLogin:(id)sender
{
	TwitterSessions *sessions = [identityManager registeredSocialSessionsWithServiceIdentifier:[TwitterSessions socialIdentifier]];
	[sessions loginSlot:0 completion:^(BOOL success) {
		if (success) {
			LNUser *user = [sessions userInSlot:0];
			[self.delegate signInViewController:self signInTwitter:user];
		} else {
			[self displayError:@"Twitter Login" message:@"You have canceled twitter login."];
		}
	}];
}

- (void)signUp
{
}

- (void)keyboardWillShow:(CGRect)newRect
{
	[UIView animateWithDuration:.25f animations:^{
		CGRect f = loginSection.frame;
		f.origin.y = MIN(logoHeight, newRect.origin.y - f.size.height - 5);
		loginSection.frame = f;
		CGPoint p = logoView.center;
		p.y = MIN(logoHeight, f.origin.y) * logoYFactor;
		logoView.center = p;
		CGFloat scale = f.origin.y / logoHeight;
		logoView.transform = CGAffineTransformMakeScale(scale, scale);
	}];
}

#pragma mark - View Lifecycle
- (void)viewDidLoad
{
	[super viewDidLoad];
	
	UIImage *logo = [UIImage imageNamed:@"splash_logo"];
	logoSize = logo.size;
	logoView = [[UIImageView alloc] initWithImage:logo];
	logoView.contentMode = UIViewContentModeScaleAspectFit;
	[self.view addSubview:logoView];
	
	CGSize fullSize = self.view.bounds.size;
	loginSection = [[UIView alloc] initWithFrame:CGRectMake(0, logoHeight, fullSize.width, 0)];
 	
	[self.view addSubview:loginSection];
	emailField = [[LNTextField alloc] initWithFrame:CGRectMake(0, 0, fullSize.width, 40)];
	emailField.placeholder = NSLocalizedString(@"Email", nil);
	emailField.keyboardType = UIKeyboardTypeEmailAddress;
	emailField.autocapitalizationType = UITextAutocapitalizationTypeNone;
	emailField.autocorrectionType = UITextAutocorrectionTypeNo;
	emailField.returnKeyType = UIReturnKeyNext;
	emailField.delegate = self;
	[loginSection addSubview:emailField];
	
	passwordField = [[LNTextField alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(emailField.frame) + 1, fullSize.width, 40)];
	passwordField.placeholder = NSLocalizedString(@"Password", nil);
	passwordField.secureTextEntry = YES;
	passwordField.returnKeyType = UIReturnKeyGo;
	passwordField.delegate = self;
	[loginSection addSubview:passwordField];
	
	loginButton = [UIButton buttonWithType:UIButtonTypeCustom];
	loginButton.frame = CGRectMake(0, CGRectGetMaxY(passwordField.frame), fullSize.width, 40);
	[loginButton setTitle:NSLocalizedString(@"Log In", nil) forState:UIControlStateNormal];
	[loginButton addTarget:self action:@selector(signIn) forControlEvents:UIControlEventTouchUpInside];
	[loginSection addSubview:loginButton];
	
	signUpButton = [UIButton buttonWithType:UIButtonTypeCustom];
	signUpButton.backgroundColor = [UIColor colorWithWhite:0 alpha:.6f];
	signUpButton.frame = CGRectMake(0, fullSize.height - 64, fullSize.width, 40);
	signUpButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
	[signUpButton setTitle:NSLocalizedString(@"Create An Account", nil) forState:UIControlStateNormal];
	[signUpButton addTarget:self action:@selector(signUp) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:signUpButton];
	
	UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:loginSection action:@selector(endEditing:)];
	tap.delegate = self;
	[self.view addGestureRecognizer:tap];
	
	if ([self.delegate respondsToSelector:@selector(signInViewController:signInFacebook:)]) {
		facebookLoginButton = [UIButton buttonWithType:UIButtonTypeCustom];
		facebookLoginButton.titleEdgeInsets = UIEdgeInsetsMake(0, 8, 0, 0);
		[facebookLoginButton setImage:[UIImage imageNamed:@"icon_facebook"] forState:UIControlStateNormal];
		[facebookLoginButton setTitle:NSLocalizedString(@"Login with Facebook", nil) forState:UIControlStateNormal];
		[facebookLoginButton addTarget:self action:@selector(facebookLogin:) forControlEvents:UIControlEventTouchUpInside];
		[self.view addSubview:facebookLoginButton];
	}
	
	if ([self.delegate respondsToSelector:@selector(signInViewController:signInTwitter:)]) {
		twitterLoginButton = [UIButton buttonWithType:UIButtonTypeCustom];
		twitterLoginButton.titleEdgeInsets = UIEdgeInsetsMake(0, 8, 0, 0);
		[twitterLoginButton setImage:[UIImage imageNamed:@"icon_twitter"] forState:UIControlStateNormal];
		[twitterLoginButton setTitle:NSLocalizedString(@"Login with Twitter", nil) forState:UIControlStateNormal];
		[twitterLoginButton addTarget:self action:@selector(twitterLogin:) forControlEvents:UIControlEventTouchUpInside];
		[self.view addSubview:twitterLoginButton];
	}
}

- (void)viewDidUnload
{
	[super viewDidUnload];
	logoView = nil;
	emailField = nil;
	passwordField = nil;
	loginSection = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	self.navigationController.navigationBarHidden = YES;

	CGRect frame = loginSection.frame;
	frame.size.height = CGRectGetMaxY(self.loginButton.frame);
	loginSection.frame = frame;
	
	if ([self.delegate respondsToSelector:@selector(frameForFacebookButtonInSignInViewController:)]) {
		CGRect frame = [self.delegate frameForFacebookButtonInSignInViewController:self];
		facebookLoginButton.frame = frame;
	}
	if ([self.delegate respondsToSelector:@selector(frameForTwitterButtonInSignInViewController:)]) {
		CGRect frame = [self.delegate frameForTwitterButtonInSignInViewController:self];
		twitterLoginButton.frame = frame;
	}
	
	if (!animationPlayed) {
		CGFloat statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
		CGRect logoFrame = logoView.frame;
		CGSize fullSize = [[UIScreen mainScreen] bounds].size;
		logoFrame.origin.x = (fullSize.width - logoSize.width) / 2;
		logoFrame.origin.y = (fullSize.height - logoSize.height) / 2 - statusBarHeight;
		logoView.frame = logoFrame;
		if (logoScale != 1)
			logoView.transform = CGAffineTransformMakeScale(logoScale, logoScale);
		loginSection.alpha = 0;
		[UIView animateWithDuration:.3 animations:^{
			CGPoint p = logoView.center;
			p.y = logoHeight * logoYFactor;
			logoView.center = p;
			logoView.transform = CGAffineTransformIdentity;
		} completion:^(BOOL finished) {
			[UIView animateWithDuration:.25f animations:^{
				loginSection.alpha = 1;
				animationPlayed = YES;
			}];
		}];
	}
}

- (void)_keyboardWillShow:(NSNotification *)notification
{
	NSValue *value = [notification userInfo][UIKeyboardFrameEndUserInfoKey];
	CGRect frame = [self.view convertRect:[value CGRectValue] fromView:nil];
	[self keyboardWillShow:frame];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_keyboardWillShow:) name:UIKeyboardWillChangeFrameNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	[self hideHUD:NO];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - UIGestureDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
	return ![touch.view isKindOfClass:[UIControl class]];
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	if (textField == emailField) {
		[passwordField becomeFirstResponder];
	} else {
		[self signIn];
	}
	return textField.text.length > 0;
}

@end