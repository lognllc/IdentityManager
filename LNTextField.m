//
//  LNTextField.m
//
//  Created by Rex Sheng on 9/5/12.
//  Copyright (c) 2012 Log(n) LLC. All rights reserved.
//

#import "LNTextField.h"

@implementation LNTextField

- (id)initWithFrame:(CGRect)frame
{
	if (self = [super initWithFrame:frame]) {
		_edgeInsetX = 8;
		_placeholderAlpha = 1;
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		self.keyboardType = UIKeyboardTypeDefault;
		self.returnKeyType = UIReturnKeySearch;
		self.autocapitalizationType = UITextAutocapitalizationTypeNone;
		self.clipsToBounds = YES;
		_validateType = LNTextValidateNone;
	}
	return self;
}

- (void)setTextAttributes:(NSDictionary *)textAttributes
{
	_textAttributes = textAttributes;
	UIFont *font = textAttributes[UITextAttributeFont];
	if (font) self.font = font;
	UIColor *textColor = textAttributes[UITextAttributeTextColor];
	if (textColor) self.textColor = textColor;
}

- (void)setBackgroundImage:(UIImage *)backgroundImage
{
	self.background = backgroundImage;
}

- (UIImage *)backgroundImage
{
	return self.background;
}

- (BOOL)isValid:(NSString *)text
{
	if (_validateType == LNTextValidateNone) return YES;
	if (_validateType == LNTextValidateCustom) {
		return [_validatePredicate evaluateWithObject:text];
	}
	NSString *reg = nil;
	if (_validateType == LNTextValidateEmail) {
		reg = @"(?:[a-z0-9!#$%\\&'*+/=?\\^_`{|}~-]+(?:\\.[a-z0-9!#$%\\&'*+/=?\\^_`{|}"
		@"~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\"
		@"x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-z0-9](?:[a-"
		@"z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:25[0-5"
		@"]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-"
		@"9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21"
		@"-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])";
        
        //For Skypets, employee account is not a email address
        BOOL matches = [[NSPredicate predicateWithFormat:@"self matches %@", @"^en[0-9]+$"] evaluateWithObject:text];
        if (matches) {
            return YES;
        }
	}
	if (_validateType == LNTextValidateRequired) {
		reg = @"^\\S(?:.*?\\S)?$";
	}
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF matches %@", reg];
	return [predicate evaluateWithObject:text];
}

- (BOOL)isValid
{
	return [self isValid:self.text];
}

- (void)setClearImage:(UIImage *)clearImage
{
	_clearImage = clearImage;
	UIButton *clearButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[clearButton setImage:clearImage forState:UIControlStateNormal];
	[clearButton addTarget:self action:@selector(cleanUp) forControlEvents:UIControlEventTouchUpInside];
	clearButton.frame = (CGRect) {.size = clearImage.size};
	self.rightView = clearButton;
	self.rightViewMode = UITextFieldViewModeAlways;
	self.rightView.hidden = YES;
	self.clearButtonMode = UITextFieldViewModeNever;
}

- (void)cleanUp
{
	if ([self.delegate textFieldShouldClear:self]) {
		self.text = nil;
		self.rightView.hidden = YES;
		if (![self isFirstResponder])
			[self becomeFirstResponder];
	}
}

- (CGRect)placeholderRectForBounds:(CGRect)bounds
{
	CGFloat offset = (bounds.size.height - self.rightView.bounds.size.height) / 2;
	return UIEdgeInsetsInsetRect(bounds, UIEdgeInsetsMake((bounds.size.height - self.font.lineHeight) / 2, _edgeInsetX, 0, self.rightView.bounds.size.width + offset));
}

- (CGRect)editingRectForBounds:(CGRect)bounds
{
	return [self textRectForBounds:bounds];
}

- (CGRect)rightViewRectForBounds:(CGRect)bounds
{
	CGFloat offset = (bounds.size.height - self.rightView.bounds.size.height) / 2;
	return CGRectOffset(self.rightView.bounds, bounds.size.width - self.rightView.bounds.size.width - offset, offset);
}

- (CGRect)textRectForBounds:(CGRect)bounds
{
	return UIEdgeInsetsInsetRect(bounds, UIEdgeInsetsMake((bounds.size.height - self.font.lineHeight) / 2, _edgeInsetX, 0, _edgeInsetX));
}

- (CGRect)leftViewRectForBounds:(CGRect)bounds
{
	CGFloat offset = (bounds.size.height - self.leftView.bounds.size.height) / 2;
	return CGRectOffset(self.leftView.bounds, offset, offset);
}

- (void)drawPlaceholderInRect:(CGRect)rect
{
	[[self.textColor colorWithAlphaComponent:_placeholderAlpha] set];
	[self.placeholder drawAtPoint:CGPointMake(0, 0) withFont:self.font];
}

@end
