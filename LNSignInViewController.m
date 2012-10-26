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

@synthesize emailField, passwordField, identityManager;

#pragma mark - Action
- (void)signIn
{
	[loginSection endEditing:YES];
	NSString *password = [passwordField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	if (emailField.text.length == 0) {
		return [self displayHUDError:@"Login" message:@"please enter your email"];
	}
	if (password.length < 6) {
		return [self displayHUDError:@"Login" message:@"please enter password in 6 or more characters. Leading or trailing spaces will be ignored."];
	}
	[self signIn];
}

- (void)signUp
{
}

- (void)forgotPassword
{
}

- (void)keyboardWillShow:(CGRect)newRect
{
	[UIView animateWithDuration:.25f animations:^{
		CGRect f = loginSection.frame;
		f.origin.y = MIN(LOGIN_SECTION_Y_ORIGIN, newRect.origin.y - f.size.height - 5);
		loginSection.frame = f;
		
		CGPoint p = logoView.center;
		p.y = MIN(LOGO_CENTER_Y_ORIGIN, f.origin.y * LOGO_CENTER_Y_FACTOR);
		logoView.center = p;
		CGFloat scale = f.origin.y / LOGIN_SECTION_Y_ORIGIN;
		logoView.transform = CGAffineTransformMakeScale(scale, scale);
	}];
}

- (void)facebookLogin:(id)sender
{
	FacebookSessions *sessions = [identityManager registeredSocialSessionsWithServiceIdentifier:[FacebookSessions socialIdentifier]];
	[sessions loginSlot:0 completion:^(BOOL success) {
		if (success) {
			NSString *token = [sessions userTokenInSlot:0];
			NSLog(@"success got facebook token %@", token);
			[self displayHUD:@"Logging in..."];
			
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
	IdentityManager *identityManager = [GetAppDelegate() identityManager];
	TwitterSessions *sessions = [identityManager registeredSocialSessionsWithServiceIdentifier:[TwitterSessions socialIdentifier]];
	[sessions loginSlot:0 completion:^(BOOL success) {
		if (success) {
			NSString *token = [sessions userTokenInSlot:0];
			NSString *tokenSecret = [sessions userTokenSecretInSlot:0];
			NSLog(@"success got twitter token %@ / %@", token, tokenSecret);
			[self displayHUD:@"Logging in..."];
			[Magento.service twitterLoginToken:token tokenSecret:tokenSecret completion:^(id responseObject, NSError *error) {
				if (error) {
					[self displayHUDError:@"try again" message:error.localizedDescription];
				} else {
					NSLog(@"response %@", responseObject);
					if (![responseObject isKindOfClass:[NSDictionary class]]) {
						[self displayHUDError:@"try again" message:@"name and password mismatch"];
					} else {
						NSDictionary *customer = responseObject;
						[self hideHUD:YES];
						NSString *customerName = [NSString stringWithFormat:@"%@ %@", [customer objectForKey:@"firstname"], [customer objectForKey:@"lastname"]];
						Magento.service.customerID = [customer objectForKey:@"customer_id"];
						Magento.service.customerName = customerName;
						[GetAppDelegate() showMainScreen];
					}
				}
			}];
		} else {
			[self displayError:@"Twitter Login" message:@"You have canceled twitter login."];
		}
	}];
}

#pragma mark - View Lifecycle
- (void)viewDidLoad
{
	[super viewDidLoad];
	//background
	UIImageView *background = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Splash_Background.jpg"]];
	background.contentMode = UIViewContentModeScaleAspectFill;
	background.frame = self.view.bounds;
	background.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	[self.view addSubview:background];
	
	UIImage *logo = [UIImage imageNamed:@"splash_logo"];
	logoSize = logo.size;
	logoView = [[UIImageView alloc] initWithImage:logo];
	logoView.contentMode = UIViewContentModeScaleAspectFit;
	[self.view addSubview:logoView];
	
	CGSize fullSize = self.view.bounds.size;
	CGFloat width = fullSize.width - MARGIN_LR - MARGIN_LR;
	loginSection = [[UIView alloc] initWithFrame:CGRectMake(MARGIN_LR, LOGIN_SECTION_Y_ORIGIN, width, 0)];
 	
	[self.view addSubview:loginSection];
	emailField = [[HDTextField alloc] initWithFrame:CGRectMake(0, 0, width, HEIGHT_FOR_CELL)];
	emailField.placeholder = @"EMAIL ADDRESS";
	emailField.keyboardType = UIKeyboardTypeEmailAddress;
	emailField.autocapitalizationType = UITextAutocapitalizationTypeNone;
	emailField.autocorrectionType = UITextAutocorrectionTypeNo;
	emailField.backgroundColor = [UIColor colorWithWhite:1 alpha:.2f];
	emailField.returnKeyType = UIReturnKeyNext;
	emailField.delegate = self;
	[loginSection addSubview:emailField];
	
	passwordField = [[HDTextField alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(emailField.frame) + 1, width, HEIGHT_FOR_CELL)];
	passwordField.backgroundColor = [UIColor colorWithWhite:1 alpha:.2f];
	passwordField.placeholder = @"PASSWORD";
	passwordField.secureTextEntry = YES;
	passwordField.returnKeyType = UIReturnKeyGo;
	passwordField.delegate = self;
	[loginSection addSubview:passwordField];
	
	UIFont *font = [UIFont semiBoldDinFontOfSize:IS_IPAD ? 27 : 17];
	UIButton *loginButton = [UIButton buttonWithType:UIButtonTypeCustom];
	loginButton.backgroundColor = [UIColor colorWithWhite:0 alpha:.7f];
	loginButton.frame = CGRectMake(0, CGRectGetMaxY(passwordField.frame) + (IS_IPAD ? 0 : 5.5f), width, HEIGHT_FOR_BUTTON);
	loginButton.titleLabel.font = font;
	[loginButton setTitle:@"LOG IN" forState:UIControlStateNormal];
	[loginButton addTarget:self action:@selector(signIn) forControlEvents:UIControlEventTouchUpInside];
	[loginSection addSubview:loginButton];
	CGRect frame = loginSection.frame;
	frame.size.height = CGRectGetMaxY(loginButton.frame);
	loginSection.frame = frame;
	
	UIButton *signUpButton = [UIButton buttonWithType:UIButtonTypeCustom];
	signUpButton.backgroundColor = [UIColor colorWithWhite:0 alpha:.6f];
	signUpButton.frame = CGRectMake(MARGIN_LR, fullSize.height - HEIGHT_FOR_BUTTON - (IS_IPAD ? 102 : 22), width, HEIGHT_FOR_BUTTON);
	signUpButton.titleLabel.font = font;
	signUpButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
	[signUpButton setTitle:@"CREATE AN ACCOUNT" forState:UIControlStateNormal];
	[signUpButton addTarget:self action:@selector(signUp) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:signUpButton];
	
	UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:loginSection action:@selector(endEditing:)];
	tap.delegate = self;
	[self.view addGestureRecognizer:tap];
	
	font = [UIFont semiBoldDinFontOfSize:FONT_SIZE_NORMAL];
	UIButton *facebookLoginButton = [UIButton buttonWithType:UIButtonTypeCustom];
	facebookLoginButton.frame = CGRectMake(MARGIN_LR, CGRectGetMaxY(loginSection.frame) + (IS_IPAD ? 33.5f : 26), width, IS_IPAD ? 42.5f : 20);
	facebookLoginButton.titleLabel.font = font;
	facebookLoginButton.titleEdgeInsets = UIEdgeInsetsMake(0, 8, 0, 0);
	[facebookLoginButton setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
	[facebookLoginButton setImage:[UIImage imageNamed:@"icon_facebook"] forState:UIControlStateNormal];
	[facebookLoginButton setTitle:@"LOGIN WITH FACEBOOK" forState:UIControlStateNormal];
	[facebookLoginButton addTarget:self action:@selector(facebookLogin:) forControlEvents:UIControlEventTouchUpInside];
	
	[self.view addSubview:facebookLoginButton];
	
	UIButton *twitterLoginButton = [UIButton buttonWithType:UIButtonTypeCustom];
	twitterLoginButton.frame = CGRectOffset(facebookLoginButton.frame, 0, facebookLoginButton.frame.size.height + MARGIN_LR / 2);
	twitterLoginButton.titleLabel.font = font;
	twitterLoginButton.titleEdgeInsets = UIEdgeInsetsMake(0, 8, 0, 0);
	[twitterLoginButton setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
	[twitterLoginButton setImage:[UIImage imageNamed:@"icon_twitter"] forState:UIControlStateNormal];
	[twitterLoginButton setTitle:@"LOGIN WITH TWITTER" forState:UIControlStateNormal];
	[twitterLoginButton addTarget:self action:@selector(twitterLogin:) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:twitterLoginButton];
	
	UIButton *forgotButton = [UIButton buttonWithType:UIButtonTypeCustom];
	font = [UIFont boldDinFontOfSize:IS_IPAD ? 22 : 11];
	NSString *text = @"FORGOT YOUR PASSWORD?";
	forgotButton.frame = CGRectMake(MARGIN_LR, CGRectGetMaxY(twitterLoginButton.frame) + (IS_IPAD ? 26 : 19), width, font.lineHeight + 2);
	[forgotButton setTitle:text forState:UIControlStateNormal];
	forgotButton.titleLabel.font = font;
	[forgotButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
	CGSize textSize = [text sizeWithFont:font];
	UIView *line = [[UIView alloc] initWithFrame:CGRectMake((width - textSize.width) / 2 - .5f, font.lineHeight - 1, textSize.width, 1)];
	line.backgroundColor = [UIColor blackColor];
	[forgotButton addSubview:line];
	[forgotButton addTarget:self action:@selector(forgotPassword) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:forgotButton];
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
	
	if (!animationPlayed) {
		CGFloat statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
		CGRect logoFrame = logoView.frame;
		CGSize fullSize = [[UIScreen mainScreen] bounds].size;
		logoFrame.origin.x = (fullSize.width - logoSize.width) / 2;
		logoFrame.origin.y = (fullSize.height - logoSize.height) / 2 - statusBarHeight;
		logoView.frame = logoFrame;
		logoView.transform = CGAffineTransformMakeScale(.886f, .886f);
		loginSection.alpha = 0;
		[UIView animateWithDuration:.3 animations:^{
			CGPoint p = logoView.center;
			p.y = LOGO_CENTER_Y_ORIGIN;
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