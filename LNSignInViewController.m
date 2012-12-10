//
//  LNSignInViewController.m
//  Hauler Deals
//
//  Created by Rex Sheng on 10/26/12.
//  Copyright (c) 2012 Log(n) LLC. All rights reserved.
//

#import "LNSignInViewController.h"
#import "UIViewController+HUD.h"
#import "LNTextField.h"
#import "IdentityManager.h"
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

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		_logoScale = 1;
		_logoYFactor = .618f;
	}
	return self;
}

#pragma mark - Action
- (void)signIn
{
	[loginSection endEditing:YES];
	NSString *password = [_passwordField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	NSString *email = [_emailField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	NSString *errorMessage;
	if (!_passwordField.isValid) {
		errorMessage = _passwordField.failedValidateText;
	} else if (!_emailField.isValid) {
		errorMessage = _emailField.failedValidateText;
	}
	if (errorMessage) {
		return [self displayError:@"Login" message:errorMessage];
	}
	NSPredicate *predicate = [self.delegate signInViewController:self predicateForField:_emailField errorMessage:&errorMessage];
	if (predicate) {
		if (![predicate evaluateWithObject:email]) {
			return [self displayHUDError:@"Login" message:errorMessage];
		}
	}
	predicate = [self.delegate signInViewController:self predicateForField:_passwordField errorMessage:&errorMessage];
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
	[self displayHUD:@"Authenticating..."];
	[_identityManager authenticateIdentityWithServiceIdentifier:@"fb" completion:^(LNUser *user) {
		[self hideHUD:NO];
		if (user) {
			[self.delegate signInViewController:self signInFacebook:user];
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
	[self displayHUD:@"Authenticating..."];
	[_identityManager authenticateIdentityWithServiceIdentifier:@"tw" completion:^(LNUser *user) {
		[self hideHUD:NO];
		if (user) {
			[self.delegate signInViewController:self signInTwitter:user];
		} else {
			[self displayError:@"Twitter Login" message:@"You have canceled twitter login."];
		}
	}];
}

- (void)keyboardWillShow:(CGRect)newRect
{
	[UIView animateWithDuration:.25f animations:^{
		CGRect f = loginSection.frame;
		f.origin.y = MIN(_logoHeight, newRect.origin.y - f.size.height - 5);
		loginSection.frame = f;
		CGPoint p = logoView.center;
		p.y = MIN(_logoHeight, f.origin.y) * _logoYFactor;
		logoView.center = p;
		CGFloat scale = f.origin.y / _logoHeight;
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
	loginSection = [[UIView alloc] initWithFrame:CGRectMake(0, _logoHeight, fullSize.width, 0)];

	if ([self.delegate respondsToSelector:@selector(signInViewController:signIn:)]) {
		[self.view addSubview:loginSection];
		_emailField = [[LNTextField alloc] initWithFrame:CGRectMake(0, 0, fullSize.width, 40)];
		_emailField.placeholder = NSLocalizedString(@"Email", nil);
		_emailField.keyboardType = UIKeyboardTypeEmailAddress;
		_emailField.autocapitalizationType = UITextAutocapitalizationTypeNone;
		_emailField.autocorrectionType = UITextAutocorrectionTypeNo;
		_emailField.returnKeyType = UIReturnKeyNext;
		_emailField.delegate = self;
		_emailField.validateType = LNTextValidateEmail;
		_emailField.failedValidateText = @"wrong email format";
		[loginSection addSubview:_emailField];
		
		_passwordField = [[LNTextField alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(_emailField.frame) + 1, fullSize.width, 40)];
		_passwordField.placeholder = NSLocalizedString(@"Password", nil);
		_passwordField.secureTextEntry = YES;
		_passwordField.returnKeyType = UIReturnKeyGo;
		_passwordField.delegate = self;
		_passwordField.validateType = LNTextValidateRequired;
		_passwordField.failedValidateText = @"you should enter your password";
		[loginSection addSubview:_passwordField];
		
		_loginButton = [UIButton buttonWithType:UIButtonTypeCustom];
		_loginButton.frame = CGRectMake(0, CGRectGetMaxY(_passwordField.frame), fullSize.width, 40);
		[_loginButton setTitle:NSLocalizedString(@"Log In", nil) forState:UIControlStateNormal];
		[_loginButton addTarget:self action:@selector(signIn) forControlEvents:UIControlEventTouchUpInside];
		[loginSection addSubview:_loginButton];
	}
	if ([self.delegate respondsToSelector:@selector(signUp)]) {
		_signUpButton = [UIButton buttonWithType:UIButtonTypeCustom];
		_signUpButton.backgroundColor = [UIColor colorWithWhite:0 alpha:.6f];
		_signUpButton.frame = CGRectMake(0, fullSize.height - 64, fullSize.width, 40);
		_signUpButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
		[_signUpButton setTitle:NSLocalizedString(@"Create An Account", nil) forState:UIControlStateNormal];
		[_signUpButton addTarget:self action:@selector(signUp) forControlEvents:UIControlEventTouchUpInside];
		[self.view addSubview:_signUpButton];
	}
	UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:loginSection action:@selector(endEditing:)];
	tap.delegate = self;
	[self.view addGestureRecognizer:tap];
	
	if ([self.delegate respondsToSelector:@selector(signInViewController:signInFacebook:)]) {
		_facebookLoginButton = [UIButton buttonWithType:UIButtonTypeCustom];
		_facebookLoginButton.titleEdgeInsets = UIEdgeInsetsMake(0, 8, 0, 0);
		[_facebookLoginButton setImage:[UIImage imageNamed:@"icon_facebook"] forState:UIControlStateNormal];
		[_facebookLoginButton setTitle:NSLocalizedString(@"Login with Facebook", nil) forState:UIControlStateNormal];
		[_facebookLoginButton addTarget:self action:@selector(facebookLogin:) forControlEvents:UIControlEventTouchUpInside];
		[self.view addSubview:_facebookLoginButton];
	}
	
	if ([self.delegate respondsToSelector:@selector(signInViewController:signInTwitter:)]) {
		_twitterLoginButton = [UIButton buttonWithType:UIButtonTypeCustom];
		_twitterLoginButton.titleEdgeInsets = UIEdgeInsetsMake(0, 8, 0, 0);
		[_twitterLoginButton setImage:[UIImage imageNamed:@"icon_twitter"] forState:UIControlStateNormal];
		[_twitterLoginButton setTitle:NSLocalizedString(@"Login with Twitter", nil) forState:UIControlStateNormal];
		[_twitterLoginButton addTarget:self action:@selector(twitterLogin:) forControlEvents:UIControlEventTouchUpInside];
		[self.view addSubview:_twitterLoginButton];
	}
}

- (void)viewDidUnload
{
	[super viewDidUnload];
	logoView = nil;
	_emailField = nil;
	_passwordField = nil;
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
		_facebookLoginButton.frame = frame;
	}
	if ([self.delegate respondsToSelector:@selector(frameForTwitterButtonInSignInViewController:)]) {
		CGRect frame = [self.delegate frameForTwitterButtonInSignInViewController:self];
		_twitterLoginButton.frame = frame;
	}
	
	if (!animationPlayed) {
		CGFloat statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
		CGRect logoFrame = logoView.frame;
		CGSize fullSize = [[UIScreen mainScreen] bounds].size;
		logoFrame.origin.x = (fullSize.width - logoSize.width) / 2;
		logoFrame.origin.y = (fullSize.height - logoSize.height) / 2 - statusBarHeight;
		logoView.frame = logoFrame;
		if (_logoScale != 1)
			logoView.transform = CGAffineTransformMakeScale(_logoScale, _logoScale);
		loginSection.alpha = 0;
		_facebookLoginButton.alpha = 0;
		_twitterLoginButton.alpha = 0;
		_signUpButton.alpha = 0;
		[UIView animateWithDuration:.3 animations:^{
			CGPoint p = logoView.center;
			p.y = _logoHeight * _logoYFactor;
			logoView.center = p;
			logoView.transform = CGAffineTransformIdentity;
		} completion:^(BOOL finished) {
			[UIView animateWithDuration:.25f animations:^{
				loginSection.alpha = 1;
				_facebookLoginButton.alpha = 1;
				_twitterLoginButton.alpha = 1;
				_signUpButton.alpha = 1;
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
	if (textField == _emailField) {
		[_passwordField becomeFirstResponder];
	} else {
		[self signIn];
	}
	return textField.text.length > 0;
}

@end